const { ethers } = require("hardhat");
require("dotenv").config({ path: ".env"});
const { CRYPTO_DEV_TOKEN_CONTRACT_ADDRESS } = require("../constants");

async function main() {
    const cryptoDevTokenAddress = CRYPTO_DEV_TOKEN_CONTRACT_ADDRESS;
    /* 
        A contract factory in ethers js is used to deploy smart contracts 
    */

        const exchangeContract = await ethers.getContractFactory("Exchange");

        // lETS DEPLoy the contract
        const deployedExchangeContract = await exchangeContract.deploy(
            cryptoDevTokenAddress
        );
        await deployedExchangeContract.deployed();

        console.log("Exchange contract address : ", deployedExchangeContract.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
      console.error(error);
      process.exit(1);
  });