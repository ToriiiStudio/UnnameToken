const hre = require("hardhat");

// var faunadb = require('faunadb');
// var q = faunadb.query;
// var adminClient = new faunadb.Client({
// 	secret: process.env.REACT_APP_FAUNA_KEY
// });

async function main() {

	let nftAddress = "0x1dC43CBDa2f3743125dD9159A7e56FF81ee64477"; //
	let owner = new ethers.Wallet(process.env.RINKEBY_PRIVATE_KEY); //
	let serial = 0;
	let maxQuantity = 1;
	let addressForClaim = ['0x5279246E3626Cebe71a4c181382A50a71d2A4156'];

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

		// var creat = await adminClient.query(q.Create(q.Ref(q.Collection('Whitelist'), serial + i), {
		// 	data: {
		// 		address: addressForClaim[i],
		// 		maxNum: maxQuantity,
		// 		signature: signature
		// 	}
		// }));

		// console.log(creat);	
	}
}

main()
	.then(() => process.exit(0))
	.catch(error => {
		console.error(error);
		process.exit(1);
	});