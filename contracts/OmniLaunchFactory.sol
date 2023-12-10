// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./OmniNFTContract.sol";

contract OmniLaunchFactory is Ownable {

    //uint256 lockInPeriod = 3 * 24 * 60 * 60 * 365; // 3 years lockin time (chain dependent) - Mainnet
    uint256 lockInPeriod = 10; // 10 seconds lockin time (chain dependent) - Testnet

    struct ProjectInfo {
        address projectAddress;
        uint256 createdAt;
    }

    mapping(address => address) public omnichainaddressmapper;
    mapping(address => ProjectInfo) public projectInfo;

    constructor() {}

    receive() external payable {}

    error FailedToWithdrawEth(address owner, address target, uint256 value);

    event DEPOSIT(
        uint256 action,
        uint256 tokenID,
        address sender,
        string uri
    );

    event OMNIMINT(
        string name,
        string symbol,
        string baseURL,
        string baseExt,
        address owner,
        address srcCollectionAddress
    );

    event SRCMINT(
        uint256 action,
        string name,
        string symbol,
        string baseURL,
        string baseExt,
        address owner,
        address srcCollectionAddress,
        uint256[] chainIds,
        uint256 initIdMul
    );

    event SRCNFTMINT(
        uint256 action,
        address srcCollectionAddress,
        address minter,
        uint256[] chainIds
    );

       //Core Bridge Logic
    function brigde(
        address collectionAddress,
        uint256 _tokenID,
        string memory uri
    ) external payable returns (bool) {
        //approve address(this) to transfer your tokens that you want to deposit and get your wrapped tokens
        require(collectionAddress != address(0), "Cannot be address 0");
        
        IERC721(collectionAddress).transferFrom(
            _msgSender(),
            owner(),
            _tokenID);    

        emit DEPOSIT(
            2,
            _tokenID,
            msg.sender,
            uri
        );
        return true;
    }

    function srccollmint(string memory _name, string memory _symbol,string memory _baseuri,string memory _baseExt,address _owner,uint256[] memory _chainIds,uint256 _initIdMul) external  {
        NFTContract nftcontract = new NFTContract(_name,_symbol,_baseuri,_baseExt,0);
        nftcontract.transferOwnership(_owner);
        projectInfo[address(nftcontract)] = ProjectInfo(address(nftcontract),block.timestamp);
        emit SRCMINT(0,_name,_symbol,_baseuri,_baseExt,_owner,address(nftcontract),_chainIds,_initIdMul);
    }

    function omnicollmint(string memory _name, string memory _symbol,string memory _baseuri,string memory _baseExt,address _owner, address srcChainCollectionAddr,uint256 _initId) external onlyOwner()  {
        NFTContract nftcontract = new NFTContract(_name,_symbol,_baseuri,_baseExt,_initId);
        nftcontract.transferOwnership(_owner);
        omnichainaddressmapper[srcChainCollectionAddr] = address(nftcontract);
        emit OMNIMINT(_name,_symbol,_baseuri,_baseExt,_owner,address(nftcontract));
    }

    function srcnftmint(address _srccollAddress, address _to, uint256[] memory _chainIds, uint256 _price) external payable {
        require(msg.value >= _price * _chainIds.length,"Not enough amount to pay");
        NFTContract(_srccollAddress).safeMint(_to);
        (bool sent, ) = owner().call{value: msg.value}("");
        if (!sent) revert FailedToWithdrawEth(msg.sender, owner(), msg.value);
        emit SRCNFTMINT(1,_srccollAddress,_to,_chainIds);
    }

    function omninftmint(address _srccollAddress, address _to) external {
        NFTContract((omnichainaddressmapper[_srccollAddress])).safeMint(_to);
    }

    function incentiviseProjects(address beneficiary,uint _amount, address _projectAddress) public onlyOwner {
        require(projectInfo[_projectAddress].createdAt + lockInPeriod < block.timestamp, "Not locked in enough time");
        (bool sent, ) = beneficiary.call{value: _amount}("");
        if (!sent) revert FailedToWithdrawEth(msg.sender, beneficiary, _amount);
    }

    function withdraw(address beneficiary) public onlyOwner {
            uint256 amount = address(this).balance;
            (bool sent, ) = beneficiary.call{value: amount}("");
            if (!sent) revert FailedToWithdrawEth(msg.sender, beneficiary, amount);
    }

    function withdrawToken(
        address beneficiary,
        address token
    ) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(beneficiary, amount);
    }
}