const { expect } = require("chai");

const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Group 5 - Duplicated orders", function () {
  async function deployMarketFixture() {
    const signers = await ethers.getSigners();
    const DSO = signers[0];
    const marketer = await ethers.deployContract("Marketer", DSO);
    await marketer.waitForDeployment();
    const market = await marketer.getMarket();
    await marketer.openMarket();
    return { marketer, DSO, market, signers };
  }

  it("Test 5.1: Sent two orders of the same type", 
  /**
   * Colocación en el mercado de dos órdenes de venta por el mismo usuario
   * Debe prevalecer la última
   */
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    const user1 = signers[1];
    const mk_handler = await ethers.getContractAt("DoubleAuction_B", market, user1);

    const order1 = await ethers.deployContract("SellOrder", [150, 35, market], user1);
    await order1.waitForDeployment();
    await mk_handler.addSellOrder(order1);

    const order2 = await ethers.deployContract("SellOrder", [150, 100, market], user1);
    await order2.waitForDeployment();
    await mk_handler.addSellOrder(order2);

  });

  it("Test 5.2: Sent two orders of the different type", 
  /**
   * Colocación en el mercado de una orden de venta y otra de compra por el mismo usuario
   * Debe prevalecer la última
   */
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    const user1 = signers[1];
    const mk_handler = await ethers.getContractAt("DoubleAuction_B", market, user1);

    const order1 = await ethers.deployContract("SellOrder", [150, 35, market], user1);
    await order1.waitForDeployment();
    await mk_handler.addSellOrder(order1);

    const order2 = await ethers.deployContract("BuyOrder", [50, 300, market], user1);
    await order2.waitForDeployment();
    await mk_handler.addBuyOrder(order2);

    var [exits,o] = await mk_handler.getOrder(user1);
    expect(exits).to.equal(true);
  });
});