// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const NFT = artifacts.require("Unname");

async function main() {


  let nftAddress = "0x1dC43CBDa2f3743125dD9159A7e56FF81ee64477";//
  let nft = await NFT.at(nftAddress);

  await nft.withdrawAll();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
