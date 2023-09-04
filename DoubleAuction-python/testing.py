import compFlags
from market import Order
from doubleAuction import DoubleAuction_A, DoubleAuction_B, DoubleAuction_B2
import time
import random

def main():

    MARKETER_SELLING_PRICE = 100
    MARKETER_BUYING_PRICE = 0.1
    market_A = DoubleAuction_A()
    market_B = DoubleAuction_B( MARKETER_BUYING_PRICE, MARKETER_SELLING_PRICE )      
    market_B2 = DoubleAuction_B2( MARKETER_BUYING_PRICE, MARKETER_SELLING_PRICE ) 

    NUM_ORDERS: int = 50000
    PROP_CONSUMERS: float = 0.1
    MAX_QUANTITY: float = 100.0
    MIN_QUANTITY: float = 0.1
    MAX_PRICE: float = 80.0
    MIN_PRICE: float = 10.0

    print( "Test scenario: " + "RANDOM" )
    mode = 'Production ' if compFlags.PROD else 'Testing '
    print( 'Mode: ' + mode + "\n" )
    print( "Number of orders: "  + str(NUM_ORDERS))

    for i in range(NUM_ORDERS):
        type:bool = True if( random.random() >= PROP_CONSUMERS ) else False
        quantity: float = random.uniform(MIN_QUANTITY, MAX_QUANTITY)
        price: float = random.uniform(MIN_PRICE, MAX_PRICE)
        market_A.addOrder( Order(ID=i, Type=type, Quantity=quantity, Price=price) )   
        market_B.addOrder( Order(ID=i, Type=type, Quantity=quantity, Price=price) ) 
        market_B2.addOrder( Order(ID=i, Type=type, Quantity=quantity, Price=price) )    

    t_start_A:float = time.time()
    market_A.clearing()
    t_end_A:float = time.time()

    t_start_B:float = time.time()
    market_B.clearing()
    t_end_B:FloatingPointError = time.time()

    t_start_B2:float = time.time()
    market_B2.clearing()
    t_end_B2:FloatingPointError = time.time()

    print()
    print( "Time A = " + '{0:.4f}'.format((t_end_A - t_start_A)*1000) + " mS" )
    print( "Time B = " + '{0:.4f}'.format((t_end_B - t_start_B)*1000) + " mS" )
    print( "Time B2 = " + '{0:.4f}'.format((t_end_B2 - t_start_B2)*1000) + " mS" )

if __name__ == "__main__":
    main()


