// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const NFT = artifacts.require("Unname");

async function main() {

  let nftAddress = "0x1dC43CBDa2f3743125dD9159A7e56FF81ee64477";
  let nft = await NFT.at(nftAddress);
  // let chainId = await ethers.provider.getNetwork()
  let owner = new ethers.Wallet(process.env.RINKEBY_PRIVATE_KEY);
  let quantity = 1;
  let maxQuantity = 2;

  const domain = {
    name: 'Unname',
    version: '1.0.0',
    chainId: 4,
    verifyingContract: nftAddress
  };

  const types = {
    NFT: [
        { name: 'addressForClaim', type: 'address' },
        { name: 'maxQuantity', type: 'uint256' },
    ],
  };

  const value = { addressForClaim: "0x5279246E3626Cebe71a4c181382A50a71d2A4156", maxQuantity: 2};

  signature = await owner._signTypedData(domain, types, value);
  console.log(signature);

  await nft.mintNormal(quantity, maxQuantity, signature, {value: "1000000000000000000"});
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
