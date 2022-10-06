// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../interfaces/IERC20.sol";
import "../../interfaces/IDAOProxy.sol";
import "../../interfaces/ICheckDotInsuranceCovers.sol";
import "../../interfaces/ICheckDotInsuranceCalculator.sol";
import "../../utils/Counters.sol";
import "../../utils/SafeMath.sol";
import "../../utils/SignedSafeMath.sol";
import "../../utils/TransferHelper.sol";
import "../../utils/Addresses.sol";

import "../../../../../CheckDot.DAOProxyContract/contracts/interfaces/IOwnedProxy.sol";

struct Object {
    mapping(string => address) a;
    mapping(string => uint256) n;
    mapping(string => string) s;
}

struct ProductInformations {
    uint256 id;
    string  name;
    string  riskType;
    string  uri;
    uint256 status;
    uint256 riskRatio;
    uint256 basePremiumInPercent;
    uint256 minCoverInDays;
    uint256 maxCoverInDays;
}

enum ProductStatus {
    NotSet,       // 0 |
    Active,       // 1 ===|
    Paused,       // 2 ===|
    Canceled      // 3 |
}

contract CheckDotInsuranceProducts {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using Counters for Counters.Counter;

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

    string private constant INSURANCE_COVERS = "INSURANCE_COVERS";
    string private constant INSURANCE_CALCULATOR = "INSURANCE_CALCULATOR";
    string private constant CHECKDOT_TOKEN = "CHECKDOT_TOKEN";

    bool internal locked;

    // V1 DATA

    /* Map of Essentials Addresses */
    mapping(string => address) private protocolAddresses;

    struct Products {
        mapping(uint256 => Object) data;
        Counters.Counter counter;
    }

    Products private products;

    // END V1

    function initialize(bytes memory _data) external onlyOwner {
        (
            address _insuranceCoversAddress,
            address _insuranceCalculatorAddress
        ) = abi.decode(_data, (address, address));

        protocolAddresses[INSURANCE_COVERS] = _insuranceCoversAddress;
        protocolAddresses[INSURANCE_CALCULATOR] = _insuranceCalculatorAddress;
        protocolAddresses[CHECKDOT_TOKEN] = IDAOProxy(address(this)).getGovernance();
    }

    modifier onlyOwner {
        require(msg.sender == IOwnedProxy(address(this)).getOwner(), "FORBIDDEN");
        _;
    }

    modifier productExists(uint256 productId) {
        require(bytes(products.data[productId].s["name"]).length != 0, "DOESNT_EXISTS");
        _;
    }

    modifier activatedProduct(uint256 productId) {
        require(products.data[productId].n["status"] == uint256(ProductStatus.Active), "Product is paused");
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

    function getInsuranceCoversAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_COVERS];
    }

    function getInsuranceCalculatorAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_CALCULATOR];
    }
   
    function createProduct(uint256 _id, bytes memory _data) external onlyOwner {
        (
            string memory _name,
            string memory _riskType,
            string memory _uri,
            uint256 _riskRatio,
            uint256 _basePremiumInPercent,
            uint256 _minCoverInDays,
            uint256 _maxCoverInDays
        ) = abi.decode(_data, (string, string, string, uint256, uint256, uint256, uint256));
        require(_minCoverInDays > 0, "MIN_COVER_UNALLOWED");
        require(_maxCoverInDays > 0, "MAX_COVER_UNALLOWED");
        require(_id <= products.counter.current(), "NOT_VALID_PRODUCT_ID");

        uint256 id = _id < products.counter.current() ? _id : products.counter.current();

        products.data[id].n["id"] = id;
        products.data[id].s["riskType"] = _riskType;
        products.data[id].s["uri"] = _uri;
        products.data[id].s["name"] = _name;
        products.data[id].n["riskRatio"] = _riskRatio;
        products.data[id].n["basePremiumInPercent"] = _basePremiumInPercent;
        products.data[id].n["status"] = uint256(ProductStatus.Active);
        products.data[id].n["minCoverInDays"] = _minCoverInDays;
        products.data[id].n["maxCoverInDays"] = _maxCoverInDays;
        if (id >= products.counter.current()) {
            products.counter.increment();
        }
        emit ProductCreated(id);
    }

    function buyCover(uint256 _productId,
        address _coveredAddress,
        uint256 _coveredAmount,
        address _coverCurrency,
        uint256 _durationInDays,
        address _payIn) external payable noReentrant activatedProduct(_productId) noContract {
        require(isValidBuy(_productId, _coveredAddress, _coveredAmount, _coverCurrency, _durationInDays, _payIn), "UNAVAILABLE");
        
        Object storage product = products.data[_productId];

        uint256 totalCostInCoverCurrency = _payCover(_productId, _coveredAmount, _coverCurrency, _durationInDays, _payIn);
        uint256 tokenId = ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).mintInsuranceToken(product.n["id"], _coveredAddress, _durationInDays, totalCostInCoverCurrency, _coverCurrency, _coveredAmount, product.s["uri"]);

        emit PurchasedCover(tokenId, product.n["id"], _coveredAmount, totalCostInCoverCurrency);
    }

    function isValidBuy(uint256 _productId,
        address _coveredAddress,
        uint256 _coveredAmount,
        address _coverCurrency,
        uint256 _durationInDays,
        address _payIn) public view returns (bool) {
        require(_coveredAddress != address(0), "EMPTY_COVER");
        require(block.timestamp.add(_durationInDays.mul(86400)) <= products.data[_productId].n["utcProductEndDate"], "PRODUCT_EXPIRED");
        require(_durationInDays >= products.data[_productId].n["minCoverInDays"], "DURATION_TOO_SHORT");
        require(_durationInDays <= products.data[_productId].n["maxCoverInDays"], "DURATION_MAX_EXCEEDED");
        require(ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).getPool(_payIn).token != address(0), "PAY_POOL_DOESNT_EXIST");
        require(_coverCurrency != protocolAddresses[CHECKDOT_TOKEN], "CDT_ISNT_COVER_CURRENCY");
        require(ICheckDotInsuranceCalculator(protocolAddresses[INSURANCE_CALCULATOR]).coverIsSolvable(products.data[_productId].n["id"], products.data[_productId].n["riskRatio"], _coverCurrency, _coveredAmount), "NOT_SOLVABLE_COVER");
        return true;
    }

    function _payCover(uint256 _productId,
        uint256 _coveredAmount,
        address _coverCurrency,
        uint256 _durationInDays,
        address _payIn) internal returns (uint256) {
        uint256 totalCostInCoverCurrency = getCoverCost(products.data[_productId].n["id"], _coverCurrency, _coveredAmount, _durationInDays);
        uint256 payCost = ICheckDotInsuranceCalculator(protocolAddresses[INSURANCE_CALCULATOR]).convertCost(totalCostInCoverCurrency, _coverCurrency, _payIn);
        uint256 fees = payCost.div(100).mul(2); // 2%

        require(IERC20(_payIn).balanceOf(msg.sender) >= payCost, "INSUFISANT_BALANCE");
        require(IERC20(_payIn).allowance(msg.sender, address(this)) >= payCost, "INSUFISANT_ALLOWANCE");

        TransferHelper.safeTransferFrom(_payIn, msg.sender, protocolAddresses[INSURANCE_COVERS], payCost.sub(fees)); // send 98% tokens to pool
        ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).sync(_payIn); // Synchronization of the reserve for distribution to the holders.

        TransferHelper.safeTransferFrom(_payIn, msg.sender, protocolAddresses[INSURANCE_COVERS], fees); // send fees to pool
        ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).addInsuranceProtocolFees(_payIn, IOwnedProxy(address(this)).getOwner()); // associate the fees to the owner
        return totalCostInCoverCurrency;
    }

    //////////
    // Views
    //////////

    function getCoverCost(uint256 _productId, address _coverCurrency, uint256 _coveredAmount, uint256 _durationInDays) public view returns (uint256) {
        (
            /** Unused Parameter **/,
            uint256 cumulativePremiumInPercent,
            /** Unused Parameter **/,
            /** Unused Parameter **/
        ) = getCoverCurrencyDetails(_coverCurrency);

        uint256 premiumInPercent = products.data[_productId].n["basePremiumInPercent"].add(cumulativePremiumInPercent);
        uint256 costOnOneYear = _coveredAmount.mul(premiumInPercent).div(100 ether);
        
        return costOnOneYear.mul(_durationInDays.mul(1 ether)).div(365 ether);
    }

    function getProductLength() public view returns (uint256) {
        return products.counter.current();
    }

    function getProductDetails(uint256 _id) public view returns (ProductInformations memory) {
        ProductInformations[] memory results = new ProductInformations[](1);
        Object storage product = products.data[_id];
        
        results[0].id = product.n["id"];
        results[0].name = product.s["name"];
        results[0].uri = product.s["uri"];
        results[0].status = product.n["status"];
        results[0].riskRatio = product.n["riskRatio"];
        results[0].basePremiumInPercent = product.n["basePremiumInPercent"];
        results[0].minCoverInDays = product.n["minCoverInDays"];
        results[0].maxCoverInDays = product.n["maxCoverInDays"];
        return results[0];
    }

    function getCoverCurrencyDetails(address _coverCurrency) public view returns (uint256, uint256, int256, uint256) {
        uint256 poolReserve = ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).getPool(_coverCurrency).reserve;
        uint256 currentCoverCurrencyCoveredAmount = ICheckDotInsuranceCalculator(protocolAddresses[INSURANCE_CALCULATOR]).getTotalCoveredAmountFromCurrency(_coverCurrency);
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
        products.data[_productId].n["status"] = uint256(ProductStatus.Paused);
    }

    function activeProduct(uint256 _productId) external onlyOwner {
        products.data[_productId].n["status"] = uint256(ProductStatus.Active);
    }

    function cancelProduct(uint256 _productId) external onlyOwner {
        products.data[_productId].n["status"] = uint256(ProductStatus.Canceled);
    }

}