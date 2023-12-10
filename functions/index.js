const functions = require("firebase-functions");
const dotenv = require("dotenv");
const HDWalletProvider = require("@truffle/hdwallet-provider");
const Web3 = require("web3");
const { ADDR_MAP } = require("./constants/constant");
const { RPC_MAP } = require("./constants/RPCs");
const FACTORY = require("./constants/ABI.json");
const MYNFT = require("./constants/MyNFT.json");

dotenv.config();

exports.depositNFT = functions.firestore
  .document(`moralis/events/Omnione/{id}`)
  .onCreate(async (snap) => {
    const { action } = snap.data();

    if (action === "0") {
      console.log(action);
      const {
        _name,
        symbol,
        baseURL,
        baseExt,
        owner,
        srcCollectionAddress,
        chainIds,
        initIdMul,
      } = snap.data();

      const chains = chainIds.split(",");
      console.log(chains);
      for (var i = 0; i < chains.length; i++) {
        console.log("Chain Id", chains[i]);
        try {
          // ADMIN CREDENTIALS
          const adminPrivKey = process.env.PRIVATE_KEY;
          // EVM PROVIDER && EVM_BRIDGE CONTRACT INIT
          const provider = new HDWalletProvider({
            mnemonic: process.env.MNEMONICS,
            providerOrUrl: RPC_MAP[chains[i]],
            pollingInterval: 8000,
          });
          const web3ZkEVM = new Web3(provider);

          const { address: adminZkEVM } =
            web3ZkEVM.eth.accounts.wallet.add(adminPrivKey);

          const zkEVMBridgeInstance = new web3ZkEVM.eth.Contract(
            FACTORY.abi,
            ADDR_MAP[chains[i]]
          );
          const tx = zkEVMBridgeInstance.methods.omnicollmint(
            _name,
            symbol,
            baseURL,
            baseExt,
            owner,
            srcCollectionAddress,
            initIdMul * (i + 1)
          );

          const [gasPrice, gasCost] = await Promise.all([
            web3ZkEVM.eth.getGasPrice(),
            tx.estimateGas({ from: adminZkEVM }),
          ]);

          const data = tx.encodeABI();

          const txData = {
            from: adminZkEVM,
            to: zkEVMBridgeInstance.options.address,
            data,
            gas: gasCost,
            gasPrice,
          };

          const receipt = await web3ZkEVM.eth.sendTransaction(txData);
          console.log("Receipt", receipt.transactionHash);
        } catch (error) {
          console.log(error);
        }
      }
    } else if (action === "1") {
      console.log(action);
      const { srcCollectionAddress, minter, chainIds } = snap.data();
      const chains = chainIds.split(",");
      for (var i = 0; i < chains.length; i++) {
        console.log("Chain Id", chains[i]);
        // ADMIN CREDENTIALS
        const adminPrivKey = process.env.PRIVATE_KEY;
        // EVM PROVIDER && EVM_BRIDGE CONTRACT INIT
        const provider = new HDWalletProvider({
          mnemonic: process.env.MNEMONICS,
          providerOrUrl: RPC_MAP[chains[i]],
          pollingInterval: 8000,
        });
        const web3ZkEVM = new Web3(provider);

        const { address: adminZkEVM } =
          web3ZkEVM.eth.accounts.wallet.add(adminPrivKey);

        const zkEVMBridgeInstance = new web3ZkEVM.eth.Contract(
          FACTORY.abi,
          ADDR_MAP[chains[i]]
        );
        const tx = zkEVMBridgeInstance.methods.omninftmint(
          srcCollectionAddress,
          minter
        );
        const [gasPrice, gasCost] = await Promise.all([
          web3ZkEVM.eth.getGasPrice(),
          tx.estimateGas({ from: adminZkEVM }),
        ]);

        const data = tx.encodeABI();

        const txData = {
          from: adminZkEVM,
          to: zkEVMBridgeInstance.options.address,
          data,
          gas: gasCost,
          gasPrice,
        };

        const receipt = await web3ZkEVM.eth.sendTransaction(txData);
        console.log("Receipt", receipt.transactionHash);
      }
    } else if (action === "2") {
      console.log(action);
      const { tokenID, sender, uri } = snap.data();
      const adminPrivKey = process.env.PRIVATE_KEY;
      // EVM PROVIDER && EVM_BRIDGE CONTRACT INIT
      const provider = new HDWalletProvider({
        mnemonic: process.env.MNEMONICS,
        providerOrUrl: RPC_MAP["1442"],
        pollingInterval: 8000,
      });
      const web3ZkEVM = new Web3(provider);

      const { address: adminZkEVM } =
        web3ZkEVM.eth.accounts.wallet.add(adminPrivKey);

      const zkEVMBridgeInstance = new web3ZkEVM.eth.Contract(
        MYNFT.abi,
        "0xC4F3998B5FC10d191cAA7AC31C2443C8Aa87592A"
      );

      const tx = zkEVMBridgeInstance.methods.mint(tokenID, sender, uri);
      const [gasPrice, gasCost] = await Promise.all([
        web3ZkEVM.eth.getGasPrice(),
        tx.estimateGas({ from: adminZkEVM }),
      ]);

      const data = tx.encodeABI();

      const txData = {
        from: adminZkEVM,
        to: zkEVMBridgeInstance.options.address,
        data,
        gas: gasCost,
        gasPrice,
      };

      const receipt = await web3ZkEVM.eth.sendTransaction(txData);
      console.log("MYNFT mint Receipt", receipt.transactionHash);
    }
  });
