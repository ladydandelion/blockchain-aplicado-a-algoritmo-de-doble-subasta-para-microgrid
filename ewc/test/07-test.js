const { expect } = require("chai");

const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Group 7 - Advanced market clearing", function () {
  async function deployMarketFixture() {
    const signers = await ethers.getSigners();
    const DSO = signers[0];
    const marketer = await ethers.deployContract("Marketer", DSO);
    await marketer.waitForDeployment();
    const market = await marketer.getMarket();
    await marketer.openMarket();
    return { marketer, DSO, market, signers };
  }


  it("Test 7.1: Three orders with over-production", 
  /**
   * Compensación de un mercado compuesto por tres órdenes y sobre-producción
   * Over-production. The order1 is splitted in two: 50@210 to the market and 250@10 to the off-market
   * Total volume = 100*63 (order3) + 50*105 (order2) + 50*210 (first split of order1) = 22050
   * Market price = market_volume / (2*market_quantity) = 110
   * Market volume = market_quantity * market_price = 100*110 = 11000
   */
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    const seller1 = signers[1];
    const seller2 = signers[2];
    const buyer = signers[3]; // error con [2]

    const mk_hdl_seller1 = await ethers.getContractAt("DoubleAuction_B", market, seller1);
    const mk_hdl_seller2 = await ethers.getContractAt("DoubleAuction_B", market, seller2);
    const mk_hdl_buyer = await ethers.getContractAt("DoubleAuction_B", market, buyer);

    // Seller1 
    const order1 = await ethers.deployContract("SellOrder", [300, 210, market], seller1);
    await order1.waitForDeployment();
    await mk_hdl_seller1.addSellOrder(order1);

    // Seller2 
    const order2 = await ethers.deployContract("SellOrder", [50, 105, market], seller2);
    await order2.waitForDeployment();
    await mk_hdl_seller2.addSellOrder(order2);

    // Buy order
    const order3 = await ethers.deployContract("BuyOrder", [100, 63, market], buyer);
    await order2.waitForDeployment();
    await mk_hdl_buyer.addBuyOrder(order3);

    // Market close
    await marketer.closeMarket();
    await marketer.marketClearing();
    
    expect(await mk_hdl_buyer.getMarketPrice()).to.equal(110);
    expect(await mk_hdl_buyer.getMarketQuantity()).to.equal(100);
    expect(await mk_hdl_buyer.getMarketVolume()).to.equal(11000);
  });

  it("Test 7.2: Three orders with over-demand", 
  /**
   * Compensación de un mercado compuesto por tres órdenes y sobre-producción
    // Over-production. The order1 is splitted in two: 50@210 to the market and 250@10 to the off-market
    // Total volume = 320*63 (order3) + 300*210 + 20*105 = 85260
    // Market price = market_volume / (2*market_quantity) = 133
    // Market volume = market_quantity * market_price = 320*133 = 42560
   */
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    const buyer1 = signers[1];
    const buyer2 = signers[2];
    const seller = signers[3]; // error con [2]

    const mk_hdl_buyer1 = await ethers.getContractAt("DoubleAuction_B", market, buyer1);
    const mk_hdl_buyer2 = await ethers.getContractAt("DoubleAuction_B", market, buyer2);
    const mk_hdl_seller = await ethers.getContractAt("DoubleAuction_B", market, seller);

    // Seller1 
    const order1 = await ethers.deployContract("BuyOrder", [300, 210, market], buyer1);
    await order1.waitForDeployment();
    await mk_hdl_buyer1.addBuyOrder(order1);

    // Seller2 
    const order2 = await ethers.deployContract("BuyOrder", [50, 105, market], buyer2);
    await order2.waitForDeployment();
    await mk_hdl_buyer2.addBuyOrder(order2);

    // Buy order
    const order3 = await ethers.deployContract("SellOrder", [320, 63, market], seller);
    await order2.waitForDeployment();
    await mk_hdl_seller.addSellOrder(order3);

    // Market close
    await marketer.closeMarket();
    const mktLog = await marketer.marketClearing();

    expect(await mk_hdl_seller.getMarketPrice()).to.equal(133);
    expect(await mk_hdl_seller.getMarketQuantity()).to.equal(320);
    expect(await mk_hdl_seller.getMarketVolume()).to.equal(42560);

  });
  
});