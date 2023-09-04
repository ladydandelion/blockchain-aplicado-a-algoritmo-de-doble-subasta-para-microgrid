const { expect } = require("chai");

const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Group 4 - Market with only one order", function () {

  async function deployMarketFixture() {
    const signers = await ethers.getSigners();
    const DSO = signers[0];
    const marketer = await ethers.deployContract("Marketer", DSO);
    await marketer.waitForDeployment();
    const market = await marketer.getMarket();
    await marketer.openMarket();
    return { marketer, DSO, market, signers };
  }

  it("Test 4.1: Market clearing with one sell order",
  /**
   * Intento de compensación de un mercado con una única orden de venta
   * El precio final del mercado debe ser 0
   */ 
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    user1 = signers[1];
    const order = await ethers.deployContract("SellOrder", [150, 35, market], user1);
    await order.waitForDeployment();

    const mk_handler = await ethers.getContractAt("DoubleAuction_B", market, user1);
    await mk_handler.addSellOrder(order);

    // Market close
    const hdlr = await ethers.getContractAt("Marketer", marketer, DSO);
    await hdlr.closeMarket();
    await hdlr.marketClearing();
    expect(await mk_handler.getMarketPrice()).to.equal(0);
  });

  it("Test 4.2: Market clearing with one buy order", 
   /**
   * Intento de compensación de un mercado con una única orden de compra
   * El precio final del mercado debe ser 0
   */ 
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    user2 = signers[2];
    const order = await ethers.deployContract("BuyOrder", [100, 25, market], user2);
    await order.waitForDeployment();

    const mk_handler = await ethers.getContractAt("DoubleAuction_B", market, user2);
    await mk_handler.addBuyOrder(order);

    // Market close
    const hdlr = await ethers.getContractAt("Marketer", marketer, DSO);
    await hdlr.closeMarket();
    await hdlr.marketClearing();
    expect(await mk_handler.getMarketPrice()).to.equal(0);
  });
});