// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../utils/SafeMath.sol";
import "../../utils/SignedSafeMath.sol";
import "../../utils/TransferHelper.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/ICheckDotPool.sol";
import "../../interfaces/IDAOProxy.sol";
import "../../interfaces/ICheckDotInsuranceStore.sol";
import "../../structs/ModelClaims.sol";
import "../../structs/ModelPools.sol";

import "./CheckDotPool.sol";

import "../../../../../CheckDot.DAOProxyContract/contracts/interfaces/IOwnedProxy.sol";

contract CheckDotPoolFactory {
    using SafeMath for uint;
    using SignedSafeMath for int256;
    using ModelClaims for ModelClaims.Claim;
    using ModelClaims for ModelClaims.ClaimWithParticipators;
    using ModelPools for ModelPools.Pool;
    using ModelPools for ModelPools.PoolWithReserve;

    event PoolCreated(address poolAddress, address token);
    event ContributionAdded(address from, address poolAddress, uint256 liquidity);
    event ContributionRemoved(address from, address poolAddress, uint256 liquidity);
    event ClaimCreated(address token, address poolAddress, uint256 id, address claimer, uint256 amount);
    event Paidout(address token, address poolAddress, uint256 id, address claimer, uint256 amount);

    bytes32 private constant INIT_CODE_POOL_HASH = keccak256(abi.encodePacked(type(CheckDotPool).creationCode));

    mapping(uint256 => ModelClaims.ClaimWithParticipators) private claims;
    uint256[] private claimIds;

    mapping(address => ModelPools.Pool) private pools;
    ModelPools.Pool[] private poolList;

    mapping(address => mapping(address => uint256)) poolsContributionsTimestamps;

    address private store;
    address private insuranceProtocolAddress;
    address private insuranceTokenAddress;
    address private insuranceRiskDataCalculatorAddress;

    function initialize(bytes memory _data) external onlyOwner {
        (address _storeAddress) = abi.decode(_data, (address));

        require(_storeAddress != address(0), "STORE_EMPTY");
        store = _storeAddress;
        insuranceProtocolAddress = ICheckDotInsuranceStore(store).getAddress("INSURANCE_PROTOCOL");
        insuranceTokenAddress = ICheckDotInsuranceStore(store).getAddress("INSURANCE_TOKEN");
        insuranceRiskDataCalculatorAddress = ICheckDotInsuranceStore(store).getAddress("INSURANCE_RISK_DATA_CALCULATOR");
        
        address cdtGouvernancetoken = IDAOProxy(address(this)).getGovernance(); // Creating Default CDT Pool
        if (pools[cdtGouvernancetoken].poolAddress == address(0)) {
            createPool(cdtGouvernancetoken);
        }
    }

    modifier poolExist(address _token) {
        require(poolExists(_token), "Entity should be initialized");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == IOwnedProxy(address(this)).getOwner(), "Factory: FORBIDDEN");
        _;
    }

    modifier onlyInsuranceProtocol {
        require(msg.sender == insuranceProtocolAddress, "Factory: FORBIDDEN");
        _;
    }

    function getInitCodePoolHash() external pure returns (bytes32) {
        return INIT_CODE_POOL_HASH;
    }

    /**
     * @dev Returns the Store address.
     */
    function getStoreAddress() external view returns (address) {
        return store;
    }

    /**
     * @dev Returns the Insurance Protocol address.
     */
    function getInsuranceProtocolAddress() external view returns (address) {
        return insuranceProtocolAddress;
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

    function createPool(address _token) public onlyOwner returns (address pool) {
        require(_token != address(0), 'ZERO_ADDRESS');
        require(pools[_token].poolAddress == address(0), 'ALREADY_EXISTS');
        require(uint256(IERC20(_token).decimals()) == 18, 'ONLY_18_DECIMALS_TOKENS');

        bytes memory bytecode = type(CheckDotPool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token));
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ICheckDotPool(pool).initialize(_token);
        pools[_token].token = _token;
        pools[_token].poolAddress = pool;
        poolList.push(pools[_token]);
        emit PoolCreated(pool, _token);
    }

    function contribute(address _token, address _from, uint256 _amountOfTokens) external poolExist(_token)
        returns (uint256 liquidity) {    
        require(_amountOfTokens > 0, "amount should be > 0");
        require(_from != address(0), "not valid from");
        ModelPools.Pool memory pool = pools[_token];

        require(poolsContributionsTimestamps[pool.poolAddress][_from] == 0, "ALREADY_HAVE_CONTRIBUTION");
        poolsContributionsTimestamps[pool.poolAddress][_from] = block.timestamp;
        
        TransferHelper.safeTransferFrom(_token, _from, pool.poolAddress, _amountOfTokens); // send tokens to pool
        liquidity = ICheckDotPool(pool.poolAddress).mint(_from);

        emit ContributionAdded(_from, pool.poolAddress, liquidity);
    }

    function uncontribute(address _token, address _to, uint256 _amountOfliquidityTokens) external poolExist(_token)
        returns (uint256 amount) {
        require(_amountOfliquidityTokens > 0, "amount should be > 0");
        require(_to != address(0), "not valid to");
        ModelPools.Pool memory pool = pools[_token];

        require(poolsContributionsTimestamps[pool.poolAddress][_to] != 0, "NO_CONTRIBUTION");
        require(poolsContributionsTimestamps[pool.poolAddress][_to].add(uint256(86400).mul(15)) < block.timestamp, "15_DAYS_LOCKED_CONTRIBUTION");
        poolsContributionsTimestamps[pool.poolAddress][_to] = 0;

        IERC20(pool.poolAddress).transferFrom(msg.sender, pool.poolAddress, _amountOfliquidityTokens); // send liquidity to pool
        amount = ICheckDotPool(pool.poolAddress).burn(_to);

        emit ContributionRemoved(_to, pool.poolAddress, amount);
    }

    function claim(address _token, uint256 _id, uint256 _amount, address _claimer) onlyInsuranceProtocol poolExist(_token) external returns (bool) {
        require(claims[_id].claim.coveredAddress == address(0), "CheckDotPool: ALREADY_EXISTS");
        ModelPools.Pool memory pool = pools[_token];

        claims[_id].claim.id = _id;
        claims[_id].claim.coveredCurrency = _token;
        claims[_id].claim.poolAddress = pool.poolAddress;
        claims[_id].claim.amount = _amount;
        claims[_id].claim.coveredAddress = _claimer;
        claims[_id].claim.utcStartVote = block.timestamp;
        claims[_id].claim.utcEndVote = block.timestamp.add(86400); // one day
        claimIds.push(_id);
        emit ClaimCreated(_token, pool.poolAddress, _id, _claimer, _amount);
        return true;
    }

    function payout(uint256 _id) onlyInsuranceProtocol external returns (bool approved) {
        require(claims[_id].claim.coveredAddress != address(0), "CheckDotPool: FORBIDDEN");
        require(claims[_id].claim.utcStartVote < block.timestamp
            && claims[_id].claim.utcEndVote < block.timestamp, "CheckDotPool: VOTE_INPROGRESS");
        require(claims[_id].claim.status == ModelClaims.ClaimStatus.Vote, "CheckDotPool: ALREADY_PAYOUT");
        claims[_id].claim.status = ModelClaims.ClaimStatus.Paid;

        ModelPools.Pool memory pool = pools[claims[_id].claim.poolAddress];
        
        if (approved = claims[_id].claim.totalApproved > claims[_id].claim.totalUnapproved) {
            ICheckDotPool(pool.poolAddress).refund(claims[_id].claim.coveredAddress, claims[_id].claim.amount);
            emit Paidout(pool.token, pool.poolAddress, _id, claims[_id].claim.coveredAddress, claims[_id].claim.amount);
        }
    }

    function vote(uint256 _id, bool approve) external {
        require(claims[_id].claim.id == _id, "CheckDotPool: FORBIDDEN");
        require(claims[_id].claim.utcStartVote < block.timestamp
            && claims[_id].claim.utcEndVote > block.timestamp, "CheckDotPool: VOTE_FINISHED");
        require(claims[_id].participators[msg.sender] == address(0), "CheckDotPool: ALREADY_VOTED");
        IERC20 cdtGouvernancetoken = IERC20(IDAOProxy(address(this)).getGovernance());
        uint256 votes = cdtGouvernancetoken.balanceOf(msg.sender) - (1**cdtGouvernancetoken.decimals());
        require(votes >= 1, "Proxy: INSUFFISANT_POWER");
        if (approve) {
            claims[_id].claim.totalApproved = claims[_id].claim.totalApproved.add(votes);
        } else {
            claims[_id].claim.totalUnapproved = claims[_id].claim.totalUnapproved.add(votes);
        }
        claims[_id].participators[msg.sender] = msg.sender;
    }

    //////////
    // Views
    //////////

    function getPools(int256 page, int256 pageSize) public view returns (ModelPools.PoolWithReserve[] memory) {
        uint256 poolLength = getPoolsLength();
        int256 queryStartPoolIndex = int256(poolLength).sub(pageSize.mul(page.add(1))).add(pageSize);
        require(queryStartPoolIndex >= 0, "Out of bounds");
        int256 queryEndPoolIndex = queryStartPoolIndex.sub(pageSize);
        if (queryEndPoolIndex < 0) {
            queryEndPoolIndex = 0;
        }
        int256 currentPoolIndex = queryStartPoolIndex;
        require(uint256(currentPoolIndex) <= poolLength, "Out of bounds");
        ModelPools.PoolWithReserve[] memory results = new ModelPools.PoolWithReserve[](uint256(currentPoolIndex - queryEndPoolIndex));
        uint256 index = 0;

        for (currentPoolIndex; currentPoolIndex > queryEndPoolIndex; currentPoolIndex--) {
            ModelPools.Pool memory pool = poolList[uint256(currentPoolIndex).sub(1)];
            results[index].token = pool.token;
            results[index].poolAddress = pool.poolAddress;
            results[index].reserve = ICheckDotPool(pool.poolAddress).getReserves();
            index++;
        }
        return results;
    }

    function getPool(address _token) poolExist(_token) public view returns (ModelPools.PoolWithReserve memory) {
        ModelPools.PoolWithReserve[] memory results = new ModelPools.PoolWithReserve[](1);
        ModelPools.Pool memory pool = pools[_token];
        
        results[0].token = pool.token;
        results[0].poolAddress = pool.poolAddress;
        results[0].reserve = ICheckDotPool(pool.poolAddress).getReserves();
        return results[0];
    }

    function getPoolsLength() public view returns (uint256) {
        return poolList.length;
    }

    function poolExists(address _token) public view returns(bool) {
        return pools[_token].poolAddress != address(0);
    }

    function poolAddress(address _token) public view returns(address) {
        return pools[_token].poolAddress;
    }

    function getClaim(uint256 _id) public view returns (ModelClaims.Claim memory) {
        return claims[_id].claim;
    }

    function getClaims(int256 page, int256 pageSize) public view returns (ModelClaims.Claim[] memory) {
        uint256 claimLength = getClaimsLength();
        int256 queryStartIndex = int256(claimLength).sub(pageSize.mul(page)).add(pageSize).sub(1);
        require(queryStartIndex >= 0, "Out of bounds");
        int256 queryEndIndex = queryStartIndex.sub(pageSize);
        if (queryEndIndex < 0) {
            queryEndIndex = 0;
        }
        int256 currentIndex = queryStartIndex;
        require(uint256(currentIndex) <= claimLength.sub(1), "Out of bounds");
        ModelClaims.Claim[] memory results = new ModelClaims.Claim[](uint256(currentIndex - queryEndIndex));
        uint256 index = 0;

        for (currentIndex; currentIndex > queryEndIndex; currentIndex--) {
            uint256 currentIndexAsUnsigned = uint256(currentIndex);
            if (currentIndexAsUnsigned <= claimLength.sub(1)) {
                results[index] = claims[claimIds[currentIndexAsUnsigned]].claim;
            }
            index++;
        }
        return results;
    }

    function getClaimsLength() public view returns (uint256) {
        return claimIds.length;
    }

}