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

import "../../DaoProxy/interfaces/IOwnedProxy.sol";

struct Object {
    mapping(string => address) a;
    mapping(string => uint256) n;
    mapping(string => string) s;
}

contract CheckDotInsuranceProducts {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using Counters for Counters.Counter;

    event PurchasedCover(uint256 coverId, uint256 productId, uint256 coveredAmount, uint256 premiumCost);

    string private constant INSURANCE_COVERS = "INSURANCE_COVERS";
    string private constant INSURANCE_CALCULATOR = "INSURANCE_CALCULATOR";
    string private constant CHECKDOT_TOKEN = "CHECKDOT_TOKEN";

    bool internal locked;

    // V1 DATA

    /* Map of Essentials Addresses */
    mapping(string => address) private protocolAddresses;

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

    function buyCover(bytes memory _productData,
        address _coveredAddress,
        uint256 _coveredAmount,
        address _coverCurrency,
        uint256 _durationInDays,
        address _payIn) external payable noReentrant noContract {
        (
            uint256 _productId,
            /*uint256  _riskRatio */,
            uint256 _basePremiumInPercent,
            string memory _uri
        ) = abi.decode(_productData, (uint256, uint256, uint256, string));

        require(isValidBuy(_coveredAddress, _durationInDays, _payIn), "UNAVAILABLE");

        uint256 totalCostInCoverCurrency = _payCover(_basePremiumInPercent, _coveredAmount, _coverCurrency, _durationInDays, _payIn);
        uint256 tokenId = ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).mintInsuranceToken(_productId, _coveredAddress, _durationInDays, totalCostInCoverCurrency, _coverCurrency, _coveredAmount, _uri);

        emit PurchasedCover(tokenId, _productId, _coveredAmount, totalCostInCoverCurrency);
    }

    function isValidBuy(address _coveredAddress,
        uint256 _durationInDays,
        address _payIn) public view returns (bool) {
        require(_coveredAddress != address(0), "EMPTY_COVER");
        require(_durationInDays >= 1, "DURATION_TOO_SHORT");
        require(ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).getPool(_payIn).token != address(0), "PAY_POOL_DOESNT_EXIST");
        return true;
    }

    // checked by front-end and if user order the cover isn't valid
    function protocolIsSolvable(uint256 _coveredAmount,
        address _coverCurrency,
        uint256 _riskRatio) public view returns (bool) {
        // convert the value of the covered currency amount in CDT
        uint256 coverAmountInCDT = ICheckDotInsuranceCalculator(protocolAddresses[INSURANCE_CALCULATOR]).convertCostPassingPerWrappedToken(_coveredAmount, _coverCurrency, protocolAddresses[CHECKDOT_TOKEN]);
        // check if CDT pool support the new cover
        return ICheckDotInsuranceCalculator(protocolAddresses[INSURANCE_CALCULATOR]).coverIsSolvable(0, _riskRatio, protocolAddresses[CHECKDOT_TOKEN], coverAmountInCDT);
    }

    function _payCover(uint256 _basePremiumInPercent,
        uint256 _coveredAmount,
        address _coverCurrency,
        uint256 _durationInDays,
        address _payIn) internal returns (uint256) {
        uint256 totalCostInCoverCurrency = getCoverCost(_basePremiumInPercent, _coveredAmount, _durationInDays);
        uint256 payCost = ICheckDotInsuranceCalculator(protocolAddresses[INSURANCE_CALCULATOR]).convertCostPassingPerWrappedToken(totalCostInCoverCurrency, _coverCurrency, _payIn);
        uint256 fees = payCost.div(100).mul(2); // 2%

        if (_payIn == protocolAddresses[CHECKDOT_TOKEN]) {
            fees = payCost.div(2); // 50% of the fees for the project when is paid in CDT
        }
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

    function getCoverCost(uint256 _basePremiumInPercent, uint256 _coveredAmount, uint256 _durationInDays) public pure returns (uint256) {
        uint256 costOnOneYear = _coveredAmount.mul(_basePremiumInPercent).div(100 ether);
        
        return costOnOneYear.mul(_durationInDays.mul(1 ether)).div(365 ether);
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

}