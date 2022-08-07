// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../interfaces/IERC20.sol";
import "../../interfaces/IInsuranceProtocol.sol";
import "../../interfaces/ICheckDotPoolFactory.sol";
import "../../interfaces/ICheckDotInsuranceStore.sol";
import "../../utils/Counters.sol";
import "../../utils/SafeMath.sol";
import "../../utils/BytesHelper.sol";
import "../../utils/Owned.sol";
import "../../structs/ModelProducts.sol";

import "../../../../../CheckDot.DAOProxyContract/contracts/interfaces/IOwnedProxy.sol";

contract CheckDotInsuranceProtocol {
    using SafeMath for uint256;
    using BytesHelper for bytes;
    using Counters for Counters.Counter;
    using ModelProducts for ModelProducts.Product;

    event Claim(uint256 policyId, uint256 amount);    
    event PaymentReceived(uint256 policyId, uint256 amount);
    event ProductUpdated(uint256 id,
        string title,
        string description,
        uint256 premiumInPercentPerDay,
        uint256 utcProductStartDate,
        uint256 utcProductEndDate,
        uint16 minCoverInDays,
        uint16 maxCoverInDays);
    event ProductCreated(uint256 id);

    struct Products {
        mapping(uint256 => ModelProducts.Product) values;
        Counters.Counter counter;
    }

    struct Pools {
        address factory;
    }

    struct Proof {
        address soulBoundTokenAddress;
    }

    Products private products;

    address private store;

    function initialize() external payable onlyOwner {
        // unused
    }

    modifier onlyOwner {
        require(msg.sender == IOwnedProxy(address(this)).getOwner(), "FORBIDDEN");
        _;
    }

    modifier activatedProduct(uint256 productId) {
        require(products.values[productId].status == ModelProducts.ProductStatus.Active, "Product is paused");
        _;
    }

    modifier pausedProduct(uint256 productId) {
        require(products.values[productId].status == ModelProducts.ProductStatus.Paused, "Product isn't paused");
        _;
    }

    function setStore(address _store) external onlyOwner {
        require(store == address(0), "ALREADY_INITIALIZED");
        store = _store;
    }

    /**
     * @dev Returns the Store address.
     */
    function getStoreAddress() external view returns (address) {
        return store;
    }

    /**
     * @dev Returns the Insurance Pool Factory address.
     */
    function getInsurancePoolFactoryAddress() external view returns (address) {
        return _getInsurancePoolFactoryAddress();
    }

    /**
     * @dev Returns the Insurance Token address.
     */
    function getInsuranceTokenAddress() external view returns (address) {
        return _getInsuranceTokenAddress();
    }
   
    function createProduct(
        uint256 _utcProductStartDate, 
        uint256 _utcProductEndDate,
        uint256 _minCoverInDays,
        uint256 _maxCoverInDays,
        uint256 _basePremiumInPercentPerDay,
        string calldata _uri,
        string calldata _title,
        address[] calldata _coverCurrencies) external onlyOwner {
        
        address poolFactoryAddress = _getInsurancePoolFactoryAddress();
        require(poolFactoryAddress != address(0), "InsuranceProtocol: UNINITIALIZED_STORE");
        ICheckDotPoolFactory poolFactory = ICheckDotPoolFactory(poolFactoryAddress);
        
        uint256 id = products.counter.current();

        require(_minCoverInDays > 0, "InsuranceProtocol: MIN_COVER_UNALLOWED");
        require(_maxCoverInDays > 0, "InsuranceProtocol: MAX_COVER_UNALLOWED");

        products.values[id].id = id;
        products.values[id].URI = _uri;
        products.values[id].title = _title;
        products.values[id].basePremiumInPercentPerDay = _basePremiumInPercentPerDay;
        products.values[id].cumulativePremiumInPercentPerDay = 0;
        products.values[id].status = ModelProducts.ProductStatus.Paused;
        products.values[id].utcProductStartDate = _utcProductStartDate; 
        products.values[id].utcProductEndDate = _utcProductEndDate;
        products.values[id].minCoverInDays = _minCoverInDays;
        products.values[id].maxCoverInDays = _maxCoverInDays;

        for (uint256 i = 0; i < _coverCurrencies.length; i++) { // add coverCurrencies
            require(poolFactory.poolExists(_coverCurrencies[i]), "InsuranceProtocol: POOL_DOESNT_EXISTS");
            products.values[id].coverCurrencies[i] = _coverCurrencies[i];
        }
        products.counter.increment();
        emit ProductCreated(id);
    }

    // function buy(uint256 _productId,
    //     uint256 _coverAmount,
    //     address _coveredCurrency,
    //     uint256 _durationInDays,
    //     bool _useCDTs) external payable activatedProduct(_productId) {

    //     address soulBoundTokenAddress = _getSoulBoundTokenAddress();
    //     require(soulBoundTokenAddress != address(0), "InsuranceProtocol: UNINITIALIZED_STORE");
    //     ICheckDotPoolFactory poolFactory = I(soulBoundTokenAddress);

    //     address poolFactoryAddress = _getPoolFactoryAddress();
    //     require(poolFactoryAddress != address(0), "InsuranceProtocol: UNINITIALIZED_STORE");
    //     ICheckDotPoolFactory poolFactory = ICheckDotPoolFactory(poolFactoryAddress);

    //     ModelProducts.Product memory product = products.values[_productId];
    //     // todo validate Dates
    //     require(block.timestamp.add(_durationInDays.mul(86000)) <= product.utcProductEndDate, "InsuranceProtocol: PRODUCT_EXPIRED");
    //     require(_durationInDays >= product.minCoverInDays, "InsuranceProtocol: DURATION_TOO_SHORT");
    //     require(_durationInDays <= product.maxCoverInDays, "InsuranceProtocol: DURATION_MAX_EXCEEDED");
    //     require(product.coverCurrencyExists(_coveredCurrency), "InsuranceProtocol: CURRENCY_NOT_COVERED");
        
    //     uint256 _amountOfTokens = 
    //     require(_amountOfTokens > 0, "amount should be > 0");
    //     require(msg.sender != address(0), "not valid from");
    //     require(policiesIds.length <= policiesLimit,"policies limit was reached");
    //     require(IERC20(token).balanceOf(msg.sender) >= _amountOfTokens, "buyer not solvent");
        
    //     // TODO: check pourcentage de la pool aloué si limit ateinte.
    //     // require(pool <= productPoolLimit, "buyer balance reached limit");

    //     uint256 policyId = getPolicyId();

    //     require(policies[policyId].premium == 0, "policy is paid and already exist");

    //     totalPolicies++;

    //     // Transfer tokens from sender to pool contract
    //     //require(IERC20(_token).transferFrom(msg.sender, address(pool), _amountOfTokens), "Tokens transfer failed.");
   
    //     policies[policyId].premium = _amountOfTokens;
    //     policies[policyId].owner = msg.sender;
    //     policies[policyId].utcStart = block.timestamp;
    //     policies[policyId].utcEnd = block.timestamp.add(policyTermInSeconds);
    //     policies[policyId].created = block.timestamp;

    //     myPolicies[msg.sender].push(policyId);

    //     emit PaymentReceived(policyId, _amountOfTokens);
    // }
          
    // function claim(uint256 _insuranceTokenId, uint256 _claimAmount) external {
    //     require(tokenBalance() >= policies[_policyId].calculatedPayout, "Contract balance is to low");

    //     policies[_policyId].utcPayoutDate = uint256(now);
    //     policies[_policyId].payout = policies[_policyId].calculatedPayout;
    //     policies[_policyId].claimProperties = _properties;

    //     policiesPayoutsCount++;
    //     policiesTotalPayouts = policiesTotalPayouts.add(policies[_policyId].payout);

    //     assert(IERC20(token).transfer(policies[_policyId].owner, policies[_policyId].payout));

    //     emit Claim(_policyId, policies[_policyId].payout);
    // }

    //////////
    // Views
    //////////

    // function getProductDetails() public view returns (address, address, uint256, uint256, string, string, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
       
    //    (uint256 basePremium, uint256 payout, uint256 loading) = IPremiumCalculator(premiumCalculator).getDetails();
       
    //     return (premiumCalculator, 
    //       investorsPool, 
    //       utcProductStartDate,
    //       utcProductEndDate,
    //       title,
    //       description,
    //       policyTermInSeconds,
    //       basePremium,
    //       payout,
    //       loading,
    //       policiesLimit,
    //       productPoolLimit,
    //       created
    //       );
    // }

    // function getProductStats() public view returns (bool, uint256, uint256, uint256, uint256, uint256) {
    //     return (
    //         paused,
    //         IERC20(token).balanceOf(this),
    //         policiesIds.length,
    //         policiesTotalCalculatedPayouts,
    //         policiesPayoutsCount,
    //         policiesTotalPayouts
    //       );
    // }

    //////////
    // Update
    //////////

    function pauseProduct(uint256 _productId) external onlyOwner activatedProduct(_productId) {
        products.values[_productId].status = ModelProducts.ProductStatus.Paused;
    }

    function activeProduct(uint256 _productId) external onlyOwner pausedProduct(_productId) {
        products.values[_productId].status = ModelProducts.ProductStatus.Active;
    }

    function cancelProduct(uint256 _productId) external onlyOwner pausedProduct(_productId) {
        products.values[_productId].status = ModelProducts.ProductStatus.Canceled;
    }

    // function updateProduct(uint256 _productId,
    //     string calldata _title,
    //     string calldata _description,
    //     uint256 _premiumInPercentPerDay,
    //     uint256 _utcProductStartDate,
    //     uint256 _utcProductEndDate,
    //     uint256 _minCoverInDays,
    //     uint256 _maxCoverInDays)
    //         external 
    //         onlyOwner 
    //         pausedProduct(_productId) {

    //     products.values[_productId].title = _title;
    //     products.values[_productId].description = _description;
    //     products.values[_productId].premiumInPercentPerDay = _premiumInPercentPerDay;
    //     products.values[_productId].utcProductStartDate = _utcProductStartDate;
    //     products.values[_productId].utcProductEndDate = _utcProductEndDate;
    //     products.values[_productId].minCoverInDays = _minCoverInDays;
    //     products.values[_productId].maxCoverInDays = _maxCoverInDays;

    //     emit ProductUpdated(
    //         _productId,
    //         _title,
    //         _description,
    //         _premiumInPercentPerDay,
    //         _utcProductStartDate,
    //         _utcProductEndDate,
    //         _minCoverInDays,
    //         _maxCoverInDays);
    // }

    // function _getPoolFactory() internal view returns (ICheckDotPoolFactory storage) {
    //     return ICheckDotPoolFactory(_getPoolFactoryAddress());
    // }

    /**
     * @dev Returns the Insurance Pool Factory address.
     */
    function _getInsurancePoolFactoryAddress() internal view returns (address) {
        return ICheckDotInsuranceStore(store).getAddress("INSURANCE_POOL_FACTORY");
    }

    /**
     * @dev Returns the Insurance token address.
     */
    function _getInsuranceTokenAddress() internal view returns (address) {
        return ICheckDotInsuranceStore(store).getAddress("INSURANCE_TOKEN");
    }

}