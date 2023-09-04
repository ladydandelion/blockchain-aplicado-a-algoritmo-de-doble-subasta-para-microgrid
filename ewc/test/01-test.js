/* console.log(
  new Date().toLocaleDateString('en-us',
    { weekday: "long", year: "numeric", month: "short", day: "numeric" })
); */

// This is an example test file. Hardhat will run every *.js file in `test/`,
// so feel free to add new ones.
// Hardhat tests are normally written with Mocha and Chai.
// We import Chai to use its asserting functions here.
const { expect } = require("chai");

// We use `loadFixture` to share common setups (or fixtures) between tests.
// Using this simplifies your tests and makes them run faster, by taking
// advantage of Hardhat Network's snapshot functionality.
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

// `describe` is a Mocha function that allows you to organize your tests.
// Having your tests organized makes debugging them easier. All Mocha
// functions are available in the global scope.
describe("Group 1 - Marketer infraestructure", function () {
  // We define a fixture to reuse the same setup in every test. We use
  // loadFixture to run this setup once, snapshot that state, and reset Hardhat
  // Network to that snapshot in every test.

  /**
   * Despliega la infraestructura de contratos que forman el mercado con una función 
   * reutilizable por el entorno de pruebas.
   * La primera cuenta proporcionada por el entorno de desarrollo es considerada la 
   * cuenta de la coemrcializadora (DSO). Construye un marketer asociado a esa cuenta 
   * y abre el mercado arrancando una fase de subasta
   * @returns el marketer, el mercado de subasta, la cuenta de la comercializadora y
   * el array con todas las cuentas proporcionadas por el entorno de desarrollo
   */
  async function deployMarketFixture() {
    // Get the Signers here.
    const signers = await ethers.getSigners();
    const DSO = signers[0];

    // To deploy our contract, we just have to call ethers.deployContract and await
    // its waitForDeployment() method, which happens once its transaction has been
    // mined.
    const marketer = await ethers.deployContract("Marketer", DSO);
    await marketer.waitForDeployment();
    const market = await marketer.getMarket();

    // Open the market
    await marketer.openMarket();

    // Fixtures can return anything you consider useful for your tests
    return { marketer, DSO, market, signers };
  }

  // `it` is another Mocha function. This is the one you use to define each
  // of your tests. It receives the test name, and a callback function.
  // If the callback function is async, Mocha will `await` it.


  it("Test 1.1: Check market owner", 
    /**
     * Test 1.1: Construye toda la infraestructura del marketer y verifica que
     * el dueño es la cuenta de la comercializadora (DSO)
     */
    async function () {
    // We use loadFixture to setup our environment, and then assert that
    // things went well
      const { marketer, DSO } = await loadFixture(deployMarketFixture);

      // `expect` receives a value and wraps it in an assertion object. These
      // objects have a lot of utility methods to assert values.
      expect(await marketer.owner()).to.equal(DSO.address);
    });

  it("Test 1.2: Reject normal user market handling", 
    /**
     * Rechaza una operación de apertura del mercado realizada por un usuario 
     * distinto de la coemrcializadora
     * Excepción recibida: "!DSO"
     */
    async function () {
      const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
      const user = signers[1];
      const hdler = await ethers.getContractAt("Marketer", marketer, user);
      await expect(hdler.openMarket()).to.be.revertedWith("!DSO");
    });

  it("Test 1.3: Valid Open->Close transit", 
    /**
     * Realiza una transición válida del mercado pasándolo de estado OPEN a
     * CLOSE
     */
    async function () {
      const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
      const hdler = await ethers.getContractAt("Marketer", marketer, DSO);
      await hdler.closeMarket();
      expect(await hdler.isOpen()).to.equal(false);
  });

  it("Test 1.4: Reject invalid Open->Open transit", 
  /**
     * Realiza una transición no válida del mercado pasándolo de estado OPEN a
     * OPEN
     * Excepción recibida: "mkt !closed"
     */
  async function () {
    const { marketer, DSO, market, signers } = await loadFixture(deployMarketFixture);
    const hdler = await ethers.getContractAt("Marketer", marketer, DSO);
    await expect(hdler.openMarket()).to.be.revertedWith('mkt !closed');
  });

}); 