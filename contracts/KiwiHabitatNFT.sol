// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//
// The KiwiHabitat NFT represents an area of land that must be owned in
// and protected in order to release a hatched Kiwi.
// A holder needs to own this habitate as well as a number of assets
// before they can find, incubate and release a kiwi.
// Habitat is always onsale at a 100% annual lease.

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//import "@openzeppelin/contracts/introspection/IERC165.sol";
// import "./Royalty.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract KiwiHabitat is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
   // Functions that need to be overidden
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function mintToken(address owner, string memory metadataURI) public returns (uint256)
    {
        // require( balanceOf(msg.sender) == 0, "Sorry, only one bee per person." );
        require( totalSupply() < totalBeeSupply, "Sorry only 5 are available at this time. ");
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(owner, id);
        _setTokenURI(id, metadataURI);
        originalURI = metadataURI;
        return id;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // function royaltyInfo(uint256 _tokenId, uint256 _price) external view TIDoutOfRange(_tokenId) returns (address receiver, uint256 amount){
    //     return (fancyDAO, _price/10);
    // }

    // Returns True if the token exists, else false.
    function tokenExists(uint256 _tokenId) external view returns (bool){
        return _exists(_tokenId);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal pure override returns (string memory) {
        return ("ipfs://");
    }

}


/*

//PR: contract FancyBee is ERC721, ERC2981ContractWideRoyalties {
contract FancyBee is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {


    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address internal fancyDAO;
    uint totalBeeSupply = 5;
    string originalURI;

    mapping (uint256=>address) outfitNFT; // maps beeIds to outfit contract
    mapping (uint256=>uint256) outfitTokenID; // maps beeIds to outfitIds

    constructor(string memory tokenName, string memory symbol) ERC721(tokenName, symbol) {
        // _setBaseURI("ipfs://"); << Now returned by a function below
        // fancyDAO = DAOAddress;
        //PR: _setRoyalties(msg.sender, 1000); // Set caller (DAO?) as Receiver and Roaylty as 10%
    }

    // Modifier to check that the token is not <= 0.
    modifier TIDoutOfRange(uint256 _tokenID) {
        require (_tokenID>0, "TokenID out of range");
        _;
    }

    function mintToken(address owner, string memory metadataURI)
    public
    returns (uint256)
    {
        // require( balanceOf(msg.sender) == 0, "Sorry, only one bee per person." );
        require( totalSupply() < totalBeeSupply, "Sorry only 5 are available at this time. ");
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(owner, id);
        _setTokenURI(id, metadataURI);
        originalURI = metadataURI;
        return id;
    }
    
    // When changing the metadata w/ Web3. Must be formatted like : bafy.../metadata.json
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external TIDoutOfRange(_tokenId) returns (string memory) {
        _setTokenURI(_tokenId, _tokenURI);
        return tokenURI(_tokenId);
    }

    // Functions that need to be overidden
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // function royaltyInfo(uint256 _tokenId, uint256 _price) external view TIDoutOfRange(_tokenId) returns (address receiver, uint256 amount){
    //     return (fancyDAO, _price/10);
    // }

    // Returns True if the token exists, else false.
    function tokenExists(uint256 _tokenId) external view returns (bool){
        return _exists(_tokenId);
    }

    //
    // * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
    // * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
    // * by default, can be overriden in child contracts.
    // 
    function _baseURI() internal pure override returns (string memory) {
        return ("ipfs://");
    }

    // Called by the DAO to attach an outfit to a bee.
    function attachOutfit(uint256 _beeID, address _outfitContract, uint256 _outfitID) public {
        require(msg.sender == fancyDAO, "Not fancyDAO");
        require(OutfitNFT(_outfitContract).isOwnedBy(_beeID), "Bee is not owner"); //check the outfit is ours
        outfitNFT[_beeID] = _outfitContract;
        outfitTokenID[_beeID] = _outfitID;
    }
}
*/