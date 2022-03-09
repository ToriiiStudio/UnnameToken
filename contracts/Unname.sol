//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "hardhat/console.sol"; //

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Unname is EIP712, ERC1155{

	using SafeMath for uint256;
	using Strings for uint256;

	// Variables
	// ------------------------------------------------------------------------
	string private _name = "U"; 
	string private _symbol = "U"; 
	
	uint256 public MAX_NORMAL_TOKEN = 2200;
	uint256 public MAX_SPECIAL_TOKEN = 22;
	uint256 public SPECIAL_CARD_CONDICTION = 3;
	uint256 public PRICE = 0.12 ether; 
	uint256 public saleTimestamp = 1642410000; 
	uint256 public totalSupply = 0;
	uint256 public normalSupply = 0;
	uint256 public specialSupply = 0;
	uint256 public claimStageLimit = 25;
	uint256 public auctionStageLimit = 2200;
	uint256 private specialCardId = 21; 
	
	bool public hasSaleStarted = true; 
	bool public hasClaimStarted = true; 
	bool public hasAuctionStarted = false; 
	bool public whitelistSwitch = false;
	bool public burnStarted = false;

	address public owner = 0x5279246E3626Cebe71a4c181382A50a71d2A4156;
	address public treasury = 0x5279246E3626Cebe71a4c181382A50a71d2A4156;

    // Dutch auction config
    uint256 public auctionStartTimestamp; 
    uint256 public auctionTimeStep;
    uint256 public auctionStartPrice;
    uint256 public auctionEndPrice;
    uint256 public auctionPriceStep;
    uint256 public auctionStepNumber;

	mapping (uint256 => uint256) public quantityLimit;
	mapping (uint256 => uint256) public hasMinted;

	// Constructor
	// ------------------------------------------------------------------------
	constructor()
	ERC1155("https://{id}")
	EIP712("Unname", "1.0.0")
	{
		for (uint index = 1; index < 21; index++){
			quantityLimit[index] = 110;
		}

		for (uint index = 21; index < 43; index++){
			quantityLimit[index] = 1;
		}
	} 
	
	function name() public view virtual returns (string memory) {
		return _name;
	}

	function symbol() public view virtual returns (string memory) {
		return _symbol;
	}

	// Events
	// ------------------------------------------------------------------------
	event mintEvent(address owner, uint256 id, uint256 quantity, uint256 totalSupply);

	// Modifiers
	// ------------------------------------------------------------------------
	function _onlyOwner() private view {
		require(msg.sender == owner, "You are not owner.");
	}

    modifier onlyOwner() {
		_onlyOwner();
        _;
    }

    modifier onlySale() {
		require(hasSaleStarted == true, "SALE_NOT_ACTIVE");
        require(block.timestamp >= saleTimestamp, "NOT_IN_SALE_TIME");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "CALLER_IS_CONTRACT");
        _;
    }

	// Verify functions
	// ------------------------------------------------------------------------
	function verify(uint256 maxQuantity, bytes memory SIGNATURE) public view returns (bool){
		address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(keccak256("NFT(address addressForClaim,uint256 maxQuantity)"), _msgSender(), maxQuantity))), SIGNATURE);

		return owner == recoveredAddr;
	}

	// Random functions
	// ------------------------------------------------------------------------
    function random(string memory seed) private pure returns (uint) {
        uint randomHash = uint(keccak256(abi.encode(seed)));

        return randomHash % 20;
    } 

	// Auction functions
	// ------------------------------------------------------------------------
    function getDutchAuctionPrice() public view returns (uint256) {
        require(hasAuctionStarted == true, "AUCTION_NOT_ACTIVE");

        if (block.timestamp < auctionStartTimestamp) {
            return auctionStartPrice;
        } else {
            // calculate step
            uint256 step = (block.timestamp - auctionStartTimestamp) / auctionTimeStep;
            if (step > auctionStepNumber) {
                step = auctionStepNumber;
            }

            // claculate final price
            if (auctionStartPrice > step * auctionPriceStep){
                return auctionStartPrice - step * auctionPriceStep;
            } else {
                return auctionEndPrice;
            }
        }
    }

	// Giveaway functions
	// ------------------------------------------------------------------------
	function giveawayNFT(address to, uint256 id, uint256 quantity) external onlyOwner{
		require(quantity > 0 && hasMinted[id].add(quantity) <= quantityLimit[id], "Exceeds id quantity limit.");

		_mint(to, id, quantity, "");

		if (id > 20) {
			specialSupply = specialSupply.add(quantity);
		} else {
			normalSupply = normalSupply.add(quantity);
		}
		totalSupply = normalSupply + specialSupply;
		hasMinted[id] = hasMinted[id].add(quantity);

		emit mintEvent(to, id, quantity, totalSupply);
	}

	// Claim special card functions
	// ------------------------------------------------------------------------
	function claimSpecial(uint256 maxQuantity, bytes memory SIGNATURE) external payable onlySale callerIsUser{
		require(hasClaimStarted == true, "Claim has not started.");
		require(specialCardId <= claimStageLimit, "Exceed the special id of claim at this stage.");
		require(verify(maxQuantity, SIGNATURE), "Not eligible for claim.");
		
		uint256 tokenNum = 0;
		for (uint index = 1; index < 21; index++){
			if (balanceOf(msg.sender, index) != 0){
				tokenNum = tokenNum + 1;
			}
		}

		require(tokenNum >= SPECIAL_CARD_CONDICTION, "Not enough normal card.");
		require(msg.value == PRICE, "Ether value sent is not equal the price.");
		require(specialSupply.add(1) <= MAX_SPECIAL_TOKEN, "Exceeds MAX_SPECIAL_TOKEN.");
		require(hasMinted[specialCardId].add(1) <= quantityLimit[specialCardId], "Exceeds id quantity limit.");
		
		_mint(msg.sender, specialCardId, 1, "");

		hasMinted[specialCardId] = hasMinted[specialCardId].add(1);
		specialSupply = specialSupply.add(1);
		totalSupply = totalSupply.add(1);	
		emit mintEvent(msg.sender, specialCardId, 1, totalSupply);
		specialCardId = specialCardId + 1; 
	}

	// Mint normal card functions
	// ------------------------------------------------------------------------
	function mintNormal(uint256 quantity, uint256 maxQuantity, bytes memory SIGNATURE) external payable onlySale callerIsUser{
		if (whitelistSwitch == true) {
			require(verify(maxQuantity, SIGNATURE), "Not eligible for whitelist.");
		}
		if (hasAuctionStarted == true) {
			require(msg.value >= getDutchAuctionPrice().mul(quantity), "Ether value sent is not enough.");
			require(quantity > 0 && normalSupply.add(quantity) <= auctionStageLimit, "Exceeds MAX_NORMAL_TOKEN.");
		} else {
			require(msg.value == PRICE.mul(quantity), "Ether value sent is not equal the price.");
		}
		require(quantity > 0 && normalSupply.add(quantity) <= MAX_NORMAL_TOKEN, "Exceeds MAX_NORMAL_TOKEN.");
		
		uint256 randomNum;
		uint256 tokenId;
        for (uint index = 0; index < quantity; index++) {
            string memory seed = string(abi.encodePacked(msg.sender, index, block.timestamp));
            randomNum = random(seed);
			tokenId = randomNum + 1;

			while(hasMinted[tokenId].add(1) > quantityLimit[tokenId]) {
				tokenId = tokenId + 1;
				if (tokenId > 20) {
					tokenId = 1;
				}
			}
			console.log(tokenId); //
			
			_mint(msg.sender, tokenId, 1, "");

			hasMinted[tokenId] = hasMinted[tokenId].add(1);
			normalSupply = normalSupply.add(1);
			totalSupply = totalSupply.add(1);			
			emit mintEvent(msg.sender, tokenId, 1, totalSupply);
        }
	}

	// Burn functions
	// ------------------------------------------------------------------------
    function burn(address account, uint256 id, uint256 quantity) public virtual {
        require(burnStarted == true, "Burn hasn't started.");
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "Caller is not owner nor approved.");

        _burn(account, id, quantity);
    }

	// // setting functions
	// // ------------------------------------------------------------------------
	function setTokenLimit(uint256 _MAX_NORMAL_TOKEN, uint256 _MAX_SPECIAL_TOKEN, uint256 _SPECIAL_CARD_CONDICTION) external onlyOwner {
		MAX_NORMAL_TOKEN = _MAX_NORMAL_TOKEN;
		MAX_SPECIAL_TOKEN = _MAX_SPECIAL_TOKEN;
		SPECIAL_CARD_CONDICTION = _SPECIAL_CARD_CONDICTION;
	}

	function setIdLimit(uint256 _id, uint256 _MAX) external onlyOwner {
		quantityLimit[_id] = _MAX;
	}

	function set_PRICE(uint256 _price) external onlyOwner {
		PRICE = _price;
	}

	function setStageLimit(uint _claimStageLimit, uint _auctionStageLimit) external onlyOwner {
		claimStageLimit = _claimStageLimit;
		auctionStageLimit = _auctionStageLimit;
	}

	function setBaseURI(string memory baseURI) public onlyOwner {
		_setURI(baseURI);
	}

	function setOwner(address _owner) public onlyOwner {
		owner = _owner;
	}

    function setBurn(bool _burnStarted) external onlyOwner {
        burnStarted = _burnStarted;
    }

    function setSaleSwitch(
		bool _hasSaleStarted, 
		bool _hasClaimStarted, 
		bool _hasAuctionStarted, 
		bool _whitelistSwitch, 
		uint256 _saleTimestamp
	) external onlyOwner {
        hasSaleStarted = _hasSaleStarted;
		hasClaimStarted = _hasClaimStarted;
		hasAuctionStarted = _hasAuctionStarted;
		whitelistSwitch = _whitelistSwitch;
        saleTimestamp = _saleTimestamp;
    }

    function setDutchAuction(
        uint256 _auctionStartTimestamp, 
        uint256 _auctionTimeStep, 
        uint256 _auctionStartPrice, 
        uint256 _auctionEndPrice, 
        uint256 _auctionPriceStep, 
        uint256 _auctionStepNumber
    ) external onlyOwner {
        auctionStartTimestamp = _auctionStartTimestamp;
        auctionTimeStep = _auctionTimeStep;
        auctionStartPrice = _auctionStartPrice;
        auctionEndPrice = _auctionEndPrice;
        auctionPriceStep = _auctionPriceStep;
        auctionStepNumber = _auctionStepNumber;
    }

	// Withdrawal functions
	// ------------------------------------------------------------------------
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

	function withdrawAll() public payable onlyOwner {
		require(payable(treasury).send(address(this).balance));
	}

}
