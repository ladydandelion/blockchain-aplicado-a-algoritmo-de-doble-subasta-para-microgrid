const { expect } = require("chai");

const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Group 8 - Recycling the market", function () {
  async function deployMarketFixture() {
    const signers = await ethers.getSigners();
    const DSO = signers[0];
    const marketer = await ethers.deployContract("Marketer", DSO);
    await marketer.waitForDeployment();
    const market = await marketer.getMarket();
    await marketer.openMarket();
    return { marketer, DSO, market, signers };
  }


  it("Test 8.1: Three orders in two cycles", 
  /**
   * Compensación de dos ciclos de mercado consecutivos. 
   * En el primer ciclo se colocan dos órdenes de venta y una de compra y en el
   * segundo ciclo se colocan dos órdenes de venta y una de compra
   */
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    const seller1 = signers[1];
    const seller2 = signers[2];
    const seller3 = signers[3];
    
    const buyer1 = signers[4];
    const buyer2 = signers[5];
    const buyer3 = signers[6]; 

    const mk_hdl_seller1 = await ethers.getContractAt("DoubleAuction_B", market, seller1);
    const mk_hdl_seller2 = await ethers.getContractAt("DoubleAuction_B", market, seller2);
    const mk_hdl_buyer = await ethers.getContractAt("DoubleAuction_B", market, buyer1);

    // Seller1 
    order1 = await ethers.deployContract("SellOrder", [300, 210, market], seller1);
    await order1.waitForDeployment();
    await mk_hdl_seller1.addSellOrder(order1);

    // Seller2 
    order2 = await ethers.deployContract("SellOrder", [50, 105, market], seller2);
    await order2.waitForDeployment();
    await mk_hdl_seller2.addSellOrder(order2);

    // Buy order
    order3 = await ethers.deployContract("BuyOrder", [100, 63, market], buyer1);
    await order2.waitForDeployment();
    await mk_hdl_buyer.addBuyOrder(order3);

    // Market close
    await marketer.closeMarket();
    await marketer.marketClearing();
 
    // Market recycle
    const index1 = await marketer.recycleMarket();

    const mk_hdl_buyer1 = await ethers.getContractAt("DoubleAuction_B", market, buyer1);
    const mk_hdl_buyer2 = await ethers.getContractAt("DoubleAuction_B", market, buyer2);
    const mk_hdl_seller = await ethers.getContractAt("DoubleAuction_B", market, seller3);

    // Seller1 
    order1 = await ethers.deployContract("BuyOrder", [300, 210, market], buyer1);
    await order1.waitForDeployment();
    await mk_hdl_buyer1.addBuyOrder(order1);

    // Seller2 
    order2 = await ethers.deployContract("BuyOrder", [50, 105, market], buyer2);
    await order2.waitForDeployment();
    await mk_hdl_buyer2.addBuyOrder(order2);

    // Buy order
    order3 = await ethers.deployContract("SellOrder", [320, 63, market], seller3);
    await order2.waitForDeployment();
    await mk_hdl_seller.addSellOrder(order3);

    // Market close
    await marketer.closeMarket();
    const mktLog = await marketer.marketClearing();

    // Market recycle
    const index2 = await marketer.recycleMarket();
  });
  
});