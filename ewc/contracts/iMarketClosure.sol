// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

interface iMarketClosure {
    function MarketPrice() external returns (uint);
    function MarketQuantity() external returns (uint);
    function MarketVolume() external returns (uint);
    function numProviders() external returns( uint );
    function numConsumers() external returns( uint );
    function Providers(uint) external returns( address );
    function Consumers(uint) external returns( address );
}
