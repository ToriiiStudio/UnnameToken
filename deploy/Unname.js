const { ethers } = require("hardhat");

const NFT = artifacts.require("Unname");

module.exports = async ({
  getNamedAccounts,
  deployments,
  getChainId,
  getUnnamedAccounts,
}) => {
  const {deploy, all} = deployments;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  console.log("");
  console.log("Deployer: ", deployer.address);

  nft = await deploy('Unname', {
    contract: "Unname",
    from: deployer.address,
    args: [
    ],
  });

  console.log("Unname address: ", nft.address);
};

module.exports.tags = ['Unname'];