// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;
import "./iMarketClosure.sol";

contract MarketClosure is iMarketClosure{
    
    // Orders received
    address[] public  Providers;
    address[] public  Consumers;
    uint public immutable numProviders;
    uint public immutable numConsumers;
    // Matched data
    uint public immutable MarketPrice;
    uint public immutable MarketQuantity;
    uint public immutable MarketVolume;
    constructor(
        uint marketPrice_,
        uint marketQuantity_,
        uint marketVolume_,
        uint numProviders_,
        address[] memory providers_,
        uint numConsumers_,
        address[] memory consumers_ 
    ) {  
        MarketPrice = marketPrice_;
        MarketQuantity = marketQuantity_;
        MarketVolume = marketVolume_;
        numProviders = numProviders_;
        Providers = providers_;
        numConsumers = numConsumers_;
        Consumers = consumers_; 
    }
}
