from typing import List  
from dataclasses import dataclass
from i_market import Order
from market import Market, Match
import time
import compFlags

@dataclass  
# Best profit algorithm for the matched positions
# Off market cleared using the market selling price
class DoubleAuction_A(Market):
    def __init__(self):
        super().__init__()

    # Calculate the seeling price of a single match as the middle point
    def _calculateMatchedPrice( self, requestPrice, offerPrice ) -> float:
        return (requestPrice + offerPrice)/2
    
    # Market matching order to order
    def _matchOrders(self): 
        # The first step will be to sort request (consumption) from high to low 
        # and offers (production) from low to high  
        self._consumers = sorted(self._consumers, key=lambda x: x.Price)[::-1]
        self._providers = sorted(self._providers, key=lambda x: x.Price)

        while (len(self._consumers) > 0 and len(self._providers) > 0):
            if self._consumers[0].Price >= self._providers[0].Price:
                # Match
                currRequest = self._consumers.pop(0)
                currOffer = self._providers.pop(0)
                
                # Adjust quantities
                if currRequest.Quantity != currOffer.Quantity:
                    if currRequest.Quantity > currOffer.Quantity:
                        newRequest = Order(ID = currRequest.ID, 
                                       Type = currRequest.Type, 
                                       Quantity = currRequest.Quantity - currOffer.Quantity, 
                                       Price = currRequest.Price)
                        self._consumers.insert(0, newRequest)
                        currRequest.Quantity = currOffer.Quantity
                    else:
                        newOffer = Order(ID=currOffer.ID, 
                                         Type = currOffer.Type, 
                                         Quantity = currOffer.Quantity - currRequest.Quantity, 
                                         Price = currOffer.Price)
                        self._providers.insert(0, newOffer)
                        currOffer.Quantity = currRequest.Quantity 
                
                # Register the matched position  
                mp =  self._calculateMatchedPrice(currRequest.Price,currOffer.Price)
                self._matches.append( Match(currRequest, currOffer, mp) )

                # Update market statistics 
                self.expectancy += currRequest.getExpectancy() + currOffer.getExpectancy()
                self.matchedQuantity += currRequest.Quantity
                self.matchedVolume += currRequest.Quantity*mp
            else:
                break    

    # Caculate the market selling price as a weigthed average o the matched positions
    def _setMarketPrice(self):
        if( self.matchedQuantity > 0 ):
            self.marketPrice = float(self.matchedVolume / self.matchedQuantity)

    def getMarketPrice(self) -> float:
        return self.marketPrice
    
    # Unmatched positions
    # The off market positions are cleared at the market selling price
    def _offMarketClearing(self):
        self.offMarketPrice = self.marketPrice

        for i in self._consumers:
            self.unmatchedDemand += i.Quantity
            i.setMatchedPrice( self.offMarketPrice )
            self.offExpectancy += i.getExpectancy()

        for i in self._providers:
            self.unmatchedProduction += i.Quantity
            i.setMatchedPrice( self.offMarketPrice )
            self.offExpectancy += i.getExpectancy()  
    

    def status(self, verbose = False):
        self.initialStatus()

        print( "\nSell Price = " + '{0:.3f}'.format(self.marketPrice) )
        print( "Matched quantity = " + str(self.matchedQuantity) )
        print( "\nOff market Price = " + '{0:.3f}'.format(self.offMarketPrice) )
        print( "Unmatched demand = " + str(self.unmatchedDemand) )
        print( "Unmatched production = " + str(self.unmatchedProduction) )
        print( "\nMarket expectancy = " + '{0:.1f}'.format(self.expectancy) )
        print( "Off-Market expectancy = " + '{0:.1f}'.format(self.offExpectancy) )
        if(verbose):
            print( "______________________________________________________")
            self.matchedStatus()
            self.offMarketStatus()

# -------------------------------------------------------------------------------

@dataclass  
# All market is cleared using the same selling price
# The off-market is handled at marketer prices
class DoubleAuction_B(Market):
    def __init__(self, inPrice: float, outPrice: float):
        super().__init__()
        self._offMarket: List[Order] = []
        self.MarketerInPrice = inPrice
        self.MarketerOutPrice = inPrice
        # For testing only
        self._consumersExpectancy: float = 0.0
        self._producersExpectancy: float = 0.0

    def _calculateMarketExpectancy(self):
        for i in self._consumers:
            i.setMatchedPrice( self.marketPrice )
            self._consumersExpectancy += i.getExpectancy()  
        for i in self._providers:
            i.setMatchedPrice( self.marketPrice )
            self._producersExpectancy += i.getExpectancy()  
        self.expectancy = self._consumersExpectancy + self._producersExpectancy
          
    def _matchOrders(self): 
        # Global balance of the market
        diff = self.globalDemand - self.globalProduction
        cv = self.initialConsumersVol
        pv = self.initialProvidersVol

        t_start_c: float = 0.0
        t_end_c: float = 0.0
        t_start_p: float = 0.0
        t_end_p: float = 0.0
        n_off: int = 0

        if( diff > 0 ):
            # Demand is grater than offer
            # Cheaper consumer orders must be put in the off-market list
            # Sort consumers by price in ascending order
            self._consumers = sorted(self._consumers, key=lambda x: x.Price, reverse=True)

            t_start_c = time.time()
            while (diff > 0):
                ord = self._consumers.pop(len(self._consumers)-1)
                n_off += 1
                if( ord.Quantity <= diff ):
                    self._offMarket.insert(len(self._consumers)-1,ord)
                    cv -= ord.Quantity*ord.Price
                    diff -= ord.Quantity
                else:
                    newOrder = Order(ID = ord.ID, 
                                       Type = ord.Type, 
                                       Quantity = diff, 
                                       Price = ord.Price)
                    self._offMarket.insert(len(self._consumers)-1, newOrder)
                    cv -= newOrder.Quantity*newOrder.Price
                    ord.Quantity -= diff
                    self._consumers.insert(len(self._consumers)-1, ord)
                    break
            t_end_c = time.time()

        elif( diff < 0 ):
            # Offer is grater than demand
            # Cheaper producer orders must be put in the unmatched list
            # Sort providers by price in descending order
            self._providers = sorted(self._providers, key=lambda x: x.Price)

            t_start_p = time.time()
            while (diff < 0):
                ord = self._providers.pop(len(self._providers)-1)
                n_off += 1
                if( ord.Quantity <= -diff ):
                    self._offMarket.insert(len(self._providers)-1,ord)
                    pv -= ord.Quantity*ord.Price
                    diff += ord.Quantity
                else:
                    newOrder = Order(ID = ord.ID, 
                                    Type = ord.Type, 
                                    Quantity = -diff, 
                                    Price = ord.Price)
                    self._offMarket.insert(len(self._providers)-1, newOrder)
                    pv -= newOrder.Quantity*newOrder.Price
                    ord.Quantity += diff
                    self._providers.insert(len(self._providers)-1, ord)
                    break
            t_end_p = time.time()

        '''
        print( "Using off-market list")
        print( ">>> Off-market:" + str(n_off) )
        t:float = (t_end_c - t_start_c)
        print( ">>> Conssumers: " + '{0:.4f}'.format((t)*1000) + " mS" )  
        t = (t_end_p - t_start_p)
        print( ">>> Providers: " + '{0:.4f}'.format((t)*1000) + " mS" )  
        '''

        self.matchedQuantity = min( self.globalDemand, self.globalProduction )
        self.marketPrice = (cv+pv)/(2*self.matchedQuantity)
        self.matchedVolume = self.matchedQuantity*self.marketPrice      
        
        if not compFlags.PROD:
            self._calculateMarketExpectancy()
       

    def _offMarketClearing(self):
        if compFlags.PROD:
            pass
        else:
            for i in self._offMarket:
                if( i.Type ):
                    self.unmatchedProduction += i.Quantity
                    i.setMatchedPrice( self.MarketerInPrice )
                else:
                    self.unmatchedDemand += i.Quantity
                    i.setMatchedPrice( self.MarketerOutPrice )
                self.offExpectancy += i.getExpectancy()


    def matchedStatus(self):
        print( "Matched positions:")
        for i in self._consumers:
            print("\t"+str(i)) 
        for i in self._providers:
            print("\t"+str(i)) 

    def offMarketStatus(self):
        print( "Unmatched positions")
        for i in self._offMarket:
            print("\t"+str(i)) 

    def status(self, verbose = False):
        self.initialStatus() 
        print( "\nSell Price = " + '{0:.3f}'.format(self.marketPrice) )
        print( "Matched quantity = " + str(self.matchedQuantity) )
        print( "\nUnmatched demand = " + str(self.unmatchedDemand) )
        print( "Unmatched production = " + str(self.unmatchedProduction) )
        print( "\nMarket expectancy = " + '{0:.1f}'.format(self.expectancy) )
        print( "\tConsumers expectancy = " + '{0:.1f}'.format(self._consumersExpectancy) )
        print( "\tProducers expectancy = " + '{0:.1f}'.format(self._producersExpectancy) )
        print( "Off-Market expectancy = " + '{0:.1f}'.format(self.offExpectancy) )
        if(verbose):
            print( "______________________________________________________")
            self.matchedStatus()
            self.offMarketStatus()


#=================================================================================================
@dataclass  
# Model B with off-market 
class DoubleAuction_B2(Market):
    def __init__(self, inPrice: float, outPrice: float):
        super().__init__()
        self._offMarket: List[Order] = []
        self.MarketerInPrice = inPrice
        self.MarketerOutPrice = outPrice
        # For testing only
        self._consumersExpectancy: float = 0.0
        self._producersExpectancy: float = 0.0

    def _calculateMarketExpectancy(self):
        for i in self._consumers:
            i.setMatchedPrice( self.marketPrice )
            self._consumersExpectancy += i.getExpectancy()  
        for i in self._providers:
            i.setMatchedPrice( self.marketPrice )
            self._producersExpectancy += i.getExpectancy()  
        self.expectancy = self._consumersExpectancy + self._producersExpectancy
          
    def _matchOrders(self): 
        # Global balance of the market
        diff = self.globalDemand - self.globalProduction
        cv = self.initialConsumersVol
        pv = self.initialProvidersVol

        t_start_c: float = 0.0
        t_end_c: float = 0.0
        t_start_p: float = 0.0
        t_end_p: float = 0.0
        n_off: int = 0

        if( diff > 0 ):
            # Demand is grater than offer
            # Cheaper consumer orders must be put in the off-market list
            # Sort consumers by price in descending order
            self._consumers = sorted(self._consumers, key=lambda x: x.Price)

            t_start_c = time.time()
            while (diff > 0):
                ord = self._consumers[len(self._consumers)-1]
                n_off += 1
                if( ord.Quantity <= diff ):
                    ord.Off_market = True
                    cv -= ord.Quantity*ord.Price
                    diff -= ord.Quantity
                else:
                    newOrder = Order(ID = ord.ID, 
                                       Type = ord.Type, 
                                       Quantity = diff, 
                                       Off_market = True,
                                       Price = ord.Price)
                    self._consumers.insert(len(self._consumers)-1, newOrder)
                    cv -= newOrder.Quantity*newOrder.Price
                    ord.Quantity -= diff
                    break
            t_end_c = time.time()

        elif( diff < 0 ):
            # Offer is grater than demand
            # Cheaper producer orders must be put in the unmatched list
            # Sort providers by price in ascending order
            self._providers = sorted(self._providers, key=lambda x: x.Price)

            t_start_p = time.time()
            while (diff < 0):
                ord = self._providers[len(self._providers)-1] 
                n_off += 1
                if( ord.Quantity <= -diff ):
                    ord.Off_market = True
                    pv -= ord.Quantity*ord.Price
                    diff += ord.Quantity
                else:
                    newOrder = Order(ID = ord.ID, 
                                    Type = ord.Type, 
                                    Quantity = -diff, 
                                    Off_market = True,
                                    Price = ord.Price)
                    self._providers.insert(len(self._consumers)-1, newOrder)
                    pv -= newOrder.Quantity*newOrder.Price
                    ord.Quantity += diff
                    break
            t_end_p = time.time()

        self.matchedQuantity = min( self.globalDemand, self.globalProduction )
        self.marketPrice = (cv+pv)/(2*self.matchedQuantity)
        self.matchedVolume = self.matchedQuantity*self.marketPrice      
        
        if not compFlags.PROD:
            self._calculateMarketExpectancy()
       

    def _offMarketClearing(self):
        if compFlags.PROD:
            pass
        else:
            for i in self._offMarket:
                if(i.Off_market):
                    if( i.Type ):
                        self.unmatchedProduction += i.Quantity
                        i.setMatchedPrice( self.MarketerInPrice )
                    else:
                        self.unmatchedDemand += i.Quantity
                        i.setMatchedPrice( self.MarketerOutPrice )
                    self.offExpectancy += i.getExpectancy()


    def matchedStatus(self):
        print( "Matched positions:")
        for i in self._consumers:
            if not i.Off_market:
                print("\t"+str(i)) 
        for i in self._providers:
            if not i.Off_market:
                print("\t"+str(i)) 


    def offMarketStatus(self):
        print( "Unmatched positions")
        for i in self._consumers:
            if i.Off_market:
                print("\t"+str(i)) 
        for i in self._providers:
            if i.Off_market:
                print("\t"+str(i)) 


    def status(self, verbose = False):
        self.initialStatus() 
        print( "\nSell Price = " + '{0:.3f}'.format(self.marketPrice) )
        print( "Matched quantity = " + str(self.matchedQuantity) )
        print( "\nUnmatched demand = " + str(self.unmatchedDemand) )
        print( "Unmatched production = " + str(self.unmatchedProduction) )
        print( "\nMarket expectancy = " + '{0:.1f}'.format(self.expectancy) )
        print( "\tConsumers expectancy = " + '{0:.1f}'.format(self._consumersExpectancy) )
        print( "\tProducers expectancy = " + '{0:.1f}'.format(self._producersExpectancy) )
        print( "Off-Market expectancy = " + '{0:.1f}'.format(self.offExpectancy) )
        if(verbose):
            print( "______________________________________________________")
            self.matchedStatus()
            self.offMarketStatus()

