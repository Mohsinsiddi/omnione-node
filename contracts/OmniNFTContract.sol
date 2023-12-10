// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract NFTContract is ERC721, ERC721URIStorage,ERC721Enumerable ,Ownable {

    using Strings for uint256;
    uint256 private _nextTokenId;
    string public baseURI;
    string public baseExtension;
       

    constructor(string memory _name, string memory _symbol,string memory _baseuri,string memory _baseExt, uint256 _initId) ERC721(_name, _symbol) {
        baseURI = _baseuri;
        baseExtension = _baseExt;
        _nextTokenId = _initId;
    }

    function _baseURI() internal view  override returns (string memory) {
        return baseURI;
    }

    function safeMint(address to) external {
        uint256 tokenId = _nextTokenId+1;
        _nextTokenId++;
        string memory currentBaseURI = _baseURI();
        string memory _uri = bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
        _safeMint(to, tokenId);

        if(bytes(_uri).length > 0){
            _setTokenURI(tokenId, _uri);
        }
    }

    // The following functions are overrides required by Solidity.

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
        override(ERC721,ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn( uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
         super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721,ERC721Enumerable ) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

}