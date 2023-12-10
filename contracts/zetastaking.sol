// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@zetachain/protocol-contracts/contracts/zevm/SystemContract.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/zContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@zetachain/toolkit/contracts/BytesHelperLib.sol";

contract OmniStaking is ERC20, zContract {
    SystemContract public immutable systemContract;
    uint256 public immutable chainIDETH;
    uint256 public immutable chainIDPOLY;
    uint256 public immutable chainIDBSC;
    uint256 constant BITCOIN = 18332;

    uint256 public rewardRateETH = 10;
    uint256 public rewardRatePOLY = 1000;
    uint256 public rewardRateBSC = 100;
    uint256 public rewardRateBTC = 1;


    error SenderNotSystemContract();
    error WrongChain(uint256 chainID);
    error UnknownAction(uint8 action);
    error Overflow();
    error Underflow();
    error WrongAmount();
    error NotAuthorized();
    error NoRewardsToClaim();
   
    mapping(address =>mapping( uint256 =>uint256)) public omnistake;
    mapping(address => address) public beneficiary;
    mapping(address => bytes) public withdraw;
    mapping(address => mapping(uint256 =>uint256)) public lastStakeTime;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 chainIDETH_,
        uint256 chainIDPOLY_,
        uint256 chainIDBSC_,
        address systemContractAddress
    ) ERC20(name_, symbol_) {
        systemContract = SystemContract(systemContractAddress);
        chainIDETH = chainIDETH_;
        chainIDPOLY = chainIDPOLY_;
        chainIDBSC = chainIDBSC_;
    }

    modifier onlySystem() {
        require(
            msg.sender == address(systemContract),
            "Only system contract can call this function"
        );
        _;
    }

    function onCrossChainCall(
        zContext calldata context,
        address zrc20,
        uint256 amount,
        bytes calldata message
    ) external virtual override onlySystem {

        address staker = BytesHelperLib.bytesToAddress(context.origin, 0);

        uint8 action = context.chainID == BITCOIN
            ? uint8(message[0])
            : abi.decode(message, (uint8));

        if (action == 1) {
            stakeZRC(staker, amount,context.chainID);
        } else if (action == 2) {
            unstakeZRC(staker,context.chainID);
        } else if (action == 3) {
            setBeneficiary(staker, message,context.chainID);
        } else if (action == 4) {
            setWithdraw(staker, message, context.origin,context.chainID);
        } else {
            revert UnknownAction(action);
        }
    }

    function stakeZRC(address staker, uint256 amount, uint256 chainID) internal {
        omnistake[staker][chainID]+= amount;
        if (omnistake[staker][chainID] < amount) revert Overflow();
        beneficiary[staker] = staker;
        lastStakeTime[staker][chainID] = block.timestamp;
        updateRewards(staker,chainID);
    }

    function updateRewards(address staker,uint256 chainID) internal {
        uint256 rewardAmount = queryRewards(staker,chainID);

        _mint(beneficiary[staker], rewardAmount);
        lastStakeTime[staker][chainID] = block.timestamp;
    }

    function queryRewards(address staker,uint256 chainID) public view returns (uint256) {
        uint256 rewardRate;
        if(chainID == chainIDETH) {
            rewardRate = rewardRateETH;
        } else if(chainID == chainIDPOLY){
             rewardRate = rewardRatePOLY;
        } else if(chainID == chainIDBSC){
             rewardRate = rewardRateBSC;
        } else if(chainID == BITCOIN){
             rewardRate = rewardRateBTC;
        } else {
            revert WrongChain(chainID);
        }
        uint256 timeDifference = block.timestamp - lastStakeTime[staker][chainID];
        uint256 rewardAmount = timeDifference * omnistake[staker][chainID] * rewardRate;
        return rewardAmount;
    }

    function unstakeZRC(address staker,uint256 chainID) internal {
        uint256 amount = omnistake[staker][chainID];

        updateRewards(staker,chainID);

        address zrc20 = systemContract.gasCoinZRC20ByChainId(chainID);
        (, uint256 gasFee) = IZRC20(zrc20).withdrawGasFee();

        if (amount < gasFee) revert WrongAmount();

        bytes memory recipient = withdraw[staker];

        omnistake[staker][chainID] = 0;

        IZRC20(zrc20).approve(zrc20, gasFee);
        IZRC20(zrc20).withdraw(recipient, amount - gasFee);

        if (omnistake[staker][chainID] > amount) revert Underflow();

        lastStakeTime[staker][chainID] = block.timestamp;
    }

    function setBeneficiary(address staker, bytes calldata message,uint256 chainID) internal {
        address beneficiaryAddress;
        if (chainID == BITCOIN) {
            beneficiaryAddress = BytesHelperLib.bytesToAddress(message, 1);
        } else {
            (, beneficiaryAddress) = abi.decode(message, (uint8, address));
        }
        beneficiary[staker] = beneficiaryAddress;
    }

    function setWithdraw(
        address staker,
        bytes calldata message,
        bytes memory origin,
        uint256 chainID
    ) internal {
        bytes memory withdrawAddress;
        if (chainID == BITCOIN) {
            withdrawAddress = bytesToBech32Bytes(message, 1);
        } else {
            withdrawAddress = origin;
        }
        withdraw[staker] = withdrawAddress;
    }

    function bytesToBech32Bytes(
        bytes calldata data,
        uint256 offset
    ) internal pure returns (bytes memory) {
        bytes memory bech32Bytes = new bytes(42);
        for (uint i = 0; i < 42; i++) {
            bech32Bytes[i] = data[i + offset];
        }

        return bech32Bytes;
    }

    function claimRewards(address staker, uint256 chainID) external {
        if (beneficiary[staker] != msg.sender) revert NotAuthorized();
        uint256 rewardAmount = queryRewards(staker,chainID);
        if (rewardAmount <= 0) revert NoRewardsToClaim();
        updateRewards(staker,chainID);
    }
}
