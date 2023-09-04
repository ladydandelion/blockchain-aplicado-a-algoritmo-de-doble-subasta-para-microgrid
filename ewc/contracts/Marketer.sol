// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

// #if _DEBUG
import "hardhat/console.sol";
// #endif

import "./Addresses.sol";
import "./GridDirectory.sol";
import "./ClosureFactory.sol";
import "./DoubleAuction_B.sol";

contract Marketer {
    uint constant MIN_PRICE = 10;
    uint constant MAX_PRICE = 1000;

    address public immutable owner;
    GridDirectory private immutable  _directory;
    ClosureFactory private immutable _factory;
    DoubleAuction_B private _market;

    // EVENTS
    event MarketCreated(address);

    // MODIFIERS
    modifier onlyDSO() {
        require(msg.sender == DSO, "!DSO");
        _;
    }

    constructor() {
        // Mode = Only one market per grid
        owner = DSO;

        _directory = new GridDirectory();
        _factory = new ClosureFactory();
        _market = new DoubleAuction_B( MAX_PRICE, MIN_PRICE, _directory, _factory );

        _factory.setMarket( address(_market) );

         // #if _DEBUG
        _loadDirectory();
        // #endif
        emit MarketCreated(address(_market));
    }

    function getMarket() external view onlyDSO returns (address) {
        return address( _market );
    }

    function getDirectory() external view onlyDSO returns (address) {
        return address( _directory );
    }

    function getFactory() external view onlyDSO returns (address) {
        return address( _factory );
    }


    function openMarket() external onlyDSO {
        _market.open();
    }

    function closeMarket() external onlyDSO{
        _market.close();
    }

    function recycleMarket() external onlyDSO{
        _market.recycle();
    }
    
    function marketClearing() external onlyDSO {
        _market.clearing();
    }

    function isOpen() external view returns (bool) {
        return _market.isOpen();
    }

    // PRIVATE & PROTECTED
    function _loadDirectory() private {
        _directory.addNode( address(this) );
        _directory.addNode( NODE_1 );
        _directory.addNode( NODE_2 );
        _directory.addNode( NODE_3 );
        _directory.addNode( NODE_4 );
        _directory.addNode( NODE_5 );
        _directory.addNode( NODE_6 );
    }
}