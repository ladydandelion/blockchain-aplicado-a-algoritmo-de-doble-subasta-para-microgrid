// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;
import "./Order.sol";

interface iMarket {
    // Open the market and start the double aution phase
    function open() external;

    // Close the market
    function close() external;

    // Reset the market to start a new cycle and return the factory index of the closure of the previous cycle
    function recycle() external returns (uint);

    // Get Market state
    function isOpen() external returns (bool);
    function isCleared() external returns (bool);

    // Get the market clearing values
    function getMarketPrice() external returns (uint);

    function getMarketQuantity() external returns (uint);

    function getMarketVolume() external returns (uint);

    // Add an order to the market and update the global market values
    function addSellOrder(Order) external payable;

    function addBuyOrder(Order) external payable;

    // Read the orders in the market
    function getOrder(address) external returns (bool exists_, Order order_);

    // Market clearing and set the market selling price and off-market price
    function clearing() external ;

    // Send events to agents after clearing
    function notifyAgents() external;
}
