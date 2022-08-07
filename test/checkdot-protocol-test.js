const truffleAssert = require('truffle-assertions');
const contractTruffle = require('truffle-contract');
const { toWei, toBN, fromWei } = web3.utils;
const timeHelper = require('./utils/index');

/* Proxies */
const UpgradableCheckDotPoolFactoryContract = contractTruffle(
  require('../build/contracts/UpgradableCheckDotPoolFactory.json'));
UpgradableCheckDotPoolFactoryContract.setProvider(web3.currentProvider);

const UpgradableCheckDotInsuranceProtocolContract = contractTruffle(
  require('../build/contracts/UpgradableCheckDotInsuranceProtocol.json'));
UpgradableCheckDotInsuranceProtocolContract.setProvider(web3.currentProvider);

const UpgradableCheckDotInsuranceStoreContract = contractTruffle(
  require('../build/contracts/UpgradableCheckDotInsuranceStore.json'));
UpgradableCheckDotInsuranceStoreContract.setProvider(web3.currentProvider);

const UpgradableCheckDotERC721InsuranceTokenContract = contractTruffle(
  require('../build/contracts/UpgradableCheckDotERC721InsuranceToken.json'));
UpgradableCheckDotERC721InsuranceTokenContract.setProvider(web3.currentProvider);

/* Contract Artifacts */
const IERC20 = artifacts.require('IERC20');
const CheckDotPoolFactory = artifacts.require('CheckDotPoolFactory');
const CheckDotPool = artifacts.require('CheckDotPool');
const CheckDotInsuranceProtocol = artifacts.require('CheckDotInsuranceProtocol');
const CheckDotInsuranceStore = artifacts.require('CheckDotInsuranceStore');
const CheckDotERC721InsuranceToken = artifacts.require('CheckDotERC721InsuranceToken');


contract('CheckDotInsurance', async (accounts) => {
  let usdtTokenAddress;
  let governanceTokenAddress;

  let basePoolFactory;
  let baseInsuranceProtocol;
  let baseInsuranceStore;
  let baseInsuranceToken;

  let insurancePoolFactory;
  let insuranceProtocol;
  let insuranceStore;
  let insuranceToken;

  let proxyPoolFactory;
  let proxyInsuranceProtocol;
  let proxyInsuranceStore;
  let proxyInsuranceToken;
  
  let owner;
  let tester;

  let snapShotId; // test blockchain snapshot

  before(async () => {
    snapShotId = await timeHelper.takeSnapshot();

    // usdt fake token address
    console.log("--------------------------------------------------------------------------");
    usdtTokenAddress = "0xf02A9d12267581a7b111F2412e1C711545DE217b";
    console.log("usdtTokenAddress       address:", usdtTokenAddress);

    // governance address
    console.log("--------------------------------------------------------------------------");
    governanceTokenAddress = "0x79deC2de93f9B16DD12Bc6277b33b0c81f4D74C7";
    console.log("governanceTokenAddress address:", governanceTokenAddress);

    // accounts
    console.log("--------------------------------------------------------------------------");
    owner = accounts[0];
    console.log('Owner                  address:', owner);
    tester = accounts[1]
    console.log('Tester                 address:', tester);

    // Contracts
    console.log("--------------------------------------------------------------------------");
    basePoolFactory = await CheckDotPoolFactory.new({ from: owner });
    baseInsuranceProtocol = await CheckDotInsuranceProtocol.new({ from: owner });
    baseInsuranceStore = await CheckDotInsuranceStore.new({ from: owner });
    baseInsuranceToken = await CheckDotERC721InsuranceToken.new({ from: owner });
    console.log('basePoolFactory        address:', basePoolFactory.address);
    console.log('baseInsuranceProtocol  address:', baseInsuranceProtocol.address);
    console.log('baseInsuranceStore     address:', baseInsuranceStore.address);
    console.log('baseInsuranceToken     address:', baseInsuranceToken.address);

    // Proxies
    console.log("--------------------------------------------------------------------------");
    proxyPoolFactory = await UpgradableCheckDotPoolFactoryContract.new(governanceTokenAddress, { from: owner });
    proxyInsuranceProtocol = await UpgradableCheckDotInsuranceProtocolContract.new(governanceTokenAddress, { from: owner });
    proxyInsuranceStore = await UpgradableCheckDotInsuranceStoreContract.new(governanceTokenAddress, { from: owner });
    proxyInsuranceToken = await UpgradableCheckDotERC721InsuranceTokenContract.new(governanceTokenAddress, { from: owner });
    console.log('proxyPoolFactory       address:', proxyPoolFactory.address);
    console.log('proxyInsuranceProtocol address:', proxyInsuranceProtocol.address);
    console.log('proxyInsuranceStore    address:', proxyInsuranceStore.address);
    console.log('proxyInsuranceToken    address:', proxyInsuranceToken.address);
    console.log("--------------------------------------------------------------------------");
  });

  after(async () => {
    await timeHelper.revertToSnapShot(snapShotId);
  });

  let setProxyImplementation = async (functionalContract, proxy) => {
    
    const currentBlockTimeStamp = ((await web3.eth.getBlock("latest")).timestamp) + 1000;
    const startUTC = `${currentBlockTimeStamp.toFixed(0)}`;
    const endUTC = `${(currentBlockTimeStamp + 86400).toFixed(0)}`;

    await proxy.upgrade(functionalContract.address, startUTC, endUTC, { from: owner });

    const lastUpgrade = await proxy.getLastUpgrade({ from: owner });

    assert.equal(lastUpgrade.submitedNewFunctionalAddress, functionalContract.address, `submitedNewFunctionalAddress should be equals to ${functionalContract.address}`);
    assert.equal(lastUpgrade.utcStartVote, startUTC, `utcStartVote should be equals to ${startUTC}`);
    assert.equal(lastUpgrade.utcEndVote, endUTC, `utcEndVote should be equals to ${endUTC}`);
    assert.equal(lastUpgrade.totalApproved, 0, `totalApproved should be equals to 0`);
    assert.equal(lastUpgrade.totalUnapproved, 0, `totalUnapproved should be equals to 0`);
    assert.equal(lastUpgrade.isFinished, false, `isFinished should be equals to false`);

    await timeHelper.advanceTime(3600); // add one hour
    await timeHelper.advanceBlock(); // add one block
    
    await proxy.voteUpgrade(true, { from: owner });
    await proxy.voteUpgrade(true, { from: tester });

    await timeHelper.advanceTime(86400); // add one day
    await timeHelper.advanceBlock(); // add one block

    await proxy.voteUpgradeCounting({ from: owner });
    
    const implementation = await proxy.getImplementation();

    assert.equal(implementation, functionalContract.address, `Should be equals to ${functionalContract.address}`);

    return true;
  }

  let addKeyAndValueToStoreAndVerify = async (testKey, testValue) => {
    const currentBlockTimeStamp = ((await web3.eth.getBlock("latest")).timestamp) + 1000;
    const startUTC = `${currentBlockTimeStamp.toFixed(0)}`;
    const endUTC = `${(currentBlockTimeStamp + 86400).toFixed(0)}`;

    await insuranceStore.updateAddress(testKey, testValue, startUTC, endUTC, { from: owner });

    const lastUpdate = await insuranceStore.getLastUpdate({ from: owner });

    assert.equal(lastUpdate.key, testKey, `indexAddress should be equals to ${testKey}`);
    assert.equal(lastUpdate.value, testValue, `indexAddress should be equals to ${testValue}`);
    assert.equal(lastUpdate.utcStartVote, startUTC, `utcStartVote should be equals to ${startUTC}`);
    assert.equal(lastUpdate.utcEndVote, endUTC, `utcEndVote should be equals to ${endUTC}`);
    assert.equal(lastUpdate.totalApproved, 0, `totalApproved should be equals to 0`);
    assert.equal(lastUpdate.totalUnapproved, 0, `totalUnapproved should be equals to 0`);
    assert.equal(lastUpdate.isFinished, false, `isFinished should be equals to false`);

    await timeHelper.advanceTime(3600); // add one hour
    await timeHelper.advanceBlock(); // add one block
    
    await insuranceStore.voteUpdate(true, { from: owner });
    await insuranceStore.voteUpdate(true, { from: tester });

    await timeHelper.advanceTime(86400); // add one day
    await timeHelper.advanceBlock(); // add one block

    await insuranceStore.voteUpdateCounting({ from: owner });
    
    const ninjaValue = await insuranceStore.getAddress(testKey);

    assert.equal(ninjaValue, testValue, `Should be equals to ${testValue}`);
  }

  it('Implementations on proxies should be applied', async () => {
    assert.equal(await setProxyImplementation(basePoolFactory, proxyPoolFactory),
      true, 'set Implementation PoolFactory: Should be equals');
    insurancePoolFactory = await CheckDotPoolFactory.at(proxyPoolFactory.address);

    assert.equal(await setProxyImplementation(baseInsuranceProtocol, proxyInsuranceProtocol),
      true, 'set Implementation InsuranceProtocol: Should be equals');
    insuranceProtocol = await CheckDotInsuranceProtocol.at(proxyInsuranceProtocol.address);

    assert.equal(await setProxyImplementation(baseInsuranceStore, proxyInsuranceStore),
      true, 'set Implementation InsuranceStore: Should be equals');
    insuranceStore = await CheckDotInsuranceStore.at(proxyInsuranceStore.address);

    assert.equal(await setProxyImplementation(baseInsuranceToken, proxyInsuranceToken),
      true, 'set Implementation InsuranceToken: Should be equals');
    insuranceToken = await CheckDotERC721InsuranceToken.at(proxyInsuranceToken.address);
  });

  it('Addresses on Store should be applied', async () => {
    await addKeyAndValueToStoreAndVerify("INSURANCE_PROTOCOL", insuranceProtocol.address);
    await addKeyAndValueToStoreAndVerify("INSURANCE_POOL_FACTORY", insurancePoolFactory.address);
    await addKeyAndValueToStoreAndVerify("INSURANCE_TOKEN", insuranceToken.address);
  });

  it('Set Store Address on Contracts', async () => {
    await insurancePoolFactory.setStore(insuranceStore.address, { from: owner });
    await insuranceProtocol.setStore(insuranceStore.address, { from: owner });
    await insuranceToken.setStore(insuranceStore.address, { from: owner });

    assert.equal(await insurancePoolFactory.getStoreAddress(),
      insuranceStore.address, 'Store in InsurancePoolFactory: Should be equals');
    assert.equal(await insuranceProtocol.getStoreAddress(),
      insuranceStore.address, 'Store in InsuranceProtocol: Should be equals');
    assert.equal(await insuranceToken.getStoreAddress(),
      insuranceStore.address, 'Store in InsuranceToken: Should be equals');
  });

  it('PoolFactory should have Store informations', async () => {
    assert.equal(await insurancePoolFactory.getInsuranceProtocolAddress(),
      insuranceProtocol.address, 'Should be equals');
    assert.equal(await insurancePoolFactory.getInsuranceTokenAddress(),
      insuranceToken.address, 'Should be equals');
  });

  it('InsuranceProtocol should have Store informations', async () => {
    assert.equal(await insuranceProtocol.getInsurancePoolFactoryAddress(),
      insurancePoolFactory.address, 'Should be equals');
    assert.equal(await insuranceProtocol.getInsuranceTokenAddress(),
      insuranceToken.address, 'Should be equals');
  });

  it('InsuranceToken should have Store informations', async () => {
    assert.equal(await insuranceToken.getInsurancePoolFactoryAddress(),
      insurancePoolFactory.address, 'Should be equals');
    assert.equal(await insuranceToken.getInsuranceProtocolAddress(),
      insuranceProtocol.address, 'Should be equals');
  });

  it('InsurancePoolFactory creating USDT Pool and reserve should be zero', async () => {
    let result = await insurancePoolFactory.createPool(usdtTokenAddress, { from: owner });

    truffleAssert.eventEmitted(result, 'PoolCreated', (ev) => {
      return ev.token == usdtTokenAddress;
    }, 'InsurancePoolFactory should return the correct NewPool event.');

    let poolWithReserve = await insurancePoolFactory.getPool(usdtTokenAddress);

    assert.equal(poolWithReserve.token, usdtTokenAddress, 'poolWithReserve.token should be equals');
    assert.equal(poolWithReserve.reserve.toString(), 0, 'Reserve Should be zero');
  });

  it('InsurancePoolFactory adding USDT Pool liquidity and reserve should be at 1000 USDT', async () => {
    let fakeUsdtERC20 = await IERC20.at(usdtTokenAddress);

    await fakeUsdtERC20.approve(insurancePoolFactory.address, toWei('1000', 'ether'), { // approve
      from: owner,
    });
    let result = await insurancePoolFactory.contribute(usdtTokenAddress, owner, toWei('1000', 'ether'), { from: owner });
    let MINIMUM_LIQUIDITY_LOCKED = toBN('1000'); // in wei

    truffleAssert.eventEmitted(result, 'ContributionAdded', (ev) => {
      return ev.from == owner;
    }, 'InsurancePoolFactory should return the correct ContributionAdded event.');

    let poolWithReserve = await insurancePoolFactory.getPool(usdtTokenAddress);

    assert.equal(poolWithReserve.token, usdtTokenAddress, 'poolWithReserve.token should be equals');
    assert.equal(fromWei(toBN(poolWithReserve.reserve).add(MINIMUM_LIQUIDITY_LOCKED), 'ether'), 1000, 'Reserve Should be 1000 USDT');
  });

  it('InsurancePoolFactory Tester add contribution USDT reserve should be at 1100 USDT', async () => {
    let fakeUsdtERC20 = await IERC20.at(usdtTokenAddress);

    await fakeUsdtERC20.transfer(tester, toWei('100', 'ether'), { from: owner }); // add 100 tokens to tester
    await fakeUsdtERC20.approve(insurancePoolFactory.address, toWei('100', 'ether'), { // approve
      from: tester,
    });
    let result = await insurancePoolFactory.contribute(usdtTokenAddress, tester, toWei('100', 'ether'), { from: tester });
    let MINIMUM_LIQUIDITY_LOCKED = toBN('1000'); // in wei

    truffleAssert.eventEmitted(result, 'ContributionAdded', (ev) => {
      return ev.from == tester;
    }, 'InsurancePoolFactory should return the correct ContributionAdded event.');

    let poolWithReserve = await insurancePoolFactory.getPool(usdtTokenAddress);

    assert.equal(poolWithReserve.token, usdtTokenAddress, 'poolWithReserve.token should be equals');
    assert.equal(fromWei(toBN(poolWithReserve.reserve).add(MINIMUM_LIQUIDITY_LOCKED), 'ether'), 1100, 'Reserve Should be 1100 USDT');
  });

  it('InsurancePoolFactory Tester remove 50% contribution USDT reserve should be at 1050 USDT', async () => {
    let poolWithReserve = await insurancePoolFactory.getPool(usdtTokenAddress);

    let fakeUsdtERC20 = await IERC20.at(usdtTokenAddress);
    let poolERC20 = await IERC20.at(poolWithReserve.poolAddress);
    let balanceLPTokens = await poolERC20.balanceOf(tester);
    let wantRemove = balanceLPTokens.div(toBN(2)).toString();
    await poolERC20.approve(insurancePoolFactory.address, wantRemove, { // approve
      from: tester,
    });
    let result = await insurancePoolFactory.uncontribute(usdtTokenAddress, tester, wantRemove, { from: tester });
    let MINIMUM_LIQUIDITY_LOCKED = toBN('1000'); // in wei

    truffleAssert.eventEmitted(result, 'ContributionRemoved', (ev) => {
      return ev.from == tester;
    }, 'InsurancePoolFactory should return the correct ContributionRemoved event.');

    let vPoolWithReserve = await insurancePoolFactory.getPool(usdtTokenAddress);

    assert.equal(vPoolWithReserve.token, usdtTokenAddress, 'poolWithReserve.token should be equals');
    assert.equal(fromWei(toBN(vPoolWithReserve.reserve).add(MINIMUM_LIQUIDITY_LOCKED), 'ether'), 1050, 'Reserve Should be 1100 USDT');

    // clean
    await fakeUsdtERC20.transfer(owner, toWei('50', 'ether'), { from: tester }); // resend 50 tokens to owner
  });

  // TODO create product
  // TODO buy product and check have NFT
  // TODO verify pool yield
  // TODO create claim
  // TODO add checkdot team comment and approve
  // TODO vote for claim and approve
  // TODO refund
  // TODO verify pool liquidity

});