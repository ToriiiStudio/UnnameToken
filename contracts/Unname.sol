//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Unname is EIP712, ERC1155{

	using SafeMath for uint256;
	using Strings for uint256;

	// Variables
	// ------------------------------------------------------------------------
	// string private _name = "PlateForm by Unname Token";
	string private _name = "P";
	string private _symbol = "PFUT"; // 
	
	uint256 public MAX_NORMAL_TOKEN = 2200;
	uint256 public MAX_SPECIAL_TOKEN = 22;
	uint256 public SPECIAL_CARD_CONDITION = 3; // 
	uint256 public MAX_ADDRESS_TOKEN = 10; //
	uint256 public PRICE = 0.2 ether; //
	uint256 public saleTimestamp = 1642410000; //
	uint256 public normalSupply = 0;
	uint256 public specialSupply = 0;
	uint256 public claimStageLimit = 30;
	uint256 public auctionStageLimit = 2200;
	uint256 public specialCardId = 21; 
	
	bool public hasSaleStarted = false; 
	bool public hasClaimStarted = false; 
	bool public hasAuctionStarted = false; 
	bool public whitelistSwitch = false;
	bool public burnStarted = false;

	address public owner = 0xCf3eD5Eb7850c885AbD6F0170c1fA66ef7c758fF;
	address public treasury = 0xCf3eD5Eb7850c885AbD6F0170c1fA66ef7c758fF;
	address public signer = 0xCf3eD5Eb7850c885AbD6F0170c1fA66ef7c758fF;

    // Dutch auction config
    uint256 public auctionStartTimestamp; 
    uint256 public auctionTimeStep;
    uint256 public auctionStartPrice;
    uint256 public auctionEndPrice;
    uint256 public auctionPriceStep;
    uint256 public auctionStepNumber;

	mapping (uint256 => uint256) public quantityLimit;
	mapping (uint256 => uint256) public idHasMinted;
	mapping (address => uint256) public addressHasMinted;
	mapping (address => uint256) public addressHasClaimed;

	// Constructor
	// ------------------------------------------------------------------------
	constructor()
	ERC1155("http://api.unnametoken.com/Metadata/{id}")
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

		return signer == recoveredAddr;
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
		require(quantity > 0 && idHasMinted[id].add(quantity) <= quantityLimit[id], "Exceeds id quantity limit.");

		_mint(to, id, quantity, "");

		if (id > 20) {
			specialSupply = specialSupply.add(quantity);
		} else {
			normalSupply = normalSupply.add(quantity);
		}
		idHasMinted[id] = idHasMinted[id].add(quantity);

		emit mintEvent(to, id, quantity, totalSupply());
	}

	// Claim special card functions
	// ------------------------------------------------------------------------
	function claimSpecial(uint256 maxQuantity, bytes memory SIGNATURE) external payable{
		require(hasClaimStarted == true, "Claim has not started.");
		require(block.timestamp >= saleTimestamp, "NOT_IN_CLAIM_TIME");
		require(specialCardId <= claimStageLimit, "Exceed the special id of claim at this stage.");
		require(verify(maxQuantity, SIGNATURE), "Not eligible for claim.");
		
		uint256 tokenNum = 0;
		for (uint index = 1; index < 21; index++){
			if (balanceOf(msg.sender, index) != 0){
				tokenNum = tokenNum + 1;
			}
		}

		require(tokenNum >= SPECIAL_CARD_CONDITION, "Not enough normal card.");
		require(msg.value >= PRICE, "Ether value sent is not equal to the price.");
		require(specialSupply.add(1) <= MAX_SPECIAL_TOKEN, "Exceeds MAX_SPECIAL_TOKEN.");
		require(idHasMinted[specialCardId].add(1) <= quantityLimit[specialCardId], "Exceeds id quantity limit.");
		require(addressHasClaimed[msg.sender].add(1) <= maxQuantity, "Exceeds claim quantity.");

		idHasMinted[specialCardId] = idHasMinted[specialCardId].add(1);
		addressHasClaimed[msg.sender] = addressHasClaimed[msg.sender].add(1);
		
		_mint(msg.sender, specialCardId, 1, "");

		specialSupply = specialSupply.add(1);
		emit mintEvent(msg.sender, specialCardId, 1, totalSupply());
		specialCardId = specialCardId + 1; 
	}

	// Mint normal card functions
	// ------------------------------------------------------------------------
	function mintNormal(uint256 quantity, uint256 maxQuantity, bytes memory SIGNATURE) external payable onlySale callerIsUser{
		if (whitelistSwitch == true) {
			require(verify(maxQuantity, SIGNATURE), "Not eligible for whitelist.");
			MAX_ADDRESS_TOKEN = maxQuantity;
		}
		if (hasAuctionStarted == true) {
			require(msg.value >= getDutchAuctionPrice().mul(quantity), "Ether value sent is not enough.");
			require(quantity > 0 && normalSupply.add(quantity) <= auctionStageLimit, "Exceeds MAX_NORMAL_TOKEN.");
		} else {
			require(msg.value >= PRICE.mul(quantity), "Ether value sent is not equal to the price.");
		}
		require(quantity > 0 && normalSupply.add(quantity) <= MAX_NORMAL_TOKEN, "Exceeds MAX_NORMAL_TOKEN.");
		require(addressHasMinted[msg.sender].add(quantity) <= MAX_ADDRESS_TOKEN, "Exceeds quantity.");

		uint256 randomNum;
		uint256 tokenId;
		addressHasMinted[msg.sender] = addressHasMinted[msg.sender].add(quantity);
		
        for (uint index = 0; index < quantity; index++) {
            string memory seed = string(abi.encodePacked(msg.sender, index, block.timestamp));
            randomNum = random(seed);
			tokenId = randomNum + 1;

			while(idHasMinted[tokenId].add(1) > quantityLimit[tokenId]) {
				tokenId = tokenId + 1;
				if (tokenId > 20) {
					tokenId = 1;
				}
			}		
			idHasMinted[tokenId] = idHasMinted[tokenId].add(1);

			_mint(msg.sender, tokenId, 1, "");

			normalSupply = normalSupply.add(1);
			emit mintEvent(msg.sender, tokenId, 1, totalSupply());
        }
	}

	// Burn functions
	// ------------------------------------------------------------------------
    function burn(address account, uint256 id, uint256 quantity) public virtual {
        require(burnStarted == true, "Burn hasn't started.");
        require(account == tx.origin || isApprovedForAll(account, _msgSender()), "Caller is not owner nor approved.");

        _burn(account, id, quantity);
    }

	// TotalSupply functions
	// ------------------------------------------------------------------------
	function totalSupply() public view returns (uint256) {
		return normalSupply + specialSupply;
	}


	// Setting functions
	// ------------------------------------------------------------------------
	function setTokenLimit(uint256 _MAX_NORMAL_TOKEN, uint256 _MAX_SPECIAL_TOKEN, uint256 _SPECIAL_CARD_CONDITION, uint256 _MAX_ADDRESS_TOKEN, uint256 _specialCardId) external onlyOwner {
		MAX_NORMAL_TOKEN = _MAX_NORMAL_TOKEN;
		MAX_SPECIAL_TOKEN = _MAX_SPECIAL_TOKEN;
		SPECIAL_CARD_CONDITION = _SPECIAL_CARD_CONDITION;
		MAX_ADDRESS_TOKEN = _MAX_ADDRESS_TOKEN;
		specialCardId = _specialCardId;
	}

	function setIdLimit(uint256 _id, uint256 _MAX) external onlyOwner {
		quantityLimit[_id] = _MAX;
	}

	function setPRICE(uint256 _price) external onlyOwner {
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
	
    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "SETTING_ZERO_ADDRESS");
        signer = _signer;
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
