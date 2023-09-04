from dataclasses import dataclass
import compFlags 

@dataclass
class Order(object):   
    ID: int  
    Quantity: float   
    Price: float
    Type: bool = True # True: provider, False: consumer 
    Off_market: bool = False 

    def __post_init__(self):
        self._matchedPrice = 0
        self._expectancy = 0

    def setMatchedPrice( self, v:float ):
        self._matchedPrice = v
        # set also the expectancy of the order
        if self.Type:  
            self._expectancy = self.Quantity*(self._matchedPrice-self.Price)
        else:
            self._expectancy = self.Quantity*(self.Price-self._matchedPrice)

    def getMatchedPrice(self) -> float:
        return self._matchedPrice
    
    def getExpectancy(self) -> float:
        return self._expectancy
    
if not compFlags.PROD:
    def __str__(self) -> str:
        t = "(P)" if self.Type else "(C)"
        off = "(OFF)" if self.Off_market else ""
        return( str(self.ID) 
                + t + off
                + ": Quantity:" + str(self.Quantity) 
                + " (at "+ str(self.Price)
                + ", Matched at " + '{0:.2f}'.format(self._matchedPrice) 
                + ", Expectancy: " + '{0:.2f}'.format(self._expectancy) +")" 
                )


@dataclass  
class iMarket(object):

    # Add an order to the market and update the global values
    def addOrder(self, order: Order):
        pass

    # Clear the market and set the market selling price
    def clearing(self):   
        pass

    # Getter of the market selling price
    def getMarketPrice(self) -> float:
        pass

    # Generate the matched positions list and the unmatched positions list (the off-market)
    def _matchOrders(self): 
        pass

    # Clear the off-market and set the off-market selling price
    def _offMarketClearing(self):
        pass

    # Getter of the off-market selling price
    def getOffMarketPrice(self) -> float:
        pass

    # Status functions   
    def matchedStatus(self):
        pass

    def offMarketStatus(self):
        pass

    def initalStatus(self):
        pass
    
    def status(self, verbose = False):
        pass