require("@nomicfoundation/hardhat-toolbox");
require('hardhat-deploy');
//require("@nomiclabs/hardhat-solpp");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  paths: {
    artifacts: './src/artifacts',
  },
  solidity: "0.8.18",
  solpp:{
    defs:{
      "_DEBUG":false,
    },
    collapseEmptyLines: true,
    noFlatten: true,
  },
  defaultNetwork: "hardhat",
  networks: {
      hardhat: {
          chainId: 31337,
      },
  },
  namedAccounts: {
      deployer: {
          default: 0
      },
  },
}
