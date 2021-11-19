// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//
// The Kiwi NFT represents the egg itself and ultimately the released
// bird after it has been incubated.
// Metadata of this NFT will update as it progresses through its life stages.
//  - egg (photo)
//  - hatching (video stream)
//  - release (video stream)
// Ownership also entitles the owner to a gated Discord group.
// 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//import "@openzeppelin/contracts/introspection/IERC165.sol";
// import "./Royalty.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Kiwi is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
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