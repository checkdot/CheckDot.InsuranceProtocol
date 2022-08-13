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

const UpgradableCheckDotInsuranceRiskDataCalculatorContract = contractTruffle(
  require('../build/contracts/UpgradableCheckDotInsuranceRiskDataCalculator.json'));
  UpgradableCheckDotInsuranceRiskDataCalculatorContract.setProvider(web3.currentProvider);

/* Contract Artifacts */
const IERC20 = artifacts.require('IERC20');
const ICheckDotERC721InsuranceToken = artifacts.require('ICheckDotERC721InsuranceToken');
const CheckDotPoolFactory = artifacts.require('CheckDotPoolFactory');
const CheckDotPool = artifacts.require('CheckDotPool');
const CheckDotInsuranceProtocol = artifacts.require('CheckDotInsuranceProtocol');
const CheckDotInsuranceStore = artifacts.require('CheckDotInsuranceStore');
const CheckDotERC721InsuranceToken = artifacts.require('CheckDotERC721InsuranceToken');
const CheckDotInsuranceRiskDataCalculator = artifacts.require('CheckDotInsuranceRiskDataCalculator');


contract('CheckDotInsurance', async (accounts) => {
  let usdtTokenAddress;
  let governanceTokenAddress;

  let basePoolFactory;
  let baseInsuranceProtocol;
  let baseInsuranceStore;
  let baseInsuranceToken;
  let baseInsuranceRiskDataCalculator;

  let insurancePoolFactory;
  let insuranceProtocol;
  let insuranceStore;
  let insuranceToken;
  let insuranceRiskDataCalculator;

  let proxyPoolFactory;
  let proxyInsuranceProtocol;
  let proxyInsuranceStore;
  let proxyInsuranceToken;
  let proxyInsuranceRiskDataCalculator;
  
  let owner;
  let tester;

  let snapShotId; // test blockchain snapshot

  let usdtPoolAddress;

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
    baseInsuranceRiskDataCalculator = await CheckDotInsuranceRiskDataCalculator.new({ from: owner });
    console.log('basePoolFactory        address:', basePoolFactory.address);
    console.log('baseInsuranceProtocol  address:', baseInsuranceProtocol.address);
    console.log('baseInsuranceStore     address:', baseInsuranceStore.address);
    console.log('baseInsuranceToken     address:', baseInsuranceToken.address);
    console.log('baseInsuranceRiskDC    address:', baseInsuranceRiskDataCalculator.address);

    // Proxies
    console.log("--------------------------------------------------------------------------");
    proxyPoolFactory = await UpgradableCheckDotPoolFactoryContract.new(governanceTokenAddress, { from: owner });
    proxyInsuranceProtocol = await UpgradableCheckDotInsuranceProtocolContract.new(governanceTokenAddress, { from: owner });
    proxyInsuranceStore = await UpgradableCheckDotInsuranceStoreContract.new(governanceTokenAddress, { from: owner });
    proxyInsuranceToken = await UpgradableCheckDotERC721InsuranceTokenContract.new(governanceTokenAddress, { from: owner });
    proxyInsuranceRiskDataCalculator = await UpgradableCheckDotInsuranceRiskDataCalculatorContract.new({ from: owner });
    console.log('proxyPoolFactory       address:', proxyPoolFactory.address);
    console.log('proxyInsuranceProtocol address:', proxyInsuranceProtocol.address);
    console.log('proxyInsuranceStore    address:', proxyInsuranceStore.address);
    console.log('proxyInsuranceToken    address:', proxyInsuranceToken.address);
    console.log('baseInsuranceRiskDC    address:', proxyInsuranceRiskDataCalculator.address);
    console.log("--------------------------------------------------------------------------");
  });

  after(async () => {
    await timeHelper.revertToSnapShot(snapShotId);
  });

  let setProxyDAOImplementation = async (functionalContract, proxy, storeAddress) => {
    
    const currentBlockTimeStamp = ((await web3.eth.getBlock("latest")).timestamp) + 1000;
    const startUTC = `${currentBlockTimeStamp.toFixed(0)}`;
    const endUTC = `${(currentBlockTimeStamp + 86400).toFixed(0)}`;

    const _data = web3.eth.abi.encodeParameters(['address'], [
      storeAddress
    ]);

    await proxy.upgrade(functionalContract.address, _data, startUTC, endUTC, { from: owner });

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

  let setStandardProxyImplementation = async (functionalContract, proxy, storeAddress) => {
    const _data = web3.eth.abi.encodeParameters(['address'], [
      storeAddress
    ]);

    await proxy.upgrade(functionalContract.address, _data, { from: owner });
    
    const implementation = await proxy.getImplementation();

    assert.equal(implementation, functionalContract.address, `Should be equals to ${functionalContract.address}`);

    return true;
  }

  let addKeyAndValueToStoreAndVerify = async (testKey, testValue) => {
    await insuranceStore.updateAddress(testKey, testValue, { from: owner });
    
    const ninjaValue = await insuranceStore.getAddress(testKey);

    assert.equal(ninjaValue, testValue, `Should be equals to ${testValue}`);
  }

  it('Implementations of the Store should be applied', async () => {
    assert.equal(await setProxyDAOImplementation(baseInsuranceStore, proxyInsuranceStore, proxyInsuranceStore.address),
      true, 'set Implementation InsuranceStore: Should be equals');
    insuranceStore = await CheckDotInsuranceStore.at(proxyInsuranceStore.address);
  });

  it('Addresses on Store should be applied', async () => {
    await addKeyAndValueToStoreAndVerify("INSURANCE_PROTOCOL", proxyInsuranceProtocol.address);
    await addKeyAndValueToStoreAndVerify("INSURANCE_POOL_FACTORY", proxyPoolFactory.address);
    await addKeyAndValueToStoreAndVerify("INSURANCE_TOKEN", proxyInsuranceToken.address);
    await addKeyAndValueToStoreAndVerify("INSURANCE_RISK_DATA_CALCULATOR", proxyInsuranceRiskDataCalculator.address);
  });

  it('Implementations on proxies should be applied', async () => {

    assert.equal(await setProxyDAOImplementation(basePoolFactory, proxyPoolFactory, proxyInsuranceStore.address),
      true, 'set Implementation PoolFactory: Should be equals');
    insurancePoolFactory = await CheckDotPoolFactory.at(proxyPoolFactory.address);

    assert.equal(await setProxyDAOImplementation(baseInsuranceProtocol, proxyInsuranceProtocol, proxyInsuranceStore.address),
      true, 'set Implementation InsuranceProtocol: Should be equals');
    insuranceProtocol = await CheckDotInsuranceProtocol.at(proxyInsuranceProtocol.address);

    assert.equal(await setProxyDAOImplementation(baseInsuranceToken, proxyInsuranceToken, proxyInsuranceStore.address),
      true, 'set Implementation InsuranceToken: Should be equals');
    insuranceToken = await CheckDotERC721InsuranceToken.at(proxyInsuranceToken.address);

    assert.equal(await setStandardProxyImplementation(baseInsuranceRiskDataCalculator, proxyInsuranceRiskDataCalculator, proxyInsuranceStore.address),
      true, 'set Implementation InsuranceRiskDataCalculator: Should be equals');
    insuranceRiskDataCalculator = await CheckDotInsuranceRiskDataCalculator.at(proxyInsuranceRiskDataCalculator.address);
  });

  // it('Check', async () => {
  //   insuranceRiskDataCalculator.getERC20PriceInUSD('')
  //   poolFor
  // })

  it('Check initialization of Contracts', async () => {
    assert.equal(await insurancePoolFactory.getStoreAddress(),
      insuranceStore.address, 'Store in InsurancePoolFactory: Should be equals');
    assert.equal(await insuranceProtocol.getStoreAddress(),
      insuranceStore.address, 'Store in InsuranceProtocol: Should be equals');
    assert.equal(await insuranceToken.getStoreAddress(),
      insuranceStore.address, 'Store in InsuranceToken: Should be equals');
    assert.equal(await insuranceRiskDataCalculator.getStoreAddress(),
      insuranceStore.address, 'Store in InsuranceRiskDataCalculator: Should be equals');
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

  it('InsuranceRiskDataCalculator should have Store informations', async () => {
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

    usdtPoolAddress = poolWithReserve.poolAddress;

    assert.equal(poolWithReserve.token, usdtTokenAddress, 'poolWithReserve.token should be equals');
    assert.equal(poolWithReserve.reserve.toString(), 0, 'Reserve Should be zero');
  });


  it('Check poolFor Hash', async () => {
    let poolAddr = await insuranceProtocol.poolFor(usdtTokenAddress);
    assert.equal(poolAddr, usdtPoolAddress, 'should be equals');
  })

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
    await timeHelper.advanceTime(86400*16); // add 15 days
    await timeHelper.advanceBlock(); // add one block

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

  it('Insurance Protocol should have one product', async () => {
    const currentBlockTimeStamp = ((await web3.eth.getBlock("latest")).timestamp) + 1000;
    //function createProduct(uint256 _utcProductStartDate, uint256 _utcProductEndDate, uint256 _minCoverInDays, uint256 _maxCoverInDays, uint256 _basePremiumInPercentPerDay, string calldata _uri, string calldata _title, address[] calldata _coverCurrencies) external;
    const DAY = 86400;
    const YEAR = (DAY * 365);
    const _utcProductStartDate = `${currentBlockTimeStamp.toFixed(0)}`;
    const _utcProductEndDate = `${(currentBlockTimeStamp + (YEAR * 2)).toFixed(0)}`;
    const _minCoverInDays = "1";
    const _maxCoverInDays = "365";
    const _basePremiumInPercent = toWei(`2`, 'ether');
    const _riskRatio = toWei(`2.5`, 'ether');
    const _uri = "productTestURI";
    const _name = "Test Protocol";
    const _coverCurrencies = [usdtTokenAddress];
    const _minCoverCurrenciesAmounts = [toWei(`1000`, 'ether')];
    const _maxCoverCurrenciesAmounts = [toWei(`50000`, 'ether')];
    const _data = web3.eth.abi.encodeParameters(['string', 'string', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256', 'address[]', 'uint256[]', 'uint256[]'], [
      _name,
      _uri,
      _utcProductStartDate,
      _utcProductEndDate,
      _riskRatio,
      _basePremiumInPercent,
      _minCoverInDays,
      _maxCoverInDays,
      _coverCurrencies,
      _minCoverCurrenciesAmounts,
      _maxCoverCurrenciesAmounts
    ]);
    let result = await insuranceProtocol.createProduct(_data, { from: owner });
    let firstProductId = 0;
    truffleAssert.eventEmitted(result, 'ProductCreated', (ev) => {
      firstProductId = Number(ev.id.toString());
      return Number(ev.id.toString()) == 0;
    }, 'InsuranceProtocol should return the correct ProductCreated event.');

    let productDetails = await insuranceProtocol.getProductDetails(firstProductId);

    console.log('productDetails:', productDetails);

    assert.equal(productDetails.name, 'Test Protocol', 'should be equals');
  });

  it('Insurance Protocol cover cost for 100 USDT cost should be 2 USDT', async () => {
    let coverCost = await insuranceProtocol.getCoverCost('0', usdtTokenAddress, toWei('100', 'ether'), '365');

    assert.equal(fromWei(coverCost.toString(), 'ether'), '2', 'should be equals');
  });

  it('Insurance Protocol buy product should send NFT', async () => {
    let fakeUsdtERC20 = await IERC20.at(usdtTokenAddress);
    await fakeUsdtERC20.approve(insuranceProtocol.address, toWei('100', 'ether'), { // approve
      from: owner,
    });

    let result = await insuranceProtocol.buyCover(0, owner, toWei('100', 'ether'), usdtTokenAddress, 365, false, { from: owner });

    //uint256 coverId, uint256 productId, uint256 coveredAmount, uint256 premiumCost
    truffleAssert.eventEmitted(result, 'PurchasedCover', (ev) => {
      console.log('test', ev);
      return Number(ev.coverId.toString()) == 0;
    }, 'InsuranceProtocol should return the correct PurchasedCover event.');

    let tokenBalance = await insuranceToken.balanceOf(owner);
    assert.equal(tokenBalance.toString(), '1', `tokenBalance should be equals to 1`);

    let cover = await insuranceToken.getCover('0');
    assert.equal(cover.coveredAddress, owner, `coveredAddress should be equals to ${owner}`);
  });

  it('GET SCR%', async () => {
    let poolLength = (await insurancePoolFactory.getPoolsLength()).toString();
    console.log('poolLength', poolLength);
    let result = await insurancePoolFactory.getPools("0", "100");
    console.log('result', result);
    let solvability = await insuranceRiskDataCalculator.getSolvability();
    console.log('solvability', solvability[0].toString(), solvability[1].toString(), solvability[2].toString());
    console.log('Solvability Ratio', (Number(solvability[0].toString()) / (10**18)));
    console.log('SCR', (Number(solvability[1].toString()) / (10**18)));
    console.log('SCRSize', (Number(solvability[2].toString()) / (10**18)));

    assert.equal((Number(solvability[0].toString()) / (10**18)) <= 3, true, `SolvabilityRatio overflow`);
  });

  

  // TODO verify pool yield
  // TODO create claim
  // TODO add checkdot team comment and approve
  // TODO vote for claim and approve
  // TODO refund
  // TODO verify pool liquidity

});