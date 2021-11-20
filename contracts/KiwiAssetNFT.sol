// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//
// This NFT represents various assets that a kiwi prospector must own
// in order to recover eggs of kiwis in the wild and protect the kiwi after release.
// There are 5 classes of tracking aids:
//  - map
//  - tracking dog
//  - local gude
//  - drone
//  - radio locator
// There are also 5 classes of habitat protection assets:
//  - pest trap
//  - predator fence
//  - infra red camera
// Asseets are always onsale at a 100% annual lease (bonded).


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";


//import "@openzeppelin/contracts/introspection/IERC165.sol";
// import "./Royalty.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract KiwiAsset is ERC721, ERC721URIStorage, ERC721Enumerable,  Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    mapping (uint256 => uint8) tokenType;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("KiwiAsset", "KAS") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, string memory uri) 
    public onlyOwner returns (uint256){
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return (tokenId);
    }
/*
    function mintToken(address owner, string memory metadataURI) public returns (uint256)
    {
        require( balanceOf(msg.sender) <=10, "Sorry, only 10 per account." );
        // require( totalSupply() < totalAssetSupply, "Sorry only 5 are available at this time. ");
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(owner, id);
        _setTokenURI(id, metadataURI);
        originalURI = metadataURI;
        return id;
    }
*/


    // The following functions are overrides required by Solidity.

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


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    // function royaltyInfo(uint256 _tokenId, uint256 _price) external view TIDoutOfRange(_tokenId) returns (address receiver, uint256 amount){
    //     return (kiwiDAO, _price/10);
    // }

    // Returns True if the token exists, else false.
    function tokenExists(uint256 _tokenId) external view returns (bool){
        return _exists(_tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public{
        _setTokenURI(tokenId, _tokenURI);
    }


    function setAssetType(uint256 _tokenID, uint8 _type) public {
        tokenType[_tokenID] = _type;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal pure override returns (string memory) {
        return ("ipfs://");
    }

    function isOwnedBy (uint256 _id, address _addr) public view returns (bool) {
        // TODO need to fix this
        return (ownerOf(_id) == _addr);
    }
}
