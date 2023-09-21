// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../interfaces/IERC20.sol";
import "../../interfaces/IOracle.sol";
import "../../interfaces/ICheckDotInsuranceCovers.sol";
import "../../interfaces/IDex.sol";
import "../../utils/SafeMath.sol";
import "../../utils/SignedSafeMath.sol";

import "../../interfaces/IOwnedProxy.sol";

contract CheckDotInsuranceCalculator is IOracle {
    using SafeMath for uint;

    string private constant INSURANCE_PRODUCTS = "INSURANCE_PRODUCTS";
    string private constant INSURANCE_COVERS = "INSURANCE_COVERS";
    string private constant CHECKDOT_TOKEN = "CHECKDOT_TOKEN";
    string private constant DEX_FACTORY_ADDRESS = "DEX_FACTORY_ADDRESS";

    // -------- V1 --------

    /* Map of Essentials Addresses */
    mapping(string => address) private protocolAddresses;

    mapping(address => uint256) totalCoveredAmounts;
    
    // --------------------

    function initialize(bytes memory _data) external onlyOwner {
        (
            address _insuranceProductsAddress,
            address _insuranceCoversAddress,
            address _checkDotTokenAddress,
            address _dexFactory,
            address _stableCoin1,
            address _stableCoin2
        ) = abi.decode(_data, (address, address, address, address, address, address));

        protocolAddresses[INSURANCE_PRODUCTS] = _insuranceProductsAddress;
        protocolAddresses[INSURANCE_COVERS] = _insuranceCoversAddress;
        protocolAddresses[CHECKDOT_TOKEN] = _checkDotTokenAddress;

        protocolAddresses[DEX_FACTORY_ADDRESS] = _dexFactory;// 0x10ED43C718714eb63d5aA57B78B54704E256024E; // PancakeSwap V2
        
        protocolAddresses["STABLECOIN1"] = _stableCoin1;//address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // BUSD
        protocolAddresses["STABLECOIN2"] = _stableCoin2;//address(0x55d398326f99059fF775485246999027B3197955); // USDT
    }

    modifier onlyOwner {
        require(msg.sender == IOwnedProxy(address(this)).getOwner(), "Calc: FORBIDDEN");
        _;
    }

    function setTotalCoveredAmountFromCurrency(address _currency, uint256 _amount) public onlyOwner {
        totalCoveredAmounts[_currency] = _amount;
    }

    function getTotalCoveredAmountFromCurrency(address _currency) public view returns (uint256) {
        uint256 coversLength = ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).getCoversCount();
        uint256 totalCoveredAmount = 0;
        for (uint256 i = 0; i < coversLength; i++) {
            (
                address coveredCurrency,
                uint256 coveredAmount,
                uint256 status
            ) = ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).getLightCoverInformation(i);
            if (coveredCurrency == _currency && status == 1) { // actives covers
                totalCoveredAmount = totalCoveredAmount.add(coveredAmount);
            }
        }
        return totalCoveredAmount;
    }

    function coverIsSolvable(uint256 _productId, uint256 _productRiskRatio, address _coverCurrency, uint256 _newCoverAmount) external view returns (bool) {
        PoolInformations memory pool = ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).getPool(_coverCurrency);

        if (_newCoverAmount < 100 ether || _newCoverAmount > 1000000 ether) { // OUT_OFF_LIMITS
            return false;
        }

        // Check for (De-peg risk product) if the coverCurrency is the Product.
        if (_productId == 5 && _coverCurrency == address(0x55d398326f99059fF775485246999027B3197955)) { // USDT Peg
            return false;
        }
        if (_productId == 6 && _coverCurrency == address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d)) { // USDC Peg
            return false;
        }
        if (_productId == 7 && _coverCurrency == address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)) { // BUSD Peg
            return false;
        }

        uint256 totalActiveCoveredAmount = getTotalCoveredAmountFromCurrency(_coverCurrency);
        uint256 solvabilityRatio = totalActiveCoveredAmount.add(_newCoverAmount).mul(1 ether).div(pool.reserve);
        return (solvabilityRatio < _productRiskRatio);
    }

    function getSolvableCoverAmount(uint256 _productRiskRatio, address _coverCurrency) public view returns (uint256) {
        if (_coverCurrency == protocolAddresses[CHECKDOT_TOKEN]) { // excluding CDT Pool
            return 0;
        }
        uint256 ratio = _productRiskRatio > 4 ether ? 4 ether : _productRiskRatio;
        uint256 totalActiveCoveredAmount = getTotalCoveredAmountFromCurrency(_coverCurrency);
        PoolInformations memory pool = ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).getPool(_coverCurrency);

        if (pool.reserve.mul(ratio).div(1 ether) < totalActiveCoveredAmount) {
            return 0;
        }
        return (pool.reserve.mul(ratio).div(1 ether).sub(totalActiveCoveredAmount));
    }

    function getTotalSolvableCoverAmountFromProductRiskRatio(uint256 _productRiskRatio) public view returns (uint256) {
        PoolInformations[] memory pools = ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).getPools(int256(0), int256(ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).getPoolsLength()));
        uint256 totalCoverableAmountInUSD = 0;
        for (uint256 i = 0; i < pools.length; i++) {
            uint256 coverableAmount = getSolvableCoverAmount(_productRiskRatio, pools[i].token);
            totalCoverableAmountInUSD = totalCoverableAmountInUSD.add(getTokenPriceInUSD(pools[i].token).mul(coverableAmount).div(1 ether));
        }
        return totalCoverableAmountInUSD;
    }

    function getSolvabilityRatio() public view returns (uint256) { // For JS (Ratio / (10**18))
        (uint256 ratio,,) = getSolvability();
        return (ratio);
    }

    function getSCRPercent() public view returns (uint256) { // For JS (SCRPercent / (10**18))
        (, uint256 SCRPercent,) = getSolvability();
        return (SCRPercent);
    }

    function getSCRSize() public view returns (uint256) { // For JS (SCRSize / (10**18))
        (,, uint256 SCRSize) = getSolvability();
        return (SCRSize);
    }

    function getSolvability() public view returns(uint256, uint256, uint256) {
        PoolInformations[] memory pools = ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).getPools(int256(0), int256(ICheckDotInsuranceCovers(protocolAddresses[INSURANCE_COVERS]).getPoolsLength()));
        uint256 totalReserve = 0;
        uint256 totalActiveCoveredAmount = 0;
        for (uint256 i = 0; i < pools.length; i++) {
            totalReserve = totalReserve.add(getTokenPriceInUSD(pools[i].token).mul(pools[i].reserve).div(1 ether));
            uint256 currentTotalActiveCoveredAmount = getTotalCoveredAmountFromCurrency(pools[i].token);
            
            totalActiveCoveredAmount = totalActiveCoveredAmount.add(getTokenPriceInUSD(pools[i].token).mul(currentTotalActiveCoveredAmount).div(1 ether));
        }
        uint256 solvabilityRatio = totalActiveCoveredAmount.mul(1 ether).div(totalReserve); // multiplication 1 ether pour decaler les decimals.
        uint256 SCRPercent = uint256(4 ether).sub(solvabilityRatio > 4 ether ? 4 ether : solvabilityRatio).mul(100);
        uint256 SCRSize = totalReserve.mul(1 ether).div(SCRPercent).mul(100); // multiplication 1 ether pour decaler les decimals.

        // exemple: 95000000000000000 (SolvabilityRatio=0.095), 390400000000000000000 (SCR=390.4), 269040200000000000000 (SCRSize=269.402)
        return (solvabilityRatio > 4 ether ? 4 ether : solvabilityRatio, SCRPercent, SCRSize);
    }

    function getClaimPrice(address _coveredCurrency, uint256 _claimAmount) public view returns (uint256) {
        uint256 claimFeesInCoveredCurrency = _claimAmount.mul(1).div(100); // 1% fee
        return convertCost(claimFeesInCoveredCurrency, _coveredCurrency, protocolAddresses[CHECKDOT_TOKEN]);
    }

    function convertCost(uint256 _costIn, address _in, address _out) public view returns (uint256) {
        if (_in != _out) {
            uint256 outTokenPriceIn = getTokenPriceOut(_in, _out);

            require(outTokenPriceIn != 0, "CDT_ORACLE_OFFLINE");
            return _costIn.mul(1 ether).div(outTokenPriceIn);
        } else {
            return _costIn;
        }
    }

    function getTokenPriceInUSD(address _token) public view returns (uint256) {
        return getTokenPriceOut(_token != protocolAddresses["STABLECOIN1"] ? protocolAddresses["STABLECOIN1"] : protocolAddresses["STABLECOIN2"], _token);
    }

    function getTokenPriceOut(address _in, address _out) public view returns (uint256) {
        address[] memory values =  new address[](2);

        values[0] = _out;
        values[1] = _in;
        try IDex(protocolAddresses[DEX_FACTORY_ADDRESS]).getAmountsOut(1 ether, values) returns (uint256[] memory result) {
            return result[1];
        } catch (bytes memory /*lowLevelData*/) {
            return (0);  // Will not get here
        }
    }

    /**
     * @dev Returns the Insurance Protocol address.
     */
    function getInsuranceProductsAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_PRODUCTS];
    }

    /**
     * @dev Returns the Insurance Pool Factory address.
     */
    function getInsuranceCoversAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_COVERS];
    }

}