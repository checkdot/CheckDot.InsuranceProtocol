// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../interfaces/IERC20.sol";
import "../../interfaces/IDAOProxy.sol";
import "../../interfaces/IInsuranceProtocol.sol";
import "../../interfaces/ICheckDotPoolFactory.sol";
import "../../interfaces/ICheckDotInsuranceStore.sol";
import "../../interfaces/ICheckDotPool.sol";
import "../../interfaces/ICheckDotERC721InsuranceToken.sol";
import "../../interfaces/ICheckDotInsuranceRiskDataCalculator.sol";
import "../../utils/Counters.sol";
import "../../utils/SafeMath.sol";
import "../../utils/SignedSafeMath.sol";
import "../../utils/BytesHelper.sol";
import "../../utils/TransferHelper.sol";
import "../../utils/Owned.sol";
import "../../utils/Addresses.sol";
import "../../structs/ModelProducts.sol";
import "../../structs/ModelPools.sol";

import "../../../../../CheckDot.DAOProxyContract/contracts/interfaces/IOwnedProxy.sol";

contract CheckDotInsuranceProtocol {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using BytesHelper for bytes;
    using Counters for Counters.Counter;
    using ModelProducts for ModelProducts.Product;
    using ModelProducts for ModelProducts.ProductWithDetails;

    event PurchasedCover(uint256 coverId, uint256 productId, uint256 coveredAmount, uint256 premiumCost);
    event ProductUpdated(uint256 id,
        string name,
        string riskType,
        uint256 premiumInPercentPerDay,
        uint256 utcProductStartDate,
        uint256 utcProductEndDate,
        uint16 minCoverInDays,
        uint16 maxCoverInDays);
    event ProductCreated(uint256 id);

    string private constant STORE = "STORE";
    string private constant INSURANCE_TOKEN = "INSURANCE_TOKEN";
    string private constant INSURANCE_POOL_FACTORY = "INSURANCE_POOL_FACTORY";
    string private constant INSURANCE_RISK_DATA_CALCULATOR = "INSURANCE_RISK_DATA_CALCULATOR";
    string private constant CHECKDOT_TOKEN = "CHECKDOT_TOKEN";

    bool internal locked;

    // V1 DATA

    /* Map of Essentials Addresses */
    mapping(string => address) private protocolAddresses;

    struct Products {
        mapping(uint256 => ModelProducts.Product) values;
        Counters.Counter counter;
    }

    Products private products;

    bytes32 private poolFactoryInitCodeHash;

    // END V1

    function initialize(bytes memory _data) external onlyOwner {
        (address _storeAddress) = abi.decode(_data, (address));

        require(_storeAddress != address(0), "STORE_EMPTY");
        protocolAddresses[STORE] = _storeAddress;
        protocolAddresses[INSURANCE_POOL_FACTORY] = ICheckDotInsuranceStore(protocolAddresses[STORE]).getAddress(INSURANCE_POOL_FACTORY);
        protocolAddresses[INSURANCE_TOKEN] = ICheckDotInsuranceStore(protocolAddresses[STORE]).getAddress(INSURANCE_TOKEN);
        protocolAddresses[INSURANCE_RISK_DATA_CALCULATOR] = ICheckDotInsuranceStore(protocolAddresses[STORE]).getAddress(INSURANCE_RISK_DATA_CALCULATOR);
        protocolAddresses[CHECKDOT_TOKEN] = IDAOProxy(address(this)).getGovernance();
        poolFactoryInitCodeHash = ICheckDotPoolFactory(protocolAddresses[INSURANCE_POOL_FACTORY]).getInitCodePoolHash();
    }

    modifier onlyOwner {
        require(msg.sender == IOwnedProxy(address(this)).getOwner(), "InsuranceProtocol: FORBIDDEN");
        _;
    }

    modifier productExists(uint256 productId) {
        require(bytes(products.values[productId].name).length != 0, "DOESNT_EXISTS");
        _;
    }

    modifier activatedProduct(uint256 productId) {
        require(products.values[productId].status == ModelProducts.ProductStatus.Active, "Product is paused");
        _;
    }

    modifier noContract() {
        require(!Addresses.isContract(msg.sender), "FORBIDEN_CONTRACT");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    /**
     * @dev Returns the Store address.
     */
    function getStoreAddress() external view returns (address) {
        return protocolAddresses[STORE];
    }

    /**
     * @dev Returns the Insurance Pool Factory address.
     */
    function getInsurancePoolFactoryAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_POOL_FACTORY];
    }

    /**
     * @dev Returns the Insurance Token address.
     */
    function getInsuranceTokenAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_TOKEN];
    }

    /**
     * @dev Returns the Insurance Risk Data Calculator address.
     */
    function getInsuranceRiskDataCalculatorAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_RISK_DATA_CALCULATOR];
    }

    /**
     * calculates the CREATE2 address for a pool without making any external calls
     */
    function poolFor(address token) public view returns (address pair) {
        bytes32 hashValue = keccak256(abi.encodePacked(
                hex'ff',
                protocolAddresses[INSURANCE_POOL_FACTORY],
                keccak256(abi.encodePacked(token)),
                poolFactoryInitCodeHash
            ));
        assembly {
            mstore(0, hashValue)
            pair := mload(0)
        }
    }
   
    function createProduct(bytes memory _data) external onlyOwner {
        (
            string memory _name,
            string memory _riskType,
            string memory _uri,
            uint256 _utcProductStartDate,
            uint256 _utcProductEndDate,
            uint256 _riskRatio,
            uint256 _basePremiumInPercent,
            uint256 _minCoverInDays,
            uint256 _maxCoverInDays
        ) = abi.decode(_data, (string, string, string, uint256, uint256, uint256, uint256, uint256, uint256));
        require(_minCoverInDays > 0, "InsuranceProtocol: MIN_COVER_UNALLOWED");
        require(_maxCoverInDays > 0, "InsuranceProtocol: MAX_COVER_UNALLOWED");

        uint256 id = products.counter.current();

        products.values[id].id = id;
        products.values[id].riskType = _riskType;
        products.values[id].URI = _uri;
        products.values[id].name = _name;
        products.values[id].riskRatio = _riskRatio;
        products.values[id].basePremiumInPercent = _basePremiumInPercent;
        products.values[id].status = ModelProducts.ProductStatus.Active;
        products.values[id].utcProductStartDate = _utcProductStartDate; 
        products.values[id].utcProductEndDate = _utcProductEndDate;
        products.values[id].minCoverInDays = _minCoverInDays;
        products.values[id].maxCoverInDays = _maxCoverInDays;

        // for (uint256 i = 0; i < _coverCurrencies.length; i++) { // add coverCurrencies
        //     ModelPools.PoolWithReserve memory pool = ICheckDotPoolFactory(protocolAddresses[INSURANCE_POOL_FACTORY]).getPool(_coverCurrencies[i]);

        //     require(pool.poolAddress != address(0), "InsuranceProtocol: POOL_DOESNT_EXISTS");
        //     products.values[id].coverCurrencies.push(_coverCurrencies[i]);
        //     products.values[id].coverCurrenciesPoolAddresses.push(pool.poolAddress);
        //     products.values[id].minCoverCurrenciesAmounts.push(_minCoverCurrenciesAmounts[i]);
        //     products.values[id].maxCoverCurrenciesAmounts.push(_maxCoverCurrenciesAmounts[i]);
        // }
        products.counter.increment();
        emit ProductCreated(id);
    }

    function buyCover(uint256 _productId,
        address _coveredAddress,
        uint256 _coveredAmount,
        address _coverCurrency,
        uint256 _durationInDays,
        address _payIn) external payable noReentrant activatedProduct(_productId) noContract {
        require(isValidBuy(_productId, _coveredAddress, _coveredAmount, _coverCurrency, _durationInDays), "UNAVAILABLE");
        ModelProducts.Product storage product = products.values[_productId];
        
        uint256 totalCostInCoverCurrency = _payCover(_productId, _coveredAmount, _coverCurrency, _durationInDays, _payIn);

        uint256 tokenId = ICheckDotERC721InsuranceToken(protocolAddresses[INSURANCE_TOKEN]).mintInsuranceToken(product.id, _coveredAddress, _durationInDays, totalCostInCoverCurrency, _coverCurrency, _coveredAmount, product.URI);

        emit PurchasedCover(tokenId, product.id, _coveredAmount, totalCostInCoverCurrency);
    }

    function isValidBuy(uint256 _productId,
        address _coveredAddress,
        uint256 _coveredAmount,
        address _coverCurrency,
        uint256 _durationInDays) public view returns (bool) {
        require(_coveredAddress != address(0), "EMPTY_COVER");
        ModelProducts.Product storage product = products.values[_productId];
        
        require(block.timestamp.add(_durationInDays.mul(86400)) <= product.utcProductEndDate, "PRODUCT_EXPIRED");
        require(_durationInDays >= product.minCoverInDays, "DURATION_TOO_SHORT");
        require(_durationInDays <= product.maxCoverInDays, "DURATION_MAX_EXCEEDED");
        // require(product.coverCurrencyExists(_coverCurrency), "CURRENCY_NOT_COVERED");
        require(ICheckDotInsuranceRiskDataCalculator(protocolAddresses[INSURANCE_RISK_DATA_CALCULATOR]).coverIsSolvable(product.riskRatio, _coverCurrency, _coveredAmount), "NOT_SOLVABLE_COVER");
        return true;
    }

    function _payCover(uint256 _productId,
        uint256 _coveredAmount,
        address _coverCurrency,
        uint256 _durationInDays,
        address _payIn) internal returns (uint256) {
        ModelProducts.Product storage product = products.values[_productId];
        
        uint256 totalCostInCoverCurrency = getCoverCost(product.id, _coverCurrency, _coveredAmount, _durationInDays);
        uint256 payCost = ICheckDotInsuranceRiskDataCalculator(protocolAddresses[INSURANCE_RISK_DATA_CALCULATOR]).convertCost(totalCostInCoverCurrency, _coverCurrency, _payIn);
        address poolAddress = poolFor(_payIn);
        uint256 fees = payCost.div(100).mul(2); // 2%

        require(IERC20(_payIn).balanceOf(msg.sender) >= payCost, "INSUFISANT_BALANCE");

        TransferHelper.safeTransferFrom(_payIn, msg.sender, poolAddress, payCost.sub(fees)); // send 98% tokens to pool
        ICheckDotPool(poolAddress).sync(); // Synchronization of the reserve for distribution to the holders.

        TransferHelper.safeTransferFrom(_payIn, msg.sender, poolAddress, fees); // send fees to pool
        ICheckDotPoolFactory(protocolAddresses[INSURANCE_POOL_FACTORY]).mintInsuranceProtocolFees(_payIn, IOwnedProxy(address(this)).getOwner()); // associate the fees to the owner
        return totalCostInCoverCurrency;
    }

    function revokeExpiredCovers() external payable onlyOwner {
        ICheckDotERC721InsuranceToken(protocolAddresses[INSURANCE_TOKEN]).revokeExpiredCovers();
    }

    //////////
    // Views
    //////////

    function getCoverCost(uint256 _productId, address _coverCurrency, uint256 _coveredAmount, uint256 _durationInDays) public view returns (uint256) {
        ModelProducts.Product storage product = products.values[_productId];
        
        (
            /** Unused Parameter **/,
            uint256 cumulativePremiumInPercent,
            /** Unused Parameter **/,
            /** Unused Parameter **/
        ) = getCoverCurrencyDetails(_coverCurrency);

        uint256 premiumInPercent = product.basePremiumInPercent.add(cumulativePremiumInPercent);
        uint256 costOnOneYear = _coveredAmount.mul(premiumInPercent).div(100 ether);
        
        return costOnOneYear.mul(_durationInDays.mul(1 ether)).div(365 ether);
    }

    function getProductLength() public view returns (uint256) {
        return products.counter.current();
    }

    function getProductDetails(uint256 _id) public view returns (ModelProducts.ProductWithDetails memory) {
        ModelProducts.ProductWithDetails[] memory results = new ModelProducts.ProductWithDetails[](1);
        ModelProducts.Product storage product = products.values[_id];
        
        results[0].id = product.id;
        results[0].name = product.name;
        results[0].URI = product.URI;
        results[0].status = product.status;
        results[0].riskRatio = product.riskRatio;
        results[0].basePremiumInPercent = product.basePremiumInPercent;
        results[0].utcProductStartDate = product.utcProductStartDate;
        results[0].utcProductEndDate = product.utcProductEndDate;
        results[0].minCoverInDays = product.minCoverInDays;
        results[0].maxCoverInDays = product.maxCoverInDays;
        // results[0].coverCurrencies = new address[](product.coverCurrencies.length);
        // results[0].coverCurrenciesPoolAddresses = new address[](product.coverCurrencies.length);
        // results[0].minCoverCurrenciesAmounts = new uint256[](product.coverCurrencies.length);
        // results[0].maxCoverCurrenciesAmounts = new uint256[](product.coverCurrencies.length);
        // results[0].cumulativePremiumInPercents = new uint256[](product.coverCurrencies.length);
        // results[0].coverCurrenciesCoveredAmounts = new uint256[](product.coverCurrencies.length);
        // results[0].coverCurrenciesCapacities = new int256[](product.coverCurrencies.length);
        // results[0].coverCurrenciesEnabled = new bool[](product.coverCurrencies.length);
        // for (uint256 i = 0; i < product.coverCurrencies.length; i++) {
        //     (
        //         uint256 currentCoverCurrencyCoveredAmount,
        //         uint256 cumulativePremiumInPercent,
        //         int256 poolCapacity,
        //         // uint256 reserve unused
        //     ) = getProductCoverCurrencyDetails(product.id, product.coverCurrencies[i]);

        //     results[0].coverCurrencies[i] = product.coverCurrencies[i];
        //     results[0].coverCurrenciesPoolAddresses[i] = product.coverCurrenciesPoolAddresses[i];
        //     results[0].minCoverCurrenciesAmounts[i] = product.minCoverCurrenciesAmounts[i];
        //     results[0].maxCoverCurrenciesAmounts[i] = product.maxCoverCurrenciesAmounts[i];
        //     results[0].cumulativePremiumInPercents[i] = cumulativePremiumInPercent;
        //     results[0].coverCurrenciesCoveredAmounts[i] = currentCoverCurrencyCoveredAmount;
        //     results[0].coverCurrenciesCapacities[i] = poolCapacity;
        //     // results[0].coverCurrenciesEnabled[i] = poolCapacity > 0;
        // }
        return results[0];
    }

    function getCoverCurrencyDetails(address _coverCurrency) public view returns (uint256, uint256, int256, uint256) {
        uint256 poolReserve = ICheckDotPool(poolFor(_coverCurrency)).getReserves();
        uint256 currentCoverCurrencyCoveredAmount = ICheckDotERC721InsuranceToken(protocolAddresses[INSURANCE_TOKEN]).getTotalCoveredAmountFromCurrency(_coverCurrency);
        int256 signedCapacity = int256(poolReserve).sub(int256(currentCoverCurrencyCoveredAmount));
        uint256 capacity = signedCapacity > 0 ? uint256(signedCapacity) : 0;
        uint256 availablePercentage = signedCapacity > 0 ? uint256(100 ether).sub(uint256(capacity).mul(100 ether).div(poolReserve)) : 0;
        uint256 cumulativePremiumInPercent = availablePercentage.mul(3 ether).div(100 ether); // 3% addable
        return (currentCoverCurrencyCoveredAmount, cumulativePremiumInPercent, signedCapacity, poolReserve);
    }

    //////////
    // Update
    //////////

    function pauseProduct(uint256 _productId) external onlyOwner {
        products.values[_productId].status = ModelProducts.ProductStatus.Paused;
    }

    function activeProduct(uint256 _productId) external onlyOwner {
        products.values[_productId].status = ModelProducts.ProductStatus.Active;
    }

    function cancelProduct(uint256 _productId) external onlyOwner {
        products.values[_productId].status = ModelProducts.ProductStatus.Canceled;
    }

    function updateProduct(uint256 _productId, bytes memory _data) external onlyOwner {
        (
            string memory _name,
            string memory _riskType,
            string memory _uri,
            uint256 _utcProductStartDate,
            uint256 _utcProductEndDate,
            uint256 _riskRatio,
            uint256 _basePremiumInPercent,
            uint256 _minCoverInDays,
            uint256 _maxCoverInDays
        ) = abi.decode(_data, (string, string, string, uint256, uint256, uint256, uint256, uint256, uint256));

        products.values[_productId].riskType = _riskType;
        products.values[_productId].URI = _uri;
        products.values[_productId].name = _name;
        products.values[_productId].riskRatio = _riskRatio;
        products.values[_productId].basePremiumInPercent = _basePremiumInPercent;
        products.values[_productId].status = ModelProducts.ProductStatus.Active;
        products.values[_productId].utcProductStartDate = _utcProductStartDate;
        products.values[_productId].utcProductEndDate = _utcProductEndDate;
        products.values[_productId].minCoverInDays = _minCoverInDays;
        products.values[_productId].maxCoverInDays = _maxCoverInDays;
    }

}