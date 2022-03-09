const {
	assert,
	expect
} = require('chai');
const {
	BN,
	time,
	expectRevert,
	constants,
	balance
} = require('@openzeppelin/test-helpers');
const {
	artifacts,
	ethers
} = require('hardhat');

describe("Unname", function () {

	let Token;
	let contract;
	let owner;
	let addr1;
	let addr2;
	let addr3;
	let addrs;

	before(async function () {

		Token = await ethers.getContractFactory("Unname");
		[owner, addr1, addr2, addr3,...addrs] = await ethers.getSigners();

		contract = await Token.deploy();
		console.log("Unname deployed to:", contract.address);
		console.log("Owner address:", owner.address);

	});

	describe("Unname Test", function () {


		// Giveaway functions
		// ------------------------------------------------------------------------
		// it("giveawayNFT Function", async function () {

			// await contract.connect(owner).giveawayNFT(owner.address, 1, 50);
			// await contract.connect(owner).giveawayNFT(owner.address, 1, 111);

			// await contract.connect(owner).giveawayNFT(addr1.address, 21, 1);
			// await contract.connect(owner).giveawayNFT(addr1.address, 22, 1);


			// expect(await contract.totalSupply()).to.equal(52);
			// console.log(await contract.totalSupply());
	
		// });

		// Mint normal card functions
		// ------------------------------------------------------------------------
		// it("mintNormal Function", async function () {

			// public
			// ------------------------------------------------------------------------
			// await contract.connect(owner).mintNormal(2200, 2200, 
			// 	"0xb3827d9bf516ab2a4465339745", 
			// 	{value: "264120000000000000"});
			// expect(await contract.totalSupply()).to.equal(2200);
			
			// for (i = 0; i < 2200; i ++){
			// 	await contract.connect(owner).mintNormal(1, 1, 
			// 	"0xb3827d9bf516ab2a4465339745", 
			// 	{value: "120000000000000"});
			// }

			// whitelist
			// ------------------------------------------------------------------------
			// await contract.setSaleSwitch(1, 0, 0, 1, 1642410000);
			// let maxQuantity = 2200;
			// const domain = {
			// 	name: 'Unname',
			// 	version: '1.0.0',
			// 	chainId: 31337,
			// 	verifyingContract: '0x668eD30aAcC7C7c206aAF1327d733226416233E2'
			// };
			// const types = {
			// 	NFT: [{
			// 			name: 'addressForClaim',
			// 			type: 'address'
			// 		},
			// 		{
			// 			name: 'maxQuantity',
			// 			type: 'uint256'
			// 		},
			// 	],
			// };
			// const value = {
			// 	addressForClaim: addr1.address,
			// 	maxQuantity: maxQuantity
			// };
			// signature = await owner._signTypedData(domain, types, value);
			// // console.log(signature);
			// await contract.connect(addr1).mintNormal(maxQuantity, maxQuantity, signature, {value: "264000000000000000"});			
		// });
			


		// Claim special card functions
		// ------------------------------------------------------------------------
		// it("claimSpecial Function", async function () {

		// 	await contract.connect(addr1).mintNormal(5, 5, "0xbb", {value: "600000000000000"});

		// 	let maxQuantity = 1;

		// 	const domain = {
		// 		name: 'Unname',
		// 		version: '1.0.0',
		// 		chainId: 31337,
		// 		verifyingContract: '0x668eD30aAcC7C7c206aAF1327d733226416233E2'
		// 	};

		// 	const types = {
		// 		NFT: [{
		// 				name: 'addressForClaim',
		// 				type: 'address'
		// 			},
		// 			{
		// 				name: 'maxQuantity',
		// 				type: 'uint256'
		// 			},
		// 		],
		// 	};

		// 	var value = {
		// 		addressForClaim: addr1.address,
		// 		maxQuantity: maxQuantity
		// 	};

		// 	signature = await owner._signTypedData(domain, types, value);
		// 	await contract.connect(addr1).claimSpecial(maxQuantity, signature, {value: "120000000000000"});			
		// });
		
		// Withdrawal functions
		// ------------------------------------------------------------------------
		// it("withdrawAll Function", async function () {

		// 	await contract.connect(owner).withdrawAll();

		// });
	});
});