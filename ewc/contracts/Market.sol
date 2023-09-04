// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;
import "./iMarket.sol";

// #if _DEBUG
import "hardhat/console.sol";
// #endif

abstract contract Market is iMarket {
    struct Entry {
        uint index; // index in the keylist + 1
        Order value;
    }

    struct KeyList {
        address[] keys;
        uint size;
        uint totalQuantity;
        uint totalVolume;
    }

    // Iterable Map pattern with two keylists, one for consumers and one for providers
    struct itmapOrders {
        mapping(address => Entry) orders;
        KeyList providers;
        KeyList consumers;
    }

    // Market global state
    address internal immutable _marketer;

    // Market states
    bool public isOpen = false;
    bool public isCleared = false;
    // Matched data
    uint internal marketPrice;
    uint internal matchedQuantity;
    uint internal matchedVolume;

    // Market positions
    // Mapping that allows you to search for a user with their Ethereum address and retrieve their data.
    itmapOrders internal positions;

    // Events
    event Received(address, uint);
    event MarketOpen();
    event MarketClosed();
    event MarketNewCycle();

    // MODIFIERS
    modifier onlyMarketer() {
        require(
            msg.sender == _marketer,
            "!mkterAddr"
        );
        _;
    }

    modifier onlyMarketOpen() {
        require(isOpen, "mkt !open");
        _;
    }

    modifier onlyMarketClosed() {
        require(!isOpen, "mkt !closed");
        _;
    }

    // PUBLIC
    constructor( address marketer_ ) {
        _marketer = marketer_;
    }

    function open() external onlyMarketer onlyMarketClosed {
        // #if _DEBUG
        //console.log("\t> Market open");
        // #endif

        isOpen = true;
        emit MarketOpen();
    }

    function close() external onlyMarketer onlyMarketOpen {
        // #if _DEBUG
        //console.log("\t> Market closed");
        // #endif

        isOpen = false;
        emit MarketClosed();
    }

    
    // Get the market clearing values
    function getMarketPrice() external view returns (uint) {
        return (marketPrice);
    }

    function getMarketVolume() external view returns (uint) {
        return (matchedVolume);
    }

    function getMarketQuantity() external view returns (uint) {
        return (matchedQuantity);
    }

    // Add a new sell order to the market and update the global market values
    function addSellOrder(Order order_) public payable virtual onlyMarketOpen {
        require(
            order_.getType() == Order.orderType.PROVIDER,
            "malOrd"
        );
        require(order_.owner() == msg.sender, "!owner");
        require(order_.marketAddr() == address(this), "!mktAddr");

        // Checks if the order from the same agent already exists in the market
        bool inMarket_;
        Order oldOrder;
        (inMarket_, oldOrder) = _isInMarket(order_.owner());

        // #if _DEBUG
        /*
        console.log("\t> Adding sell order. Duplicated: %s", inMarket_);
        console.log(
            "\t\tNew sell order: index= %s quantity= %s price= %s",
            uint(order_.getType()),
            order_.originalAmmount(),
            order_.originalPrice()
        );
        */
        // #endif

        if (inMarket_ && (oldOrder.getType() == Order.orderType.CONSUMER)) {
            // The order has chaged the type. Remove it completely
            _removeOrder(order_.owner(), positions.consumers);
        }
        // Add the new order or replace the old one
        _addOrder(order_, positions.providers);
    }

    // Add a new sell order to the market and update the global values
    function addBuyOrder(Order order_) public payable virtual onlyMarketOpen {
        require(
            order_.getType() == Order.orderType.CONSUMER,
            "malOrd"
        );
        require(order_.owner() == msg.sender, "!owner");
        require(order_.marketAddr() == address(this), "!mktAddr");

        // Checks if the order from the same agent already exists in the market
        bool inMarket_;
        Order oldOrder;
        (inMarket_, oldOrder) = _isInMarket(order_.owner());

        // #if _DEBUG
        /*
        console.log("\t> Adding buy order. Duplicated: %s", inMarket_);
        console.log(
            "\t\tNew buy order: type= %s",
            uint(order_.getType())
        );
        console.log(
            "\t\tNew buy order: quantity= %s price= %s",
            order_.originalAmmount(),
            order_.originalPrice()
        );
        */
        // #endif

        if (inMarket_ && (oldOrder.getType() == Order.orderType.PROVIDER)) {
            // The order has chaged the type. Remove it completely
            _removeOrder(order_.owner(), positions.providers);
        }
        // Add the new order or replace the old one
        _addOrder(order_, positions.consumers);
    }

    function getOrder(
        address owner_
    ) public view virtual returns (bool exists_, Order order_) {
        exists_ = positions.orders[owner_].index > 0;
        if (exists_) {
            order_ = positions.orders[owner_].value;
        }
    }

    function clearing() public virtual onlyMarketer onlyMarketClosed {
        require(
            (positions.providers.size > 0) || (positions.consumers.size > 0),
            "mktEmpty"
        );

        // #if _DEBUG
        /*
        console.log("\t> Market clearing");
        */
        // #endif

        _matchOrders();
        _setMarketPrice();
        _offMarketClearing();
        isCleared = true;
        _notify();
    }

    function notifyAgents() public {
        _notify();
    }

    // PROTECTED & PRIVATE

    // Generate the matched positions list and the unmatched positions list (the off-market)
    function _matchOrders() internal virtual;

    // Clear the off-market and set the off-market selling price
    function _offMarketClearing() internal virtual;

    // Calculate the market price
    function _setMarketPrice() internal virtual;

    // Market agents notification
    function _notify() internal virtual;

    // Market log
    function _marketLog() internal virtual returns( uint );
    
    // Iterable Map management functions
    // Return if an agent has current positions in the market
    function _isInMarket(
        address key_
    ) private view returns (bool inMarket_, Order oldOrder_) {
        if (positions.orders[key_].index > 0) {
            inMarket_ = true;
            oldOrder_ = positions.orders[key_].value;
        } else {
            inMarket_ = false;
        }
    }

    function _recycle() internal virtual onlyMarketer {
        // #if _DEBUG
        //console.log("\t> Market reset");
        // #endif

        isOpen = true;
        isCleared = false;
        marketPrice = 0;
        matchedQuantity = 0;
        matchedVolume = 0;

        for( uint i = 0; i < positions.providers.keys.length; i++ ){
            delete positions.orders[positions.providers.keys[i]];
        }
        for( uint i = 0; i < positions.consumers.keys.length; i++ ){
            delete positions.orders[positions.consumers.keys[i]];
        }
        positions.providers.keys = new address[](0);
        positions.providers.size = 0;
        positions.providers.totalQuantity = 0;
        positions.providers.totalVolume = 0;
        positions.consumers.keys = new address[](0);
        positions.consumers.size = 0;
        positions.consumers.totalQuantity = 0;
        positions.consumers.totalVolume = 0;
        emit MarketNewCycle();
    }

    // Insert a new order or update it if already in the market
    function _addOrder(Order order_, KeyList storage kl_) internal {
        Entry storage entry = positions.orders[order_.owner()];
        if (entry.index > 0) {
            // #if _DEBUG
            /*
            console.log("\t\t>> Updating an old order");
            */
            // #endif

            // entry exists. Must be updated
            // update also the market global data
            kl_.totalQuantity -= entry.value.originalAmmount();
            kl_.totalVolume -=
                entry.value.originalAmmount() *
                entry.value.originalPrice();
            // update the order
            entry.value = order_;
        } else {
            // Add a new entry in the keylist at the end
            kl_.keys.push(order_.owner());
            kl_.size++;
            // new entry
            entry.value = order_;
            entry.index = kl_.size;

            // #if _DEBUG
            /*
            console.log("\t\t>> Adding new entry in map");
            */
            // #endif
        }
        // update also the market global data
        kl_.totalQuantity += entry.value.originalAmmount();
        kl_.totalVolume += (entry.value.originalAmmount() *
            entry.value.originalPrice());
    }

    // Remove a order
    function _removeOrder(address key_, KeyList storage kl_) internal {
        // #if _DEBUG
        /*
        console.log("\t\t>> Removing order. Key= %s", key_);
        */
        // #endif


        require(positions.orders[key_].index != 0); // entry not exist
        require(positions.orders[key_].index <= kl_.size); // invalid index value

        // Move the last element of the keylist into the vacated key slot
        uint keyListIndex = positions.orders[key_].index - 1;
        uint keyListLastIndex = kl_.size - 1;
        positions.orders[kl_.keys[keyListLastIndex]].index = keyListIndex + 1;
        kl_.keys[keyListIndex] = kl_.keys[keyListLastIndex];
        kl_.size--;

        delete positions.orders[key_];
    }

    //Function to quicksort keyLists O(nlogn)
    function _sort( KeyList storage kl_, int right_, int left_, bool ascending_ ) internal {
        int i = right_;
        int j = left_;
        
        uint pivotValue = positions.orders[kl_.keys[uint(left_ + ((right_ - left_) / 2))]].value.originalPrice();
        while (i <= j) {
            while ( ascending_
                        ? positions.orders[kl_.keys[uint(i)]].value.originalPrice() < pivotValue
                        : positions.orders[kl_.keys[uint(i)]].value.originalPrice() > pivotValue
            ) i++;
            while ( ascending_
                        ? positions.orders[kl_.keys[uint(j)]].value.originalPrice() > pivotValue
                        : positions.orders[kl_.keys[uint(j)]].value.originalPrice() < pivotValue
            ) j--;
            if (i <= j) {
                (kl_.keys[uint(i)], kl_.keys[uint(j)]) = (kl_.keys[uint(j)], kl_.keys[uint(i)]);
                i++;
                j--;
            }
        }
        if (left_ < j) _sort( kl_, left_, j, ascending_ );
        if (i < right_) _sort( kl_, i, right_, ascending_ );
    }

/*
    function _sortAscending(
        int right,
        int left
    ) internal {
        int i = right;
        int j = left;
        KeyList storage kl = positions.providers;
        uint pivotIdx = uint(left + ((right - left) / 2));
        uint pivotValue = positions.orders[kl.keys[pivotIdx]].value.originalPrice();
        
        while (i <= j) {
            while (
                positions.orders[kl.keys[uint(i)]].value.originalPrice() < pivotValue
            ) i++;
            while (
                positions.orders[kl.keys[uint(j)]].value.originalPrice() > pivotValue
            ) j--;
            if (i <= j) {
                (kl.keys[uint(i)], kl.keys[uint(j)]) = (
                    kl.keys[uint(j)],
                    kl.keys[uint(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) _sortAscending( left, j);
        if (i < right) _sortAscending( i, right);
    }

//Function to quicksort producers in ascending order of price O(nlogn)
    function _sortDescending(
        int right,
        int left
    ) internal {
        int i = right;
        int j = left;
        KeyList storage kl = positions.consumers;
        uint pivotIdx = uint(left + (( right - left ) / 2));
        uint pivotValue = positions.orders[kl.keys[pivotIdx]].value.originalPrice();
        
        while (i <= j) {
            while (
                positions.orders[kl.keys[uint(i)]].value.originalPrice() > pivotValue
            ) i++;
            while (
                positions.orders[kl.keys[uint(j)]].value.originalPrice() < pivotValue
            ) j--;
            if (i <= j) {
                (kl.keys[uint(i)], kl.keys[uint(j)]) = (
                    kl.keys[uint(j)],
                    kl.keys[uint(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) _sortDescending( left, j);
        if (i < right) _sortDescending( i, right);
    }
*/
    function _getLastConsumer() internal view returns (Entry storage e) {
        require(
            positions.consumers.size > 0,
            "!consumers"
        );
        e = positions.orders[
            positions.consumers.keys[positions.consumers.size - 1]
        ];
    }

    function _getLastProvider() internal view returns (Entry storage e) {
        require(
            positions.providers.size > 0,
            "!providers"
        );
        e = positions.orders[
            positions.providers.keys[positions.providers.size - 1]
        ];
    }
}
