const hre = require("hardhat");

var faunadb = require('faunadb');
var q = faunadb.query;
var adminClient = new faunadb.Client({
	secret: process.env.REACT_APP_FAUNA_KEY
});

async function main() {

	let nftAddress = "0x7296334165fC627d9Ed0D432d590b1475c2f3f2F"; //
	let owner = new ethers.Wallet(process.env.SIGNER_PRIVATE_KEY); //
	let serial = 0;
	let maxQuantity = 3;
	let addressForClaim = ['0x5279246e3626cebe71a4c181382a50a71d2a4156', '0xd56e7bcf62a417b821e6cf7ee16df7715a3e82ab'];

	for (let i = 0; i < addressForClaim.length; i++) {
		const domain = {
			name: 'Unname',
			version: '1.0.0',
			chainId: 4, //
			verifyingContract: nftAddress
		};

		const types = {
			NFT: [{
					name: 'addressForClaim',
					type: 'address'
				},
				{
					name: 'maxQuantity',
					type: 'uint256'
				},
			],
		};

		const value = {
			addressForClaim: addressForClaim[i],
			maxQuantity: maxQuantity
		};

		signature = await owner._signTypedData(domain, types, value);
		console.log(signature);

		var creat = await adminClient.query(q.Create(q.Ref(q.Collection('Claim'), serial + i), {
			data: {
				address: addressForClaim[i],
				maxNum: maxQuantity,
				signature: signature
			}
		}));

		console.log(creat);	
	}
}

main()
	.then(() => process.exit(0))
	.catch(error => {
		console.error(error);
		process.exit(1);
	});