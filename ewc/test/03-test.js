const { expect } = require("chai");

const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Group 3 - Orders creation and handling", function () {

  async function deployMarketFixture() {
    const signers = await ethers.getSigners();
    const DSO = signers[0];
    const marketer = await ethers.deployContract("Marketer", DSO);
    await marketer.waitForDeployment();
    const market = await marketer.getMarket();
    await marketer.openMarket();
    return { marketer, DSO, market, signers };
  }

  it("Test 3.1: Order creation", 
  /**
   * Creación de una orden de venta y verificación de su propietario, del precio
   * y de la cantidad
   */
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    user1 = signers[1];
    const order = await ethers.deployContract("SellOrder", [150, 35, market], user1);
    await order.waitForDeployment();
    expect(await order.owner()).to.equal(user1.address);
    expect(await order.originalAmmount()).to.equal(150);
    expect(await order.originalPrice()).to.equal(35);
  });

  it("Test 3.2: Adding a sell order by the owner", 
  /**
   * Creación de una orden de compra y colocación en el mercado de doble subasta
   * Se verifica que la orden está aceptada por el mercado
   */
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    user1 = signers[1];
    const order = await ethers.deployContract("SellOrder", [150, 35, market], user1);
    await order.waitForDeployment();
    const mk_handler = await ethers.getContractAt("DoubleAuction_B", market, user1);
    await mk_handler.addSellOrder(order);
    var [exits, o] = await mk_handler.getOrder(user1);
    expect(exits).to.equal(true);
  });

  it("Test 3.3: Rejecting a malformed order", 
  /**
   * Creación de una orden de compra y colocación en el mercado como orden de venta
   * Excepción recibida: "malOrd"
   */
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    user1 = signers[1];
    const order = await ethers.deployContract("BuyOrder", [150, 35, market], user1);
    await order.waitForDeployment();
    const mk_handler = await ethers.getContractAt("DoubleAuction_B", market, user1);
    await expect(mk_handler.addSellOrder(order)).to.be.revertedWith("malOrd");
  });

  it("Test 3.4: Rejecting a order added to the market by another user", 
  /**
   * Creación de una orden y colocación en el mercado por un usuario distinto del dueño
   * Excepción recibida: "!owner"
   */
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    user1 = signers[1];
    user2 = signers[2];
    const order = await ethers.deployContract("SellOrder", [150, 35, market], user1);
    await order.waitForDeployment();

    const mk_handler = await ethers.getContractAt("DoubleAuction_B", market, user2);
    await expect(mk_handler.addSellOrder(order)).to.be.revertedWith("!owner");
  });

  it("Test 3.5: Rejecting an order added to the market by a non member user", 
  /**
   * Rechazo de la colocación de una orden en el mercado por un usuario que no pertenece al 
   * micro-grid
   * Excepción recibida: "!member"
   */
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    user9 = signers[9];
    const order = await ethers.deployContract("SellOrder", [150, 35, market], user9);
    await order.waitForDeployment();

    const mk_handler = await ethers.getContractAt("DoubleAuction_B", market, user9);
    mk_handler.addSellOrder(order);

    await expect(mk_handler.addSellOrder(order)).to.be.revertedWith("!member");
  });

});