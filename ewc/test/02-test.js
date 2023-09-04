
const { expect } = require("chai");

const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");


describe("Group 2 - Basic market functionality", function () {

  async function deployMarketFixture() {
    const signers = await ethers.getSigners();
    const DSO = signers[0];
    const marketer = await ethers.deployContract("Marketer", DSO);
    await marketer.waitForDeployment();
    const market = await marketer.getMarket();
    await marketer.openMarket();
    return { marketer, DSO, market, signers };
  }

    it("Test 2.1: Empty market clearing", 
    /**
     * Rrealiza una operación de compensación de un mercado vacío
     * Excepción recibidad: "mktEmpty"
     */
    async function () {
      const { marketer, owner } = await loadFixture(deployMarketFixture);
      await marketer.closeMarket();
      await expect(marketer.marketClearing()).to.be.revertedWith("mktEmpty");
    });

    it("Test 2.2: Market recycling", 
    /**
     * Realiza una compensación de un mercado vacío recibiendo la excepción correspondiente
     * y después provoca un reciclado del mercado (reinicio de una nueva fase de subasta)
     * Intenta abrir el mercado tras el reciclado y debe recibir la excepción "mkt !closed"
     */
    async function () {
      const { marketer, owner } = await loadFixture(deployMarketFixture);
      await marketer.closeMarket();
      await expect(marketer.marketClearing()).to.be.revertedWith("mktEmpty");
      const idx = await marketer.recycleMarket();
      await expect(marketer.openMarket()).to.be.revertedWith('mkt !closed');
    });
});

