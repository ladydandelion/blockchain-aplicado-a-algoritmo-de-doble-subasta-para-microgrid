from typing import List  
from dataclasses import dataclass
from i_market import Order, iMarket

@dataclass  
class Match(object):   
    Consumer: Order   
    Producer: Order 
    MatchedPrice: float

    def __post_init__(self):
        self.Consumer.setMatchedPrice(self.MatchedPrice)
        self.Producer.setMatchedPrice(self.MatchedPrice)

    def __str__(self):
        return("Quantity:" + str(self.Consumer.Quantity) 
               + " (at "+ str(self.MatchedPrice) + ")" 
               + " Consumer: " + str(self.Consumer.ID) 
               + " (at " + str(self.Consumer.Price) + " / " + str(self.Consumer.getExpectancy()) + ") " 
               + "<-> Producer: " + str(self.Producer.ID) 
               + " (at " + str(self.Producer.Price) + " / " + str(self.Producer.getExpectancy())  + ") "
               )

@dataclass  
class Market(iMarket):

    def __init__(self):
        # Working lists
        self._consumers: List[Order] = []
        self._providers: List[Order] = []
        self._matches: List[Match] = []
        # Number of positions
        self.numProviders: int = 0
        self.numConsumers: int = 0
        # Global quantities
        self.globalDemand: float = 0.0
        self.globalProduction: float = 0.0
        # Global initial volumes
        self.initialConsumersVol: float = 0.0
        self.initialProvidersVol: float = 0.0
        # Matched data
        self.marketPrice: float = 0.0
        self.matchedQuantity: float = 0.0 
        self.matchedVolume: float = 0.0     #marketPrice * matchedQuantity
        # Off-market data
        self.offMarketPrice: float = 0.0
        self.unmatchedDemand:float = 0.0
        self.unmatchedProduction:float = 0.0
        # Market expectancy
        self.expectancy: float = 0.0
        self.offExpectancy: float = 0.0

    # Add an order to the market and update the global values
    # Update:
    #   self._providers
    #   self._consumers
    #   self.initialProvidersVol
    #   self.initialConsumersVol
    #   self.globalProduction
    #   self.globalDemand
    #   self.numProviders
    #   self.numConsumers
    def addOrder(self, order: Order):
        if order.Type:
            # Provider
            self._providers.append(order)
            self.initialProvidersVol += order.Price*order.Quantity
            self.globalProduction += order.Quantity
            self.numProviders += 1
        else:
            self._consumers.append(order)
            self.initialConsumersVol += order.Price*order.Quantity
            self.globalDemand += order.Quantity
            self.numConsumers += 1
    
    # Generate the matched position list and the unmatched position list (off-market)
    # Calculate:
    #   self.matchedQuantity
    #   self.matchedVolume
    #   self.expectancy
    def _matchOrders(self): 
        pass

    # Getter of the market selling price
    def getMarketPrice(self) -> float:
        return self.marketPrice

    # Set de market selling price derived from the matched positions
    # Calculate:
    #   self.marketPrice
    def _setMarketPrice(self):
        pass


    # Clear de off-market
    # Calculate:
    #   self.offMarketPrice
    #   self.unmatchedDemand
    #   self.unmatchedProduction
    #   self.offExpectancy
    def _offMarketClearing(self):
        pass


    # Clearing of the market(s) and setting the market selling price
    def clearing(self):   
        self._matchOrders()
        self._setMarketPrice()
        self._offMarketClearing()


    # Print functions   
    def matchedStatus(self):
        print( "Matched positions:")
        for i in self._matches:
            print(str(i))
        print()


    def offMarketStatus(self):
        print( "Unmatched positions")
        print( "Consumers:")
        for i in self._consumers:
            print("\t"+str(i))
        print( "Providers:")
        for i in self._providers:
            print("\t"+str(i))      


    def initialStatus(self):
        print( "Number of Consumers = " + str(self.numConsumers))
        print( "Number of Providers = " + str(self.numProviders))
        print( "Global demand = " + str(self.globalDemand))
        print( "Global production = " + str(self.globalProduction))  
        print( "Initial consumer Volume = " + str(self.initialConsumersVol))
        print( "Initial providers Volume = " + str(self.initialProvidersVol))

    def status(self, verbose = False):
        pass
# end testing