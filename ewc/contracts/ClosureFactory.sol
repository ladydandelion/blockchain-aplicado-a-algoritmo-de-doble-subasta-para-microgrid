// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;
//import "./Addresses.sol";
import "./MarketClosure.sol";
import "./GridDirectory.sol";

// #if _DEBUG
import "hardhat/console.sol";
// #endif

contract ClosureFactory{
    iMarketClosure[] internal _closures;
    address internal immutable _marketer;
    address internal _market = address(0);
    
    modifier onlyMarket() {
        require( _market != address(0) , "Invalid Market" );
        require( msg.sender == _market, "!mktAddr" ); 
        _;
    }

    modifier onlyMarketer() {
        require(
            msg.sender == _marketer,
            "!mkterAddr"
        );
        _;
    }

    constructor() {
        _marketer = msg.sender;
    }

    function setMarket( address mkt_ ) external onlyMarketer {
        _market = mkt_;
    }

    function createMarketClosure (
        uint marketPrice_, 
        uint marketQuantity_, 
        uint marketVolume_, 
        uint numProviders_, 
        address[] calldata providers_, 
        uint numConsumers_,
        address[] calldata consumers_
        ) external onlyMarket returns( uint index ){
            //# if _DEBUG
            /* console.log( "Market closure: marketPrice= %s numProviders= %s numConsumers= %s",
                marketPrice_, numProviders_, numConsumers_
            ); */
            //# endif
            MarketClosure closure = new MarketClosure( marketPrice_,
                                                        marketQuantity_,
                                                        marketVolume_, 
                                                        numProviders_, 
                                                        providers_, 
                                                        numConsumers_, 
                                                        consumers_);
            _closures.push(closure);
            return _closures.length - 1;
    }
    
}
