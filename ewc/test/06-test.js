const { expect } = require("chai");

const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Group 6 - Basic market clearing", function () {
  async function deployMarketFixture() {
    const signers = await ethers.getSigners();
    const DSO = signers[0];
    const marketer = await ethers.deployContract("Marketer", DSO);
    await marketer.waitForDeployment();
    const market = await marketer.getMarket();
    await marketer.openMarket();
    return { marketer, DSO, market, signers };
  }

  it("Test 6.1: Two orders with over-production", 
  /**
   * Compensación de un mercado con dos órdenes y sobreproducción
   * La cantidad intercambiada viene determinada por la menor de las dos órdenes
   * y el precio de equilibrio se sitúa en este caso en 136 
   */
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    const seller = signers[1];
    const buyer = signers[2];
    const mk_hdl_seller = await ethers.getContractAt("DoubleAuction_B", market, seller);
    const mk_hdl_buyer = await ethers.getContractAt("DoubleAuction_B", market, buyer);

    // Sell order
    const order1 = await ethers.deployContract("SellOrder", [300, 210, market], seller);
    await order1.waitForDeployment();
    await mk_hdl_seller.addSellOrder(order1);

    // Buy order
    const order2 = await ethers.deployContract("BuyOrder", [100, 63, market], buyer);
    await order2.waitForDeployment();
    await mk_hdl_buyer.addBuyOrder(order2);

    // Market close
    const hdlr = await ethers.getContractAt("Marketer", marketer, DSO);
    await hdlr.closeMarket();
    await hdlr.marketClearing();

    expect(await mk_hdl_buyer.getMarketPrice()).to.equal(136);
    expect(await mk_hdl_buyer.getMarketQuantity()).to.equal(100);
    expect(await mk_hdl_buyer.getMarketVolume()).to.equal(13600);
  });

  it("Test 6.2: Two orders with over-demand", 
   /**
   * Compensación de un mercado con dos órdenes y sobredemanda
   * La cantidad intercambiada viene determinada por la menor de las dos órdenes
   * y el precio de equilibrio se sitía en este caso en 136 
   */
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    const seller = signers[1];
    const buyer = signers[2];
    const mk_hdl_seller = await ethers.getContractAt("DoubleAuction_B", market, seller);
    const mk_hdl_buyer = await ethers.getContractAt("DoubleAuction_B", market, buyer);

    // Sell order
    const order1 = await ethers.deployContract("SellOrder", [100, 63, market], seller);
    await order1.waitForDeployment();
    await mk_hdl_seller.addSellOrder(order1);

    // Buy order
    const order2 = await ethers.deployContract("BuyOrder", [300, 210, market], buyer);
    await order2.waitForDeployment();
    await mk_hdl_buyer.addBuyOrder(order2);

    // Market close
    const hdlr = await ethers.getContractAt("Marketer", marketer, DSO);
    await hdlr.closeMarket();
    await hdlr.marketClearing();

    expect(await mk_hdl_buyer.getMarketPrice()).to.equal(136);
    expect(await mk_hdl_buyer.getMarketQuantity()).to.equal(100);
    expect(await mk_hdl_buyer.getMarketVolume()).to.equal(13600);
  }); 
});