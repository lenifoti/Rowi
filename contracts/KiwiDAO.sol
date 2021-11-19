// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//
// The KiwiDAO is governed by a token that is earned by the 
// organisation recovering the egg, hatching the edg and 
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

contract KiwiDAO is Ownable, pausable {
    

}

   
/*        
    mapping (uint16=> uint256) public hiveBalance;
    mapping (uint16=> uint16) public hivePercent;
    mapping (uint16=> address) public reverseHiveMap;
    
    uint16 public hiveCount = 0;
    uint32 public beePopulation = 0;

    uint256 public treasury; //Amount to be distributed
    uint256 public retained; //Amount held for DAO
    uint32 public daoPercent = 0;// % to be retained by DAO
    uint256 public nextDistribution = 0; // Timer to prevent high gas fees
    uint256 public distributionInterval = 604800;

    FancyBee public beeNFT; //contract address for beeNFT
    OutfitNFT public outfitNFT; //contract address for outfitNFT
    
    constructor(){
    }

    function initAddresses(
        FancyBee beeAddress, 
        OutfitNFT outfitAddress
        ) public onlyOwner{
        require( nextDistribution == 0, "Already initialized.");
        beeNFT = beeAddress;
        outfitNFT = outfitAddress;
        nextDistribution = block.timestamp + distributionInterval;  // only allow distribution weekly
    }
    
    //Recieve all ETH there.  (TODO: ERC20s are permissioned and accumulated in the ERC20 contract)
    receive() external payable {
        treasury += msg.value;
    }
    
    //
    // Interface to Beekeeper
    //
    function dressMe(uint256 _beeID, uint256 _outfitID) public payable {
        // FancyBeeInterface fancyBee = FancyBeeInterface(beeNFT);
        // FancyBeeInterface outfit = FancyBeeInterface(outfitNFT);

        require(beeNFT.tokenExists(_beeID), "Bee does not exist.");
        require(outfitNFT.tokenExists(_outfitID), "Outfit does not exist.");
        require( msg.value != 10^16, "Please send exactly 0.01 ETH.");

        outfitNFT.attachToBee(_outfitID, address(beeNFT), _beeID);
        beeNFT.attachOutfit(_beeID, address(outfitNFT), _outfitID);
 
        beeNFT.setTokenURI(_beeID ,outfitNFT.getTokenURI(_outfitID));
        
        treasury += msg.value;
    } 
    
    //
    // Governance and voting
    //

    uint256 proposalTimer;
    mapping (uint256=> uint256) beeLastVoted;
    uint256 proposalAmount;
    address proposalRecipient;
    uint32 yesVotes;
    uint32 noVotes;
    uint32 numVotes;
    
    function proposeDistribution(uint256 _beeID, address _recipient, uint256 _amount) public {
        require(proposalTimer != 0, "One at a time");
        // TODO FIX this - require(beeNFT.isOwnedBy(_beeID, msg.sender), "Only Bees"); //TODO how do we tell.
        require(_amount + 10^16 <= retained);
        proposalTimer = block.timestamp + 604800; // 1 Week to vote.
        yesVotes = 0;
        noVotes = 0;
        numVotes = 0;
        proposalRecipient = _recipient;
        proposalAmount = _amount;
        retained -= (_amount + 10^16); //reserve funds.

    }
    
    function voteDistribution(uint256 _beeID, bool _vote) public payable{
        // TODO FIX this - require(beeNFT.isOwnedBy(_beeID, msg.sender), "Only Bees"); //TODO how do we tell.
        require(beeLastVoted[_beeID] != proposalTimer, "Double vote");
        beeLastVoted[_beeID] = proposalTimer;
        if (_vote) {
            yesVotes++;
        }else{
            noVotes++;
        }
        numVotes++;
    }
    
    //
    // This is called by any bee to distribute funds to a specific party.
    // Must be called after 1 week and when the treasury has more thatn 3 ETH.
    // The calling bee gets a small reward.
    //
    function executeDistribution(uint256 _beeID) public payable{
        require(block.timestamp > proposalTimer, "Too soon");
        require(proposalTimer >0, "No proposal");
        proposalTimer = 0; //prevent re-entry
        require(numVotes>100 && numVotes*10 > beePopulation, "insufficient votes"); 
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
    
   
    //
    // HIVES
    //


    // mapping (uint32=> uint256) public hiveBalance;  // Map hive ID to balance
    // mapping (uint32=> uint8) public hiveRatio; 

    // Hives are indexed by uint32 hiveID (starting at 1!)
    mapping (uint32=> address) public hiveOwner; // Map hiveID to owner address.
    uint32 public hiveSlot = 0; //last assigned hive ID (does not re-use IDs
    
    // Addresses can only have one hive.
    mapping (address=> uint32) public hiveID;    // Map owner address to HiveID  

    //Currently can only be added by the owner of the DAO conract.
    //TODO - allow add by bee vote.
    function addHive(address _addr) public onlyOwner returns (uint32){
        require(hiveID[_addr] == 0, "One hive per address");
        require(hiveCount < 1000, "Only 1000 hives allowed");
        hiveSlot++;
        hiveCount++;
        hiveOwner[hiveSlot] = _addr;
        hiveID[_addr] = hiveSlot; //Starts at 1
        return(hiveSlot);
        // hiveBalance[hiveSlot] = 0;
        // hiveRatio[hiveSlot] = 10; // this is a divisor * 10 (unused for now)
    }

    //Currently can only be removed by the owner of the DAO conract.
    //TODO - allow remove by bee vote.   
    function removeHive(uint32 _hive) public onlyOwner{
        require(hiveOwner[_hive] != address(0), "Hive doesn't exist");
        hiveID[hiveOwner[_hive]] = 0;
        hiveOwner[_hive] = address(0);
        hiveCount--;
        // hiveRatio[_hive] = 0;
        // hiveBalance[_hive] = 0;
    }
    
    function setCharityRatio(uint32 _hive, uint8 _p ) public onlyOwner{
        require(hiveRatio[_hive] !=0, "Hive doesn't exist");   
        require(_p >0 && _p<11, "Ratio arg must be 1-10");
        hiveRatio[_hive] = _p; 
    }
    
    
    function setDAOPercent(uint16 _p) public onlyOwner{
        require(_p<10000, "Cannot be greater than 100%");
        daoPercent = _p;
    }
    

    //
    // Funds distribution to all hives equally.
    //
    
    function  distributeFunds(uint256 _beeID) public {
        if (treasury >0){ //check for recursion here.
        
            require(treasury >3*10^18, "Less that 3 ETH");  //TODO Don't need this if reward is 0.25%
            require(block.timestamp > nextDistribution, "Too early");
            // TODO FIX this - require(beeNFT.isOwnedBy(_beeID, msg.sender), "Only Bees"); //TODO how do we tell.
        

            uint _reward = 10^16;  // TODO make the reward ~0.25% percentage of the total.
            uint256 _treasury = treasury - _reward;
            treasury = 0; //protect from reentrance by removing any funds.
            
            // Send the reward
            (bool sent1, ) = msg.sender.call{value: _reward}("");
            require(sent1, "Failed to send Ether");
            
 
            // take the amount for the DAO.
            uint256 amt = _treasury -_treasury*10000/daoPercent;
            
            //Calculate amount for each hive
            uint256 t = amt/hiveCount;
            
            //Send portion to each hive royalty address.
            for (uint16 i=0; i<hiveCount; i++){
                _treasury -= t;
                (bool sent2, ) = reverseHiveMap[i].call{value: t}("");
                require(sent2, "Failed to send Ether");
            }
            retained += _treasury;
        }
    }

}

interface FancyBeeInterface {
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external returns (string memory);
    function getTokenURI(uint _outfitId) external view returns (string memory);
    function tokenExists(uint256 _tokenId) external view returns (bool);
}

*/