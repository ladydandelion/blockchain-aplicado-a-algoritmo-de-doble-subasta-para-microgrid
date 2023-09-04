// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;
//import "./Addresses.sol";
import "./Market.sol";
import "./GridDirectory.sol";
import "./ClosureFactory.sol";

// #if _DEBUG
import "hardhat/console.sol";
// #endif

contract DoubleAuction_B is Market {
    // Marketer prices
    uint internal immutable maxPrice; // marketer Supplied Price
    uint internal immutable minPrice; // marketer Absorbed Price
    GridDirectory internal immutable _directory;
    ClosureFactory internal immutable _factory;

    // Off-market positions
    struct OffMarket {
        KeyList kl;
        uint unmatchedDemand;
        uint unmatchedProduction;
    }
    OffMarket private offMarket;

    // EVENTS
    event MarketCleared(uint price, uint ammount, uint volume);
    event OrderCleared(address owner);

    // MODIFIERS
    modifier onlyMember(address addr_) {
        require(_directory.isMember(addr_), "!member");
        _;
    }

    //PUBLIC
    constructor(
        uint marketerSuppliedPrice_,
        uint marketerAbsorbedPrice_,
        GridDirectory directory_,
        ClosureFactory factory_
    ) Market( msg.sender) {
        maxPrice = marketerSuppliedPrice_;
        minPrice = marketerAbsorbedPrice_;
        _directory = directory_;
        _factory = factory_;

        // #if _DEBUG
        //console.log("\t> Double auction B market creation");
        //_marketDump();
        // #endif
    }

    // PUBLIC
    // Add a new sell order to the market and update the global values
    function addSellOrder(
        Order order_
    ) public payable override onlyMarketOpen onlyMember(msg.sender) {
        require(
            order_.originalPrice() > minPrice &&
                order_.originalPrice() < maxPrice,
            "invPrice"
        );
        // #if _DEBUG
        //console.log("\t> Adding sell order" );
        // #endif
        super.addSellOrder(order_);
    }

    // Add a new sell order to the market and update the global values
    function addBuyOrder(
        Order order_
    ) public payable override onlyMarketOpen onlyMember(msg.sender) {
        require(
            order_.originalPrice() > minPrice &&
                order_.originalPrice() < maxPrice,
            "invPrice"
        );

        // #if _DEBUG
        //console.log("\t> Adding buy order" );
        // #endif

        super.addBuyOrder(order_);
    }

    function recycle() public override returns (uint mktLogIdx){
        // #if _DEBUG
        //console.log("\t> DAB_reset" );
        // #endif

        // Store the previous market state
        mktLogIdx = _marketLog();

        // reset the market
        offMarket.unmatchedDemand = 0;
        offMarket.unmatchedProduction = 0;
        offMarket.kl.size = 0;
        super._recycle();
    }

    // #if _DEBUG
    /*
    function clearing() public override {
        super.clearing();
        console.log( "\n\t> Final market state:");
        _marketDump();
        _offMarketDump();
    }
    */
    // #endif

    function _marketLog() internal override returns( uint cls ) {
        cls =  _factory.createMarketClosure(
                                marketPrice,
                                matchedQuantity,
                                matchedVolume,
                                positions.providers.keys.length,
                                positions.providers.keys,
                                positions.providers.keys.length,
                                positions.consumers.keys); 
        // #if _DEBUG
        //console.log("\t>IDX= %s", cls);
        // #endif
    }

    

    function _notify() internal override {
        // #if _DEBUG
        /*
        console.log("\t\t> Market agents notification");
        */
        // #endif

        for (uint i = 0; i < positions.providers.keys.length; i++) {
            address addr = positions.providers.keys[i];
            if (!positions.orders[addr].value.inOffMarket()) {
                positions.orders[addr].value.setPrice(marketPrice);
                emit OrderCleared(addr);
                positions.orders[addr].value.setUsed();
            }
        }
        for (uint i = 0; i < positions.consumers.keys.length; i++) {
            address addr = positions.consumers.keys[i];
            if (!positions.orders[addr].value.inOffMarket()) {
                positions.orders[addr].value.setPrice(marketPrice);
                emit OrderCleared(addr);
                positions.orders[addr].value.setUsed();
            }
        }

        // #if _DEBUG
        /*
        console.log("\t\t> OFF-Market agents notification");
        */
        // #endif

        for (uint i = 0; i < positions.providers.keys.length; i++) {
            address addr = positions.providers.keys[i];
            if (positions.orders[addr].value.inOffMarket()) {
                if (positions.orders[addr].value.marketAmmount() > 0) {
                    positions.orders[addr].value.setPrice(marketPrice);
                }
                positions.orders[addr].value.setUsed();
                emit OrderCleared(addr);
            }
        }
        for (uint i = 0; i < positions.consumers.keys.length; i++) {
            address addr = positions.consumers.keys[i];
            if (positions.orders[addr].value.inOffMarket()) {
                if (positions.orders[addr].value.marketAmmount() > 0) {
                    positions.orders[addr].value.setPrice(marketPrice);
                }
                positions.orders[addr].value.setUsed();
                emit OrderCleared(addr);
            }
        }
    }

    // PROTECTED
    function _addOffMarket(Entry storage entry_) internal {
        entry_.value.setInOffMarket(true);
        offMarket.kl.keys.push(entry_.value.owner());
        offMarket.kl.size++;
        if (entry_.value.getType() == Order.orderType.CONSUMER) {
            offMarket.unmatchedDemand += (entry_.value.originalAmmount() -
                entry_.value.marketAmmount());
        } else {
            offMarket.unmatchedProduction += (entry_.value.originalAmmount() -
                entry_.value.marketAmmount());
        }

        // #if _DEBUG
        /*
        console.log( "\t\tOrder added to off market. Type= %s",
                        (uint(entry_.value.getType())==1)?'P':'C');
        */
        /*
        console.log( "\t\t\t unmatched demand= %s unmatched prodction=%s",
                        offMarket.unmatchedDemand,
                        offMarket.unmatchedProduction );
        */
        // #endif
    }

    function _matchOrders() internal override {
        // Calculate global energy exchage balance of the market
        if (
            positions.consumers.totalQuantity ==
            positions.providers.totalQuantity
        ) {
            // Balanced market.
            // #if _DEBUG
            /*
            console.log(
                "\t> Matching phase: Balanced market. No action needed"
            );
            */
            // #endif
            return;
        }

        // #if _DEBUG
        /*
        console.log("\n\t>> Matching phase:");
        */
        // #endif

        if (
            positions.consumers.totalQuantity >
            positions.providers.totalQuantity
        ) {
            // Over-demand
            uint diff = positions.consumers.totalQuantity -
                positions.providers.totalQuantity;

            // #if _DEBUG
            /*
            console.log("\t>>> Over-demand of %s", diff);
            */
            // #endif

            // Cheaper consumer orders must be put in the off-market list
            // Sort consumers by price in descending order
            _sort(positions.consumers, 0, int(positions.consumers.size-1), false );

            while (diff > 0) {
                Entry storage entry = _getLastConsumer(); // pointer to the last order
                if (entry.value.originalAmmount() <= diff) {
                    // The order is added to the OFF-market in full
                    _addOffMarket(entry);
                    // Supress the entry in the consumer KeyList (is the last one)
                    positions.consumers.size--;
                    // Updates the global volumes
                    positions.consumers.totalVolume -=
                        entry.value.originalAmmount() *
                        entry.value.originalPrice();
                    diff -= entry.value.originalAmmount();
                } else {
                    // Creates a new Order splitting de original in two slices
                    entry.value.setAmmount(
                        entry.value.originalAmmount() - diff
                    );
                    _addOffMarket(entry);
                    positions.consumers.totalVolume -=
                        diff *
                        entry.value.originalPrice();

                    // #if _DEBUG
                    /*
                    console.log("\t\tSplitting diff= %s", diff);
                    _ordDump(entry.value);
                    console.log(
                        "\t\tConsumers Volume= %s ",
                        positions.consumers.totalVolume
                    );
                    */
                    // #endif

                    break;
                }
            }
        } else {
            // Over-production
            uint diff = positions.providers.totalQuantity -
                positions.consumers.totalQuantity;

            // #if _DEBUG
            /*
            console.log("\t>>> Over-production of %s", diff);
            */
            // #endif

            // Most expensive producer orders must be put in the unmatched list
            // Sort providers by price in ascending order
            _sort(positions.providers, 0, int(positions.providers.size-1), true);

            while (diff > 0) {
                Entry storage entry = _getLastProvider(); // pointer to the last order
                if (entry.value.originalAmmount() <= diff) {
                    // The order is added to the OFF-market in full
                    _addOffMarket(entry);
                    // Supress the entry in the consumer KeyList (is the last one)
                    positions.providers.size--;
                    // Updates the global volumes
                    positions.providers.totalVolume -=
                        entry.value.originalAmmount() *
                        entry.value.originalPrice();

                    // #if _DEBUG
                    /*
                    console.log( "Adding full order to off-market");
                    _ordDump( entry.value );
                    */
                    // #endif

                    diff -= entry.value.originalAmmount();
                } else {
                    // Creates a new Order splitting de original in two slices
                    entry.value.setAmmount(
                        entry.value.originalAmmount() - diff
                    );
                    _addOffMarket(entry);
                    positions.providers.totalVolume -=
                        diff *
                        entry.value.originalPrice();

                    // #if _DEBUG
                    /*
                    console.log("\t\tSplitting diff= %s", diff);
                    _ordDump(entry.value);
                    console.log(
                        "\t\tProviders Volume= %s ",
                        positions.providers.totalVolume
                    );
                    */
                    // #endif

                    break;
                }
            }
        }
    }

    // Clear the off-market and set the off-market selling price
    function _offMarketClearing() internal pure override {
        // #if _DEBUG
        /*
        console.log("\n\t>> Off-market clearing phase:");
        */
        // #endif
    }

    function _setMarketPrice() internal override {
        // #if _DEBUG
        /*
        console.log("\n\t>> Price phase:");
        */
        // #endif

        matchedQuantity = (positions.consumers.totalQuantity <
            positions.providers.totalQuantity)
            ? positions.consumers.totalQuantity
            : positions.providers.totalQuantity;
        if (matchedQuantity > 0) {
            marketPrice =
                (positions.consumers.totalVolume +
                    positions.providers.totalVolume) /
                (2 * matchedQuantity);
            matchedVolume = matchedQuantity * marketPrice;
        } else {
            // Correct decision?
            marketPrice = 0;
            matchedVolume = 0;
        }

        emit MarketCleared(marketPrice, matchedQuantity, matchedVolume);

        // #if _DEBUG
        /*
        console.log(
            "\t>>> Market cleared. Price= %s",
            marketPrice
        );
        console.log(
            "\t\t>>> quantity= %s, volume= %s",
            matchedQuantity,
            matchedVolume
        );
        */
        // #endif
    }

    // #if _DEBUG
    // Dump functions
    /*
    function _ordDump(Order order_) internal view {
        console.log(
            "\t\t\tOwner= %s type= %s",
            order_.owner(),
            (uint(order_.getType()) == 0) ? "C" : "P"
        );
        console.log(
            "\t\t\tOriginal (quantity= %s, price= %s)",
            order_.originalAmmount(),
            order_.originalPrice()
        );
        console.log(
            "\t\t\tMarket (quantity= %s, price= %s)",
            order_.marketAmmount(),
            order_.marketPrice()
        );
        console.log("\t\t\tIn Off market= %s", order_.inOffMarket());
    }

    function _ordersDump() internal view {
        console.log("\t> Market Orders:");
        console.log("\t  Number of sell orders = %s", positions.providers.size);
        for (uint i = 0; i < positions.providers.size; i++) {
            address addr = positions.providers.keys[i];
            console.log(
                "\t\tOrder %s: index= %s",
                i + 1,
                positions.orders[addr].index
            );
            _ordDump(positions.orders[addr].value);
        }
        console.log("\t  Number of buy orders = %s", positions.consumers.size);
        for (uint i = 0; i < positions.consumers.size; i++) {
            address addr = positions.consumers.keys[i];
            console.log(
                "\t\tOrder %s: index= %s",
                i + 1,
                positions.orders[addr].index
            );
            _ordDump(positions.orders[addr].value);
        }
        console.log(
            "\t  Market volume: Providers= %s, Consumers= %s",
            positions.providers.totalVolume,
            positions.consumers.totalVolume
        );
        console.log("\t  -----");
    }

    function _marketDump() internal view {
        console.log("\t>> Market state");
        console.log("\t\t MAX price= %s, MIN price= %s ", maxPrice, minPrice);
        console.log("\t\t open= %s, cleared= %s ", isOpen, isCleared);
        _ordersDump();
    }

    function _offMarketDump() internal view {
        console.log("\t> Off market state:");
        console.log(
            "\t  Unmatched demand = %s, unmatched production = %s",
            offMarket.unmatchedDemand,
            offMarket.unmatchedProduction
        );
        console.log("\t  Number of orders = %s", offMarket.kl.size);
        for (uint i = 0; i < offMarket.kl.size; i++) {
            address addr = offMarket.kl.keys[i];
            console.log("\t\tOrder %s", i + 1);
            _ordDump(positions.orders[addr].value);
        }
    }
    */
    // #endif
}
