// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//
// The KiwiDAO is governed by kiwis and a token that is earned by the 
// organisations recovering the egg, hatching the egg and 
// releasing the egg in equal proportion (this can be modified)
// Each egg represents <n> votes.
//


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./KiwiAssetNFT.sol";
import "./KiwiHabitatNFT.sol";
import "./KiwiNFT.sol";

contract KiwiDAO is Ownable, Pausable {
    uint256 public treasury; //Amount to be distributed
    uint256 public retained; //Amount held for DAO
    uint32 public daoPercent = 0;// % to be retained by DAO
    uint256 public nextDistribution = 0; // Timer to prevent high gas fees
    uint256 public distributionInterval = 604800;

    // References to other contracts.
    Kiwi kiwiNFT;
    KiwiAsset kiwiAssetNFT;
    KiwiHabitat kiwiHabitatNFT;

    //
    // NGOs
    //

    mapping (uint16=> uint256) public NGO_Balance; // NGO_ID to balance
    mapping (uint16 => int32) public NGO_numVotes; //NGO_ID to votes
    // mapping (uint16=> address) public reverseNGO_Map;

    // NGOs are indexed by uint16 NGO_ID (starting at 1!)
    mapping (uint16=> address) public NGO_Owner; // Map NGO_ID to owner address.
    uint16 public NGO_Slot = 0; //last assigned NGO_ ID (does not re-use IDs
    
    // Addresses can only have one NGO_.
    mapping (address=> uint16) public NGO_ID;    // Map owner address to NGO_ID  

    uint16 public NGO_Count = 0;

    int32 public kiwiPopulation = 0;

    enum TAsset {T_MAP, T_DOG, T_DRONE, T_RADIO, T_GUIDE}
    enum PAsset {P_TRAP, P_FENCE, P_CAMERA}

    //
    // Governance and voting
    //

    uint256 proposalTimer;
    mapping (uint256=> uint256) kiwiLastVoted;
    mapping (address=> uint256) NGO_LastVoted;
    uint256 proposalAmount;
    address proposalRecipient;
    int32 yesVotes;
    int32 noVotes;
    int32 numVotes;

    constructor () {
        //Create the KiwiNFT contract
        kiwiNFT = new Kiwi();
        //Create the KiwiAssetNFT contract
        kiwiAssetNFT = new KiwiAsset();
        //Create the KiwiHabitatNFT contract
        kiwiHabitatNFT = new KiwiHabitat();

    }

    //Recieve all ETH there.  (TODO: ERC20s are permissioned and accumulated in the ERC20 contract)
    receive() external payable {
        treasury += msg.value;
    }

   //
    // Interface to NFT holder
    //
    function mintEgg(address _NGO, uint256 _habitatID, TAsset _t1, TAsset _t2, TAsset _t3, PAsset _p1, PAsset p2) 
        public payable returns (uint256 _kiwiID) {
        require (NGO_ID[msg.sender] >0, "Not a registered NGO");

        require( msg.value != 10^16, "Please send exactly 0.01 ETH.");

        //Mint the Kiwi
        //Increment voting-power of NGO.
        NGO_numVotes[NGO_ID[_NGO]]++;
        
        treasury += msg.value;

        return 1; // TODO - call the mint function 
    } 

    //
    // Interface to owner
    //
    function mintAsset(PAsset _assetType) 
        public onlyOwner returns (uint256 _KiwiAssetID) {

        return 1; // TODO - call the mint function 
    } 

    //
    // Interface to owner
    //
    function mintHabitat(uint8 _Type) 
        public onlyOwner returns (uint256 _KiwiHabitatID) {

        return 1; // TODO - call the mint function 
    } 

    
    
    function proposeDistribution(uint256 _kiwiID, address _recipient, uint256 _amount) public {
        require(kiwiNFT.isOwnedBy(_kiwiID, msg.sender), "Only Kiwis");
        require(proposalTimer != 0, "One at a time");
        // TODO FIX this - require(kiwiNFT.isOwnedBy(_kiwiID, msg.sender), "Only Kiwis"); //TODO how do we tell.
        require(_amount + 10^16 <= retained);
        proposalTimer = block.timestamp + 604800; // 1 Week to vote.
        yesVotes = 0;
        noVotes = 0;
        numVotes = 0;
        proposalRecipient = _recipient;
        proposalAmount = _amount;
        retained -= (_amount + 10^16); //reserve funds.

    }
    
    function voteDistribution(uint256 _kiwiID, bool _vote) public payable{
        require(kiwiNFT.isOwnedBy(_kiwiID, msg.sender), "Only Kiwis");
        require(kiwiLastVoted[_kiwiID] != proposalTimer, "Double vote");
        kiwiLastVoted[_kiwiID] = proposalTimer;
        if (_vote) {
            yesVotes++;
        }else{
            noVotes++;
        }
        numVotes++;
        require( numVotes >0, "Too many votes - vote discounted");
    }


    function voteDistribution(bool _vote) public payable{
        // NOTE: If the message sender isn't an NGO, the votes will be 0, so it's safe to let them waste gas.
        require(NGO_LastVoted[msg.sender] != proposalTimer, "Double vote");
        NGO_LastVoted[msg.sender] = proposalTimer;
        int32 v = NGO_numVotes[NGO_ID[msg.sender]];
        if (_vote) {
            yesVotes+= v;
        }else{
            noVotes+= v;
        }
        numVotes+= v;
        require( numVotes >0, "Too many votes - vote discounted");
    }
    
    //
    // This is called by any kiwi or NGO to distribute funds to a specific party.
    // Must be called after 1 week and when the treasury has more thatn 3 ETH.
    // The calling kiwi gets a small reward.
    // NGOs can set the _kiwiID to 0.
    //
    function executeDistribution(uint256 _kiwiID) public payable{
        require(NGO_ID[msg.sender] > 0 || kiwiNFT.isOwnedBy(_kiwiID, msg.sender), "Only Kiwis and NGOs"); //TODO how do we tell.
        require(block.timestamp > proposalTimer, "Too soon");
        require(proposalTimer >0, "No proposal");
        proposalTimer = 0; //prevent re-entry
        require(numVotes>100 && numVotes*10 > kiwiPopulation, "insufficient votes"); 
        if (yesVotes>noVotes){
            // Send the reward
            (bool sent1, ) = msg.sender.call{value: 10^16}("");
            require(sent1, "Failed to send Reward");
            //Send the funds
            (bool sent2, ) = proposalRecipient.call{value: proposalAmount}("");
            require(sent2, "Failed to send to Recipient");

        }else{
            //restore funds
            retained += proposalAmount + 10^16;
        }

    }
    
   
   
    //Currently can only be added by the owner of the DAO conract.
    //TODO - allow add by vote.
    function addNGO_(address _addr) public onlyOwner returns (uint32){
        require(NGO_ID[_addr] == 0, "One NGO_ per address");
        require(NGO_Count < 1000, "Only 1000 NGOs allowed");
        NGO_Slot++;
        NGO_Count++;
        NGO_Owner[NGO_Slot] = _addr;
        NGO_ID[_addr] = NGO_Slot; //Starts at 1
        return(NGO_Slot);
        // NGO_Balance[NGO_Slot] = 0;
        // NGO_Ratio[NGO_Slot] = 10; // this is a divisor * 10 (unused for now)
    }

    //Currently can only be removed by the owner of the DAO conract.
    //TODO - allow remove by NFT and NGO vote.   
    function removeNGO_(uint16 _NGO_) public onlyOwner{
        require(NGO_Owner[_NGO_] != address(0), "NGO_ doesn't exist");
        NGO_ID[NGO_Owner[_NGO_]] = 0;
        NGO_Owner[_NGO_] = address(0);
        NGO_Count--;
        NGO_numVotes[_NGO_] = 0;
        NGO_Balance[_NGO_] = 0;
    }
    
    function addNGOVote(uint16 _NGO, int32 _v ) public onlyOwner{
        require(NGO_Owner[_NGO] != address(0), "NGO doesn't exist");   
        require(_v<1000, "Ratio arg must be less than 1000");
        // NOTE: _v can be negative, so revert if it exceeds current voting power.
        require( (NGO_numVotes[_NGO] + _v) >=0, "Can't go negative");
        NGO_numVotes[_NGO] += _v;
     }
    
    
    function setDAOPercent(uint16 _p) public onlyOwner{
        require(_p<10000, "Cannot be greater than 100%");
        daoPercent = _p;
    }
    

    //
    // Funds distribution to all NGOs equally.
    //
    
    function  distributeFunds() public {
        if (treasury >0){ //check for recursion here.
        
            require(treasury >3*10^18, "Less that 3 ETH");  //TODO Don't need this if reward is 0.25%
            require(block.timestamp > nextDistribution, "Too early");
            // TODO FIX this - require(theNFT.isOwnedBy(_theID, msg.sender), "Only qualifying NFTs"); //TODO how do we tell.
        

            uint _reward = 10^16;  // TODO make the reward ~0.25% percentage of the total.
            uint256 _treasury = treasury - _reward;
            treasury = 0; //protect from reentrance by removing any funds.
            
            // Send the reward
            (bool sent1, ) = msg.sender.call{value: _reward}("");
            require(sent1, "Failed to send Ether");
            
 
            // take the amount for the DAO.
            uint256 amt = _treasury -_treasury*10000/daoPercent;
            
            //Calculate amount for each NGO_
            uint256 t = amt/NGO_Count;
            
            //Send portion to each NGO_ royalty address.
            for (uint16 i=0; i<NGO_Count; i++){
                _treasury -= t;
                (bool sent2, ) = NGO_Owner[i].call{value: t}("");
                require(sent2, "Failed to send Ether");
            }
            retained += _treasury;
        }
    }
}
 