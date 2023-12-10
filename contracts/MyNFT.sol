// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract MyNFT is ERC721URIStorage, Ownable {
    
    constructor() ERC721("Degods", "DGOD") {}

    function mint(uint256 _tokenId,address to, string memory _uri) public onlyOwner {
        _safeMint(to, _tokenId);
        _setTokenURI(_tokenId, _uri);
    }
}
