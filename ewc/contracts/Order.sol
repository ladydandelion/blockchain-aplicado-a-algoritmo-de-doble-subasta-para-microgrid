// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;


// #if _DEBUG
//import "hardhat/console.sol";
// #endif

// TODO
// Quantity -> uint64
// Price -> uint16
// Number of agents -> uint8
// Volume -> uint

abstract contract Order {
    enum orderType {
        CONSUMER,
        PROVIDER
    }

    orderType internal immutable _type;
    address payable public immutable owner;
    uint public immutable originalAmmount;
    uint public immutable originalPrice;
    uint public marketAmmount;
    uint public marketPrice = 0;
    bool public inOffMarket = false;
    address public immutable marketAddr;
    bool used = false;

    modifier onlyMarket() {
        require(msg.sender == marketAddr, "!mktAddr");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    modifier onlyNotUsed() {
        require(!used);
        _;
    }

    constructor(orderType type_, uint ammount_, uint price_, address market_) {
        _type = type_;
        owner = payable(msg.sender);
        originalAmmount = ammount_;
        marketAmmount = ammount_;
        originalPrice = price_;
        marketAddr = market_;
    }

    function getType() public view virtual returns (orderType) {
        return _type;
    }

    function setAmmount(uint v_) public onlyMarket onlyNotUsed { 
        marketAmmount = v_;
    }

    function setPrice(uint v_) public onlyMarket onlyNotUsed {
        marketPrice = v_;
    }

    function setInOffMarket(bool f_) public onlyMarket onlyNotUsed {
        inOffMarket = f_;
    }

    function setUsed() public onlyMarket {
        used = true;
    }
}

contract BuyOrder is Order {
    constructor(
        uint ammount_,
        uint price_,
        address market_
    ) Order(orderType.CONSUMER, ammount_, price_, market_) {}
}

contract SellOrder is Order {
    constructor(
        uint ammount_,
        uint price_,
        address market_
    ) Order(orderType.PROVIDER, ammount_, price_, market_) {}
}
