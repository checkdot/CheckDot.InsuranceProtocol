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

    event ClaimCreated(uint256 id, uint256 productId, uint256 amount);    
    event PurchasedCover(uint256 coverId, uint256 productId, uint256 coveredAmount, uint256 premiumCost);
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

    Products private products;

    struct Claims {
        mapping(uint256 => ModelClaims.ClaimWithParticipators) values;
    }

    Claims private claims;

    address private store;
    address private insurancePoolFactoryAddress;
    address private insuranceTokenAddress;
    address private insuranceRiskDataCalculatorAddress;

    bytes32 private poolFactoryInitCodeHash;

    function initialize(bytes memory _data) external onlyOwner {
        (address _storeAddress) = abi.decode(_data, (address));

        require(_storeAddress != address(0), "STORE_EMPTY");
        store = _storeAddress;
        insurancePoolFactoryAddress = ICheckDotInsuranceStore(store).getAddress("INSURANCE_POOL_FACTORY");
        insuranceTokenAddress = ICheckDotInsuranceStore(store).getAddress("INSURANCE_TOKEN");
        insuranceRiskDataCalculatorAddress = ICheckDotInsuranceStore(store).getAddress("INSURANCE_RISK_DATA_CALCULATOR");
        poolFactoryInitCodeHash = ICheckDotPoolFactory(insurancePoolFactoryAddress).getInitCodePoolHash();
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

    modifier pausedProduct(uint256 productId) {
        require(products.values[productId].status == ModelProducts.ProductStatus.Paused, "Product isn't paused");
        _;
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
        return insurancePoolFactoryAddress;
    }

    /**
     * @dev Returns the Insurance Token address.
     */
    function getInsuranceTokenAddress() external view returns (address) {
        return insuranceTokenAddress;
    }

    /**
     * @dev Returns the Insurance Risk Data Calculator address.
     */
    function getInsuranceRiskDataCalculatorAddress() external view returns (address) {
        return insuranceRiskDataCalculatorAddress;
    }

    /**
     * calculates the CREATE2 address for a pool without making any external calls
     */
    function poolFor(address token) public view returns (address pair) {
        bytes32 hashValue = keccak256(abi.encodePacked(
                hex'ff',
                insurancePoolFactoryAddress,
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
            string memory _uri,
            uint256 _utcProductStartDate,
            uint256 _utcProductEndDate,
            uint256 _riskRatio,
            uint256 _basePremiumInPercent,
            uint256 _minCoverInDays,
            uint256 _maxCoverInDays,
            address[] memory _coverCurrencies,
            uint256[] memory _minCoverCurrenciesAmounts,
            uint256[] memory _maxCoverCurrenciesAmounts
        ) = abi.decode(_data, (string, string, uint256, uint256, uint256, uint256, uint256, uint256, address[], uint256[], uint256[]));

        require(_coverCurrencies.length > 0, "InsuranceProtocol: EMPTY_COVER_CURRENCIES");
        require(_coverCurrencies.length == _minCoverCurrenciesAmounts.length
            && _coverCurrencies.length == _maxCoverCurrenciesAmounts.length, "InsuranceProtocol: NOT_EQUALS_COVER_CURRENCIES_AMOUNTS");
        require(_minCoverInDays > 0, "InsuranceProtocol: MIN_COVER_UNALLOWED");
        require(_maxCoverInDays > 0, "InsuranceProtocol: MAX_COVER_UNALLOWED");

        uint256 id = products.counter.current();

        products.values[id].id = id;
        products.values[id].URI = _uri;
        products.values[id].name = _name;
        products.values[id].riskRatio = _riskRatio;
        products.values[id].basePremiumInPercent = _basePremiumInPercent;
        products.values[id].status = ModelProducts.ProductStatus.Active;
        products.values[id].utcProductStartDate = _utcProductStartDate; 
        products.values[id].utcProductEndDate = _utcProductEndDate;
        products.values[id].minCoverInDays = _minCoverInDays;
        products.values[id].maxCoverInDays = _maxCoverInDays;

        for (uint256 i = 0; i < _coverCurrencies.length; i++) { // add coverCurrencies
            ModelPools.PoolWithReserve memory pool = ICheckDotPoolFactory(insurancePoolFactoryAddress).getPool(_coverCurrencies[i]);

            require(pool.poolAddress != address(0), "InsuranceProtocol: POOL_DOESNT_EXISTS");
            products.values[id].coverCurrencies.push(_coverCurrencies[i]);
            products.values[id].coverCurrenciesPoolAddresses.push(pool.poolAddress);
            products.values[id].minCoverCurrenciesAmounts.push(_minCoverCurrenciesAmounts[i]);
            products.values[id].maxCoverCurrenciesAmounts.push(_maxCoverCurrenciesAmounts[i]);
        }
        products.counter.increment();
        emit ProductCreated(id);
    }

    function buyCover(uint256 _productId,
        address _coveredAddress,
        uint256 _coveredAmount,
        address _coverCurrency,
        uint256 _durationInDays,
        bool _useCDTs) external payable activatedProduct(_productId) {
        require(msg.sender != address(0), "EMPTY_SENDER");
        require(!Addresses.isContract(msg.sender), "FORBIDEN_CONTRACT");
        require(_coveredAddress != address(0), "EMPTY_COVER");
        ModelProducts.Product storage product = products.values[_productId];
        
        require(block.timestamp.add(_durationInDays.mul(86000)) <= product.utcProductEndDate, "PRODUCT_EXPIRED");
        require(_durationInDays >= product.minCoverInDays, "DURATION_TOO_SHORT");
        require(_durationInDays <= product.maxCoverInDays, "DURATION_MAX_EXCEEDED");
        require(product.coverCurrencyExists(_coverCurrency), "CURRENCY_NOT_COVERED");
        require(ICheckDotInsuranceRiskDataCalculator(insuranceRiskDataCalculatorAddress).coverIsSolvable(product.riskRatio, _coverCurrency, _coveredAmount), "NOT_SOLVABLE_COVER");
        
        uint256 totalCost = getCoverCost(product.id, _coverCurrency, _coveredAmount, _durationInDays);

        if (_useCDTs) {
            address cdtGouvernancetoken = IDAOProxy(address(this)).getGovernance();
            uint256 cdtCost = ICheckDotInsuranceRiskDataCalculator(insuranceRiskDataCalculatorAddress).getCostInCDT(totalCost, cdtGouvernancetoken);
            address cdtPoolAddress = poolFor(cdtGouvernancetoken);
            uint256 checkDotFees = cdtCost.div(2);
            uint256 newCost = cdtCost.sub(checkDotFees);

            TransferHelper.safeTransferFrom(cdtGouvernancetoken, msg.sender, address(this), checkDotFees); // send tokens to insuranceProtocol
            TransferHelper.safeTransferFrom(cdtGouvernancetoken, msg.sender, cdtPoolAddress, newCost); // send tokens to CDT pool
            ICheckDotPool(cdtPoolAddress).sync();
        } else {
            TransferHelper.safeTransferFrom(_coverCurrency, msg.sender, product.getCoverCurrencyPoolAddress(_coverCurrency), totalCost); // send tokens to pool
            ICheckDotPool(product.getCoverCurrencyPoolAddress(_coverCurrency)).sync();
        }
        uint256 tokenId = ICheckDotERC721InsuranceToken(insuranceTokenAddress).mintInsuranceToken(product.id, _coveredAddress, _durationInDays, totalCost, _coverCurrency, _coveredAmount, product.URI);

        emit PurchasedCover(tokenId, product.id, _coveredAmount, totalCost);
    }

    function claim(uint256 _insuranceTokenId, uint256 _claimAmount, string calldata _claimProperties) external {
        ICheckDotERC721InsuranceToken insuranceToken = ICheckDotERC721InsuranceToken(insuranceTokenAddress);
        
        require(insuranceToken.ownerOf(_insuranceTokenId) == msg.sender, "FORBIDEN");
        require(insuranceToken.coverIsAvailable(_insuranceTokenId), 'EXPIRED');

        ModelCovers.Cover memory cover = insuranceToken.getCover(_insuranceTokenId);
        ModelProducts.Product storage product = products.values[cover.productId];

        claims.values[_insuranceTokenId].claim.id = _insuranceTokenId;
        claims.values[_insuranceTokenId].claim.properties = _claimProperties;
        claims.values[_insuranceTokenId].claim.coveredAddress = cover.coveredAddress;
        claims.values[_insuranceTokenId].claim.poolAddress = product.getCoverCurrencyPoolAddress(cover.coveredAddress);
        claims.values[_insuranceTokenId].claim.coveredCurrency = msg.sender;
        claims.values[_insuranceTokenId].claim.amount = _claimAmount;
        claims.values[_insuranceTokenId].claim.status = ModelClaims.ClaimStatus.Approbation;

        insuranceToken.setClaim(_insuranceTokenId, _claimAmount, _claimProperties);

        emit ClaimCreated(_insuranceTokenId, cover.productId, _claimAmount);
    }

    function revokeExpiredCovers() external payable onlyOwner {
        ICheckDotERC721InsuranceToken(insuranceTokenAddress).revokeExpiredCovers();
    }

    //////////
    // Views
    //////////

    function getCoverCost(uint256 _productId, address _coveredCurrency, uint256 _coveredAmount, uint256 _durationInDays) public view returns (uint256) {
        ModelProducts.Product storage product = products.values[_productId];
        
        (
            /** Unused Parameter **/,
            uint256 cumulativePremiumInPercent,
            int256 poolCapacity,
            /** Unused Parameter **/
        ) = getProductCoverCurrencyDetails(product.id, _coveredCurrency);
        require(poolCapacity > int256(0) && poolCapacity > int256(_coveredAmount), "CURRENCY_CAPACITY_LIMIT_WAS_REACHED");

        uint256 premiumInPercent = product.basePremiumInPercent.add(cumulativePremiumInPercent);
        uint256 costOnOneYear = _coveredAmount.mul(premiumInPercent).div(100 ether);
        
        return costOnOneYear.mul(_durationInDays.mul(1 ether)).div(365 ether);
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
        results[0].coverCurrencies = new address[](product.coverCurrencies.length);
        results[0].coverCurrenciesPoolAddresses = new address[](product.coverCurrencies.length);
        results[0].minCoverCurrenciesAmounts = new uint256[](product.coverCurrencies.length);
        results[0].maxCoverCurrenciesAmounts = new uint256[](product.coverCurrencies.length);
        results[0].cumulativePremiumInPercents = new uint256[](product.coverCurrencies.length);
        results[0].coverCurrenciesCoveredAmounts = new uint256[](product.coverCurrencies.length);
        results[0].coverCurrenciesCapacities = new int256[](product.coverCurrencies.length);
        results[0].coverCurrenciesEnabled = new bool[](product.coverCurrencies.length);
        for (uint256 i = 0; i < product.coverCurrencies.length; i++) {
            
            (
                uint256 currentCoverCurrencyCoveredAmount,
                uint256 cumulativePremiumInPercent,
                int256 poolCapacity,
                // uint256 reserve unused
            ) = getProductCoverCurrencyDetails(product.id, product.coverCurrencies[i]);

            results[0].coverCurrencies[i] = product.coverCurrencies[i];
            results[0].coverCurrenciesPoolAddresses[i] = product.coverCurrenciesPoolAddresses[i];
            results[0].minCoverCurrenciesAmounts[i] = product.minCoverCurrenciesAmounts[i];
            results[0].maxCoverCurrenciesAmounts[i] = product.maxCoverCurrenciesAmounts[i];
            results[0].cumulativePremiumInPercents[i] = cumulativePremiumInPercent;
            results[0].coverCurrenciesCoveredAmounts[i] = currentCoverCurrencyCoveredAmount;
            results[0].coverCurrenciesCapacities[i] = poolCapacity;
            results[0].coverCurrenciesEnabled[i] = poolCapacity > 0;
        }
        return results[0];
    }

    function getProductCoverCurrencyDetails(uint256 _productId, address _coverCurrency) public view returns (uint256, uint256, int256, uint256) {
        ModelProducts.Product storage product = products.values[_productId];

        uint256 poolReserve = ICheckDotPool(product.getCoverCurrencyPoolAddress(_coverCurrency)).getReserves();
        uint256 currentCoverCurrencyCoveredAmount = ICheckDotInsuranceRiskDataCalculator(insuranceRiskDataCalculatorAddress).getActiveCoverAmountByCurrency(_coverCurrency);
        int256 signedCapacity = int256(poolReserve).sub(int256(currentCoverCurrencyCoveredAmount));
        uint256 capacity = signedCapacity > 0 ? uint256(signedCapacity) : 0;
        uint256 availablePercentage = signedCapacity > 0 ? uint256(100 ether).sub(uint256(capacity).mul(100 ether).div(poolReserve)) : 0;
        uint256 cumulativePremiumInPercent = availablePercentage.mul(3 ether).div(100 ether); // 3% addable
        return (currentCoverCurrencyCoveredAmount, cumulativePremiumInPercent, signedCapacity, poolReserve);
    }

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

}