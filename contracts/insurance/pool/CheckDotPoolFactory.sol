// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../utils/SafeMath.sol";
import "../../utils/SignedSafeMath.sol";
import "../../utils/TransferHelper.sol";
import "../../utils/Counters.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/ICheckDotPool.sol";
import "../../interfaces/IDAOProxy.sol";
import "../../interfaces/ICheckDotInsuranceStore.sol";
import "../../interfaces/ICheckDotInsuranceRiskDataCalculator.sol";
import "../../interfaces/ICheckDotERC721InsuranceToken.sol";
import "../../structs/ModelClaims.sol";
import "../../structs/ModelPools.sol";

import "./CheckDotPool.sol";

import "../../../../../CheckDot.DAOProxyContract/contracts/interfaces/IOwnedProxy.sol";

contract CheckDotPoolFactory {
    using SafeMath for uint;
    using SignedSafeMath for int256;
    using ModelClaims for ModelClaims.Claim;
    using ModelClaims for ModelClaims.Vote;
    using ModelClaims for ModelClaims.ClaimWithParticipators;
    using ModelPools for ModelPools.Pool;
    using ModelPools for ModelPools.PoolWithReserve;
    using Counters for Counters.Counter;

    event PoolCreated(address poolAddress, address token);
    event ContributionAdded(address from, address poolAddress, uint256 liquidity);
    event ContributionRemoved(address from, address poolAddress, uint256 liquidity);

    event ClaimCreated(uint256 id, uint256 productId, uint256 coverId, uint256 amount);    
    event ClaimUpdated(uint256 id, uint256 productId, uint256 coverId);
    
    uint256 private constant VERSION = 1;
    bytes32 private constant INIT_CODE_POOL_HASH = keccak256(abi.encodePacked(type(CheckDotPool).creationCode));
    uint256 private constant MINIMUM_CLAIM_REWARDS = 10**3;
    string  private constant STORE = "STORE";
    string  private constant INSURANCE_PROTOCOL = "INSURANCE_PROTOCOL";
    string  private constant INSURANCE_TOKEN = "INSURANCE_TOKEN";
    string  private constant INSURANCE_RISK_DATA_CALCULATOR = "INSURANCE_RISK_DATA_CALCULATOR";
    string  private constant CHECKDOT_TOKEN = "CHECKDOT_TOKEN";

    bool internal locked;

    // V1 DATA

    /* Map of Essentials Addresses */
    mapping(string => address) private protocolAddresses;

    mapping(address => mapping(address => uint256)) private poolsContributionsTimestamps;
    mapping(address => ModelPools.Pool) private pools;
    ModelPools.Pool[] private poolList;

    struct Claims {
        mapping(uint256 => ModelClaims.ClaimWithParticipators) values;
        Counters.Counter counter;
    }
    Claims private claims;

    // END V1

    function initialize(bytes memory _data) external onlyOwner {
        (address _storeAddress) = abi.decode(_data, (address));

        require(_storeAddress != address(0), "STORE_EMPTY");
        protocolAddresses[STORE] = _storeAddress;
        protocolAddresses[INSURANCE_PROTOCOL] = ICheckDotInsuranceStore(protocolAddresses[STORE]).getAddress(INSURANCE_PROTOCOL);
        protocolAddresses[INSURANCE_TOKEN] = ICheckDotInsuranceStore(protocolAddresses[STORE]).getAddress(INSURANCE_TOKEN);
        protocolAddresses[INSURANCE_RISK_DATA_CALCULATOR] = ICheckDotInsuranceStore(protocolAddresses[STORE]).getAddress(INSURANCE_RISK_DATA_CALCULATOR);
        protocolAddresses[CHECKDOT_TOKEN] = IDAOProxy(address(this)).getGovernance();

        if (pools[protocolAddresses[CHECKDOT_TOKEN]].poolAddress == address(0)) { // Creating Default CDT Pool if doesn't exists
            createPool(protocolAddresses[CHECKDOT_TOKEN]);
        }
        claims.values[0].claim.utcEndVote = block.timestamp;
    }

    modifier poolExist(address _token) {
        require(pools[_token].poolAddress != address(0), "Entity should be initialized");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == IOwnedProxy(address(this)).getOwner(), "Factory: FORBIDDEN");
        _;
    }

    modifier onlyInsuranceProtocol {
        require(msg.sender == protocolAddresses[INSURANCE_PROTOCOL], "Factory: FORBIDDEN");
        _;
    }

    modifier onlyInsuranceToken {
        require(msg.sender == protocolAddresses[INSURANCE_TOKEN], "Factory: FORBIDDEN");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    function getInitCodePoolHash() external pure returns (bytes32) {
        return INIT_CODE_POOL_HASH;
    }

    function getVersion() external pure returns (uint256) {
        return VERSION;
    }

    function getStoreAddress() external view returns (address) {
        return protocolAddresses[STORE];
    }

    function getInsuranceProtocolAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_PROTOCOL];
    }

    function getInsuranceTokenAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_TOKEN];
    }

    function getInsuranceRiskDataCalculatorAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_RISK_DATA_CALCULATOR];
    }

    //////////
    // Functions
    //////////

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

    function contribute(address _token, address _from, uint256 _amountOfTokens) external noReentrant poolExist(_token)
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

    function uncontribute(address _token, address _to, uint256 _amountOfliquidityTokens) external noReentrant poolExist(_token)
        returns (uint256 amount) {
        require(_amountOfliquidityTokens > 0, "amount should be > 0");
        require(_to != address(0), "not valid to");
        ModelPools.Pool memory pool = pools[_token];

        //require(poolsContributionsTimestamps[pool.poolAddress][_to] != 0, "NO_CONTRIBUTION");
        //require(poolsContributionsTimestamps[pool.poolAddress][_to].add(uint256(86400).mul(15)) < block.timestamp, "15_DAYS_LOCKED_CONTRIBUTION");
        poolsContributionsTimestamps[pool.poolAddress][_to] = 0;

        IERC20(pool.poolAddress).transferFrom(msg.sender, pool.poolAddress, _amountOfliquidityTokens); // send liquidity to pool
        amount = ICheckDotPool(pool.poolAddress).burn(_to);

        emit ContributionRemoved(_to, pool.poolAddress, amount);
    }

    function mintInsuranceProtocolFees(address _token, address _from) external noReentrant poolExist(_token) onlyInsuranceProtocol
        returns (uint256 liquidity) {
        require(_from != address(0), "not valid from");
        ModelPools.Pool memory pool = pools[_token];
        
        liquidity = ICheckDotPool(pool.poolAddress).mint(_from);
    }

    function getClaimPrice(address _coveredCurrency, uint256 _claimAmount) public view returns (uint256) {
        uint256 claimFeesInCoveredCurrency = _claimAmount.div(100).mul(1); // 1% fee
        return ICheckDotInsuranceRiskDataCalculator(protocolAddresses[INSURANCE_RISK_DATA_CALCULATOR]).convertCost(claimFeesInCoveredCurrency, _coveredCurrency, protocolAddresses[CHECKDOT_TOKEN]);
    }

    function claim(uint256 _insuranceTokenId, uint256 _claimAmount, string calldata _claimProperties) external noReentrant onlyInsuranceToken returns (uint256) {
        ICheckDotERC721InsuranceToken insuranceToken = ICheckDotERC721InsuranceToken(protocolAddresses[INSURANCE_TOKEN]);
        
        require(insuranceToken.coverIsAvailable(_insuranceTokenId), 'CLAIM_UNAVAILABLE');

        ModelCovers.Cover memory cover = insuranceToken.getCover(_insuranceTokenId);

        require(_claimAmount > 0 && _claimAmount <= cover.coveredAmount, 'AMOUNT_UNAVAILABLE');
        uint256 claimFeesInCDT = getClaimPrice(cover.coveredCurrency, _claimAmount);
        
        require(IERC20(protocolAddresses[CHECKDOT_TOKEN]).balanceOf(cover.coveredAddress) >= claimFeesInCDT, "INSUFISANT_BALANCE");
        TransferHelper.safeTransferFrom(protocolAddresses[CHECKDOT_TOKEN], cover.coveredAddress, address(this), claimFeesInCDT); // send tokens to insuranceProtocol

        uint256 id = claims.counter.current();

        claims.values[id].claim.id = id;
        claims.values[id].claim.coverId = _insuranceTokenId;
        claims.values[id].claim.productId = cover.productId;
        claims.values[id].claim.properties = _claimProperties;
        claims.values[id].claim.coveredAddress = cover.coveredAddress;
        claims.values[id].claim.poolAddress = pools[cover.coveredCurrency].poolAddress;
        claims.values[id].claim.coveredCurrency = cover.coveredCurrency;
        claims.values[id].claim.amount = _claimAmount;
        claims.values[id].claim.status = ModelClaims.ClaimStatus.Approbation;
        claims.values[id].claim.rewardsInCDT = claimFeesInCDT;
        claims.counter.increment();
        emit ClaimCreated(id, cover.productId, _insuranceTokenId, _claimAmount);

        return id;
    }

    function teamApproveClaim(uint256 claimId, bool approved, string calldata additionnalProperties) external onlyInsuranceToken {
        ModelClaims.ClaimWithParticipators storage currentClaim = claims.values[claimId];

        if (approved) {
            currentClaim.claim.status = ModelClaims.ClaimStatus.Vote;
        } else {
            currentClaim.claim.status = ModelClaims.ClaimStatus.Canceled;
        }
        currentClaim.claim.additionnalProperties = additionnalProperties;
        currentClaim.claim.utcStartVote = block.timestamp; // now
        currentClaim.claim.alreadyRewardedAmount = 0;
        currentClaim.claim.utcEndVote = block.timestamp.add(uint256(86400).mul(2)); // in two days
        emit ClaimUpdated(currentClaim.claim.id, currentClaim.claim.productId, currentClaim.claim.coverId);
    }

    function voteForClaim(uint256 claimId, bool approved) external noReentrant {
        ModelClaims.ClaimWithParticipators storage currentClaim = claims.values[claimId];

        require(currentClaim.participators[msg.sender].voter == address(0), "ALREADY_VOTED");
        require(currentClaim.claim.coveredAddress != msg.sender, "ACCESS_DENIED");
        require(currentClaim.claim.status == ModelClaims.ClaimStatus.Vote, "VOTE_FINISHED");
        require(block.timestamp < currentClaim.claim.utcEndVote, "VOTE_ENDED");

        IERC20 token = IERC20(protocolAddresses[CHECKDOT_TOKEN]);
        uint256 votes = token.balanceOf(msg.sender).div(10 ** token.decimals());
        require(votes >= 1, "Proxy: INSUFFISANT_POWER");

        if (approved) {
            currentClaim.claim.totalApproved = currentClaim.claim.totalApproved.add(votes);
            currentClaim.participators[msg.sender].totalApproved = votes;
        } else {
            currentClaim.claim.totalUnapproved = currentClaim.claim.totalUnapproved.add(votes);
            currentClaim.participators[msg.sender].totalUnapproved = votes;
        }
        currentClaim.participators[msg.sender].voter = msg.sender;

        uint256 voteDuration = currentClaim.claim.utcEndVote.sub(currentClaim.claim.utcStartVote);
        uint256 timeSinceStartVote = block.timestamp.sub(currentClaim.claim.utcStartVote);
        uint256 rewards = timeSinceStartVote.mul(currentClaim.claim.rewardsInCDT).div(voteDuration).sub(currentClaim.claim.alreadyRewardedAmount);

        if (rewards > MINIMUM_CLAIM_REWARDS && token.balanceOf(address(this)) >= rewards) {
            TransferHelper.safeTransfer(protocolAddresses[CHECKDOT_TOKEN], msg.sender, rewards);
            currentClaim.claim.alreadyRewardedAmount = currentClaim.claim.alreadyRewardedAmount.add(rewards);
        }
        emit ClaimUpdated(currentClaim.claim.id, currentClaim.claim.productId, currentClaim.claim.coverId);
    }

    function getNextVoteRewards(uint256 claimId) public view returns (uint256) {
        ModelClaims.ClaimWithParticipators storage currentClaim = claims.values[claimId];

        uint256 voteDuration = currentClaim.claim.utcEndVote.sub(currentClaim.claim.utcStartVote);
        uint256 timeSinceStartVote = block.timestamp.sub(currentClaim.claim.utcStartVote);
        uint256 rewards = timeSinceStartVote.mul(currentClaim.claim.rewardsInCDT).div(voteDuration).sub(currentClaim.claim.alreadyRewardedAmount);

        if (rewards > MINIMUM_CLAIM_REWARDS && IERC20(protocolAddresses[CHECKDOT_TOKEN]).balanceOf(address(this)) >= rewards) {
            return rewards;
        }
        return 0;
    }

    function getVoteOf(uint256 claimId, address _addr) public view returns (ModelClaims.Vote memory) {
        return claims.values[claimId].participators[_addr];
    }

    function payoutClaim(uint256 claimId) external noReentrant onlyInsuranceToken {
        ModelClaims.ClaimWithParticipators storage currentClaim = claims.values[claimId];

        require(currentClaim.claim.status == ModelClaims.ClaimStatus.Vote, "CLAIM_FINISHED");
        require(block.timestamp > currentClaim.claim.utcEndVote, "VOTE_INPROGRESS");
        require(currentClaim.claim.totalApproved > currentClaim.claim.totalUnapproved, "CLAIM_REJECTED");
        require(ICheckDotPool(currentClaim.claim.poolAddress).getReserves() >= currentClaim.claim.amount, "UNAVAILABLE_FOUND_AMOUNT");
        currentClaim.claim.status = ModelClaims.ClaimStatus.Paid;
        ICheckDotPool(currentClaim.claim.poolAddress).refund(currentClaim.claim.coveredAddress, currentClaim.claim.amount);
        emit ClaimUpdated(currentClaim.claim.id, currentClaim.claim.productId, currentClaim.claim.coverId);
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
            results[index].reserveInUSD = ICheckDotInsuranceRiskDataCalculator(protocolAddresses[INSURANCE_RISK_DATA_CALCULATOR]).getTokenPriceInUSD(pool.token);
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
        results[0].reserveInUSD = 0;//ICheckDotInsuranceRiskDataCalculator(protocolAddresses[INSURANCE_RISK_DATA_CALCULATOR]).getTokenPriceInUSD(pool.token).mul(results[0].reserve).div(1 ether);
        return results[0];
    }

    function getPoolsLength() public view returns (uint256) {
        return poolList.length;
    }

    function getClaimLength() public view returns (uint256) {
        return claims.counter.current();
    }

    function getClaimDetails(uint256 _id) public view returns (ModelClaims.Claim memory) {
        ModelClaims.Claim[] memory results = new ModelClaims.Claim[](1);
        ModelClaims.Claim storage currentClaim = claims.values[_id].claim;

        results[0].id = currentClaim.id;
        results[0].coverId = currentClaim.coverId;
        results[0].properties = currentClaim.properties;
        results[0].coveredAddress = currentClaim.coveredAddress;
        results[0].poolAddress = currentClaim.poolAddress;
        results[0].coveredCurrency = currentClaim.coveredCurrency;
        results[0].amount = currentClaim.amount;
        results[0].utcStartVote = currentClaim.utcStartVote;
        results[0].utcEndVote = currentClaim.utcEndVote;
        results[0].totalApproved = currentClaim.totalApproved;
        results[0].totalUnapproved = currentClaim.totalUnapproved;
        results[0].status = currentClaim.status;
        results[0].rewardsInCDT = currentClaim.rewardsInCDT;
        results[0].alreadyRewardedAmount = currentClaim.alreadyRewardedAmount;
        return results[0];
    }

    function getPoolContributionInformations(address _token, address _staker) public view returns (uint256, bool, uint256, uint256) {
        ModelPools.Pool memory pool = pools[_token];
        uint256 lastContributionTime = poolsContributionsTimestamps[pool.poolAddress][_staker];
        bool canUnContribute = block.timestamp.sub(lastContributionTime).add(uint256(86400).mul(15)) < block.timestamp;
        uint256 stakerBalanceLP = IERC20(pool.poolAddress).balanceOf(_staker);
        uint256 totalBalanceOfToken = IERC20(pool.token).balanceOf(pool.poolAddress);
        uint256 totalSupply = IERC20(pool.poolAddress).totalSupply();

        return (lastContributionTime, canUnContribute, stakerBalanceLP, stakerBalanceLP.mul(totalBalanceOfToken).div(totalSupply));
    }

}