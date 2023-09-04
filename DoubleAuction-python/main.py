from market import Order
from doubleAuction import DoubleAuction_A, DoubleAuction_B, DoubleAuction_B2
import csv
import time
import compFlags

def main():
    import sys

    MARKETER_SELLING_PRICE = 100
    MARKETER_BUYING_PRICE = 10
    market_A = DoubleAuction_A()
    market_B = DoubleAuction_B( MARKETER_BUYING_PRICE, MARKETER_SELLING_PRICE )      
    market_B2 = DoubleAuction_B2( MARKETER_BUYING_PRICE, MARKETER_SELLING_PRICE )  

    args = sys.argv[1:]
    if len(args) >= 1:
        testFile = sys.argv[1]
    else:
        testFile = './test-50.csv'
    print( "Test scenario: " + testFile )
    mode = 'Production ' if compFlags.PROD else 'Testing '
    print( 'Mode: ' + mode + "\n" )

    with open( testFile, newline='') as csvfile:
        test = csv.reader(csvfile, delimiter=';')
        header = []
        header = next(test)
        for row in test:
            market_A.addOrder(Order(ID=int(row[0]),
                                    Type=int(row[1]) == 1,
                                    Quantity= float(row[2]),
                                    Price=float(row[3])))
            market_B.addOrder(Order(ID=int(row[0]),
                                   Type=int(row[1]) == 1,
                                    Quantity= float(row[2]),
                                    Price=float(row[3])))
            market_B2.addOrder(Order(ID=int(row[0]),
                                   Type=int(row[1]) == 1,
                                    Quantity= float(row[2]),
                                    Price=float(row[3])))
    csvfile.close()

    t_start_A:float = time.time_ns()
    market_A.clearing()
    t_end_A:float = time.time_ns()

    t_start_B:float = time.time_ns()
    market_B.clearing()
    t_end_B:FloatingPointError = time.time_ns()

    t_start_B2:float = time.time_ns()
    market_B2.clearing()
    t_end_B2:FloatingPointError = time.time_ns()

    print( "=================== DOUBLE AUCTION - A =========================" )
    print( "Time = " + '{0:.4f}'.format(t_end_A - t_start_A) )
    if not compFlags.PROD:
        market_A.status(verbose=True)

    print()
    print( "=================== DOUBLE AUCTION - B =========================" )
    print( "Time = " + '{0:.4f}'.format(t_end_B - t_start_B) )
    if not compFlags.PROD:
        market_B.status(verbose=True)

    print()
    print( "=================== DOUBLE AUCTION - B2 =========================" )
    print( "Time = " + '{0:.4f}'.format(t_end_B2 - t_start_B2) )
    if not compFlags.PROD:
        market_B.status(verbose=True)

if __name__ == "__main__":
    main()


