// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../utils/SafeMath.sol";
import "../../utils/SignedSafeMath.sol";
import "../../utils/TransferHelper.sol";
import "../../utils/Counters.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IDAOProxy.sol";
import "../../interfaces/IOracle.sol";
import "../../token/ERC721.sol";

import "../../DaoProxy/interfaces/IOwnedProxy.sol";

struct Object {
    mapping(string => address) a;
    mapping(string => uint256) n;
    mapping(string => string) s;
}

struct CoverInformations {
    // cover slots
    uint256 id;
    uint256 productId;
    string  uri;
    address coveredAddress;
    uint256 utcStart;
    uint256 utcEnd;
    uint256 coveredAmount;
    address coveredCurrency;
    uint256 premiumAmount;
    uint256 status;
    // claim slots
    string  claimProperties;
    string  claimAdditionnalProperties;
    uint256 claimAmount;
    uint256 claimPayout;
    uint256 claimUtcPayoutDate;
    uint256 claimRewardsInCDT;
    uint256 claimAlreadyRewardedAmount;
    uint256 claimUtcStartVote;
    uint256 claimUtcEndVote;
    uint256 claimTotalApproved;
    uint256 claimTotalUnapproved;
    // others slots
    address claimCurrency;
}

enum CoverStatus {
    NotSet,           // 0 |
    Active,           // 1 |
    ClaimApprobation, // 2 |
    ClaimVote,        // 3 |
    ClaimPaid,        // 4 |
    Canceled          // 5 |
}

struct PoolInformations {
    address token;
    uint256 totalSupply; // LP token
    uint256 reserve;
}

struct Vote {
    address voter;
    uint256 totalApproved;
    uint256 totalUnapproved;
}

contract CheckDotInsuranceCovers is ERC721 {
    using SafeMath for uint;
    using SignedSafeMath for int256;
    using Counters for Counters.Counter;

    event PoolCreated(address token);
    event ContributionAdded(address from, address token, uint256 amount, uint256 liquidity);
    event ContributionRemoved(address from, address token, uint256 amount, uint256 liquidity);

    event ClaimCreated(uint256 id, uint256 productId, uint256 amount);    
    event ClaimUpdated(uint256 id, uint256 productId);
    
    string private constant INSURANCE_PRODUCTS = "INSURANCE_PRODUCTS";
    string private constant INSURANCE_CALCULATOR = "INSURANCE_CALCULATOR";
    string private constant CHECKDOT_TOKEN = "CHECKDOT_TOKEN";

    bool internal locked;

    // V1 DATA

    /* Map of Essentials Addresses */
    mapping(string => address) private protocolAddresses;

    // Pools

    mapping (address => mapping(address => uint256)) private _balances;
    mapping (address => mapping(address => uint256)) private _holdTimes;

    mapping(address => Object) private pools;
    address[] private poolList;

    // Covers

    struct CoverTokens {
        mapping(uint256 => Object) data;
        Counters.Counter counter;
    }
    CoverTokens private tokens;

    // Claims

    mapping(uint256 => mapping(address => Object)) private claimsParticipators;

    // Vars

    Object private vars;

    // END V1

    function initialize(bytes memory _data) external onlyOwner {
        (
            address _insuranceProductsAddress,
            address _insuranceCalculatorAddress
        ) = abi.decode(_data, (address, address));

        protocolAddresses[INSURANCE_PRODUCTS] = _insuranceProductsAddress;
        protocolAddresses[INSURANCE_CALCULATOR] = _insuranceCalculatorAddress;
        protocolAddresses[CHECKDOT_TOKEN] = IDAOProxy(address(this)).getGovernance();

        if (pools[protocolAddresses[CHECKDOT_TOKEN]].a["token"] == address(0)) { // Creating Default CDT Pool if doesn't exists
            createPool(protocolAddresses[CHECKDOT_TOKEN]);
        }
        vars.n["LOCK_DURATION"] = uint256(86400).mul(15); // To be managed via DAO in the future.
        vars.n["VOTE_DURATION"] = uint256(86400).mul(30); // To be managed via DAO in the future.
    }

    modifier poolExist(address _token) {
        require(pools[_token].a["token"] != address(0), "Entity should be initialized");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == IOwnedProxy(address(this)).getOwner(), "FORBIDDEN");
        _;
    }

    modifier onlyInsuranceProducts {
        require(msg.sender == protocolAddresses[INSURANCE_PRODUCTS], "FORBIDDEN");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    function getVersion() external pure returns (uint256) {
        return 1;
    }

    function getInsuranceProductsAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_PRODUCTS];
    }

    function getInsuranceCalculatorAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_CALCULATOR];
    }

    //////////
    // Functions
    //////////

    function createPool(address _token) public onlyOwner {
        require(_token != address(0), 'ZERO_ADDRESS');
        require(pools[_token].a["token"] == address(0), 'ALREADY_EXISTS');

        pools[_token].a["token"] = _token;
        poolList.push(_token);
        emit PoolCreated(_token);
    }

    function contribute(address _token, address _from, uint256 _amountOfTokens) external noReentrant poolExist(_token) {
        require(_amountOfTokens > 0, "INVALID_AMOUNT");
        require(IERC20(_token).balanceOf(_from) >= _amountOfTokens, "BALANCE_EXCEEDED");
        require(IERC20(_token).allowance(_from, address(this)) >= _amountOfTokens, "UNALLOWED");

        TransferHelper.safeTransferFrom(_token, _from, address(this), _amountOfTokens);
        uint256 liquidity = _contribute(_token, _from);
        emit ContributionAdded(_from, _token, _amountOfTokens, liquidity);
    }

    function uncontribute(address _token, address _to, uint256 _amountOfliquidityTokens) external noReentrant poolExist(_token) {
        require(_amountOfliquidityTokens > 0, "INVALID_AMOUNT");
        require(_holdTimes[_token][msg.sender].add(vars.n["LOCK_DURATION"]) < block.timestamp, "15_DAYS_LOCKED_CONTRIBUTION");

        uint256 amountOfLP = _amountOfliquidityTokens;
        if (_amountOfliquidityTokens > _balances[_token][msg.sender]) {
            amountOfLP = _balances[_token][msg.sender];
        }
        uint256 amount = _unContribute(_token, msg.sender, _to, amountOfLP); // remove contribution
        emit ContributionRemoved(_to, _token, amount, _amountOfliquidityTokens);
    }

    function sync(address _token) external noReentrant poolExist(_token) {
        _sync(_token);
    }

    function addInsuranceProtocolFees(address _token, address _from) external noReentrant poolExist(_token) onlyInsuranceProducts {
        _contribute(_token, _from);
    }

    function getClaimPrice(address _coveredCurrency, uint256 _claimAmount) public view returns (uint256) {
        uint256 claimFeesInCoveredCurrency = _claimAmount.div(100).mul(1); // 1% fee
        return IOracle(protocolAddresses[INSURANCE_CALCULATOR]).convertCost(claimFeesInCoveredCurrency, _coveredCurrency, protocolAddresses[CHECKDOT_TOKEN]);
    }

    function claim(uint256 _insuranceTokenId, uint256 _claimAmount, address _claimCurrency, string calldata _claimProperties) external noReentrant returns (uint256) {
        require(tokens.data[_insuranceTokenId].n["status"] == uint256(CoverStatus.Active), "NOT_ACTIVE_COVER");
        require(tokens.data[_insuranceTokenId].n["utcEnd"] > block.timestamp, 'COVER_ENDED');
        Object storage cover = tokens.data[_insuranceTokenId];

        require(_claimAmount > 0 && _claimAmount <= cover.n["coveredAmount"], 'AMOUNT_UNAVAILABLE');
        uint256 claimFeesInCDT = getClaimPrice(cover.a["coveredCurrency"], _claimAmount);
        
        require(IERC20(protocolAddresses[CHECKDOT_TOKEN]).balanceOf(cover.a["coveredAddress"]) >= claimFeesInCDT, "INSUFISANT_BALANCE");
        TransferHelper.safeTransferFrom(protocolAddresses[CHECKDOT_TOKEN], cover.a["coveredAddress"], address(this), claimFeesInCDT); // send tokens to insuranceProtocol
        _sync(protocolAddresses[CHECKDOT_TOKEN]); // update reserve.

        cover.s["claimProperties"] = _claimProperties;
        cover.n["claimAmount"] = _claimAmount;
        cover.a["claimCurrency"] = _claimCurrency;
        cover.n["status"] = uint256(CoverStatus.ClaimApprobation);
        cover.n["claimRewardsInCDT"] = claimFeesInCDT;

        emit ClaimCreated(cover.n["id"], cover.n["productId"], _claimAmount);
        return cover.n["id"];
    }

    function teamApproveClaim(uint256 _insuranceTokenId, bool _approved, string calldata _additionnalProperties) external onlyOwner {
        Object storage cover = tokens.data[_insuranceTokenId];

        require(cover.n["status"] == uint256(CoverStatus.ClaimApprobation) || cover.n["status"] == uint256(CoverStatus.ClaimVote), "CLAIM_APPROBATION_FINISHED");
        if (_approved) {
            cover.n["status"] = uint256(CoverStatus.ClaimVote);
            cover.n["claimUtcStartVote"] = block.timestamp; // now
            cover.n["claimUtcEndVote"] = block.timestamp.add(vars.n["VOTE_DURATION"]); // in two days
        } else {
            cover.n["status"] = uint256(CoverStatus.Canceled);
        }
        cover.s["claimAdditionnalProperties"] = _additionnalProperties;
        emit ClaimUpdated(cover.n["id"], cover.n["productId"]);
    }

    function teamCancelClaim(uint256 _insuranceTokenId, string calldata _additionnalProperties) external onlyOwner {
        Object storage cover = tokens.data[_insuranceTokenId];

        cover.n["status"] = uint256(CoverStatus.Canceled);
        cover.n["claimUtcStartVote"] = 0;
        cover.n["claimUtcEndVote"] = 0;
        cover.s["claimAdditionnalProperties"] = _additionnalProperties;
        emit ClaimUpdated(cover.n["id"], cover.n["productId"]);
    }

    function voteForClaim(uint256 _insuranceTokenId, bool _approved) external noReentrant {
        Object storage cover = tokens.data[_insuranceTokenId];

        require(claimsParticipators[_insuranceTokenId][msg.sender].a["voter"] == address(0), "ALREADY_VOTED");
        require(cover.a["coveredAddress"] != msg.sender, "ACCESS_DENIED");
        require(cover.n["status"] == uint256(CoverStatus.ClaimVote), "VOTE_FINISHED");
        require(block.timestamp < cover.n["claimUtcEndVote"], "VOTE_ENDED");

        IERC20 token = IERC20(protocolAddresses[CHECKDOT_TOKEN]);
        uint256 votes = token.balanceOf(msg.sender).div(10 ** token.decimals());
        require(votes >= 1, "Proxy: INSUFFISANT_POWER");

        if (_approved) {
            cover.n["claimTotalApproved"] = cover.n["claimTotalApproved"].add(votes);
            claimsParticipators[_insuranceTokenId][msg.sender].n["TotalApproved"] = votes;
        } else {
            cover.n["claimTotalUnapproved"] = cover.n["claimTotalUnapproved"].add(votes);
            claimsParticipators[_insuranceTokenId][msg.sender].n["totalUnapproved"] = votes;
        }
        claimsParticipators[_insuranceTokenId][msg.sender].a["voter"] = msg.sender;

        uint256 voteDuration = cover.n["claimUtcEndVote"].sub(cover.n["claimUtcStartVote"]);
        uint256 timeSinceStartVote = block.timestamp.sub(cover.n["claimUtcStartVote"]);
        uint256 rewards = timeSinceStartVote.mul(cover.n["claimRewardsInCDT"]).div(voteDuration).sub(cover.n["claimAlreadyRewardedAmount"]);

        if (token.balanceOf(address(this)) >= rewards) {
            TransferHelper.safeTransfer(protocolAddresses[CHECKDOT_TOKEN], msg.sender, rewards);
            cover.n["claimAlreadyRewardedAmount"] = cover.n["claimAlreadyRewardedAmount"].add(rewards);
            _sync(protocolAddresses[CHECKDOT_TOKEN]);
        }
        emit ClaimUpdated(cover.n["id"], cover.n["productId"]);
    }

    function getNextVoteRewards(uint256 _insuranceTokenId) public view returns (uint256) {
        Object storage cover = tokens.data[_insuranceTokenId];

        uint256 voteDuration = cover.n["claimUtcEndVote"].sub(cover.n["claimUtcStartVote"]);
        uint256 timeSinceStartVote = block.timestamp.sub(cover.n["claimUtcStartVote"]);
        uint256 rewards = timeSinceStartVote.mul(cover.n["claimRewardsInCDT"]).div(voteDuration).sub(cover.n["claimAlreadyRewardedAmount"]);

        if (IERC20(protocolAddresses[CHECKDOT_TOKEN]).balanceOf(address(this)) >= rewards) {
            return rewards;
        }
        return 0;
    }

    function payoutClaim(uint256 _insuranceTokenId) external noReentrant {
        Object storage cover = tokens.data[_insuranceTokenId];

        require(cover.n["status"] == uint256(CoverStatus.ClaimVote), "CLAIM_FINISHED");
        require(block.timestamp > cover.n["claimUtcEndVote"], "VOTE_INPROGRESS");
        require(cover.a["coveredAddress"] == msg.sender, "ONLY_COVERED");
        require(cover.n["claimTotalApproved"] > cover.n["claimTotalUnapproved"], "CLAIM_REJECTED");
        require(pools[cover.a["coveredCurrency"]].n["reserve"] >= cover.n["claimAmount"], "UNAVAILABLE_FUNDS_AMOUNT");
        cover.n["status"] = uint256(CoverStatus.ClaimPaid);
        cover.n["claimPayout"] = cover.n["claimAmount"];
        cover.n["claimUtcPayoutDate"] = block.timestamp;
        TransferHelper.safeTransfer(cover.a["coveredCurrency"], cover.a["coveredAddress"], cover.n["claimAmount"]);
        _sync(cover.a["coveredCurrency"]); // synchronize the coverCurrency Pool with the new reserve
        emit ClaimUpdated(cover.n["id"], cover.n["productId"]);
    }

    //////////
    // Views
    //////////

    // function getPools(int256 page, int256 pageSize) external view returns (PoolInformations[] memory) {
    //     uint256 poolLength = poolList.length;
    //     int256 queryStartPoolIndex = int256(poolLength).sub(pageSize.mul(page.add(1))).add(pageSize);
    //     require(queryStartPoolIndex >= 0, "Out of bounds");
    //     int256 queryEndPoolIndex = queryStartPoolIndex.sub(pageSize);
    //     if (queryEndPoolIndex < 0) {
    //         queryEndPoolIndex = 0;
    //     }
    //     int256 currentPoolIndex = queryStartPoolIndex;
    //     require(uint256(currentPoolIndex) <= poolLength, "Out of bounds");
    //     PoolInformations[] memory results = new PoolInformations[](uint256(currentPoolIndex - queryEndPoolIndex));
    //     uint256 index = 0;

    //     for (currentPoolIndex; currentPoolIndex > queryEndPoolIndex; currentPoolIndex--) {
    //         address token = poolList[uint256(currentPoolIndex).sub(1)];
    //         results[index].token = token;
    //         results[index].totalSupply = pools[token].n["totalSupply"];
    //         results[index].reserve = pools[token].n["reserve"];
    //         index++;
    //     }
    //     return results;
    // }

    function getPool(address _token) external view returns (PoolInformations memory) {
        PoolInformations[] memory results = new PoolInformations[](1);

        results[0].token = pools[_token].a["token"];
        results[0].totalSupply = pools[_token].n["totalSupply"];
        results[0].reserve = pools[_token].n["reserve"];
        return results[0];
    }

    function getPoolsLength() external view returns (uint256) {
        return poolList.length;
    }

    function getPoolContributionInformations(address _token, address _staker) external view returns (uint256, bool, uint256, uint256) {
        uint256 lastContributionTime = _holdTimes[_token][_staker];
        bool canUnContribute = lastContributionTime.add(vars.n["LOCK_DURATION"]) < block.timestamp;
        uint256 stakerBalanceLP = _balances[_token][_staker];
        uint256 totalBalanceOfToken = IERC20(_token).balanceOf(address(this));
        uint256 totalSupply = pools[_token].n["totalSupply"];

        return (lastContributionTime, canUnContribute, stakerBalanceLP, stakerBalanceLP.mul(totalBalanceOfToken).div(totalSupply));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Overloaded function to retrieve IPFS url of a tokenId.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "INVALID_TOKEN_ID");
        return _insuranceTokenURI(tokenId);
    }

    function getCoverIdsByOwner(address _owner) public view returns (uint256[] memory) {
        return balanceIdsOf(_owner);
    }

    function getCoversByOwner(address _owner) external view returns (CoverInformations[] memory) {
        uint256[] memory ids = getCoverIdsByOwner(_owner);
        CoverInformations[] memory results = new CoverInformations[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            results[i] = getCover(ids[i]);
        }
        return results;
    }

    /**
     * @dev Creates a new insurance token sent to `_coveredAddress`.
     */
    function mintInsuranceToken(uint256 _productId, address _coveredAddress, uint256 _insuranceTermInDays, uint256 _premiumAmount, address _coveredCurrency, uint256 _coveredAmount, string calldata _uri) external noReentrant onlyInsuranceProducts returns (uint256) {
        require(bytes(_uri).length > 0, "URI doesn't exists on product");
        uint256 tokenId = tokens.counter.current();

        _mint(_coveredAddress, tokenId);
        tokens.data[tokenId].n["id"] = tokenId;
        tokens.data[tokenId].n["productId"] = _productId;
        tokens.data[tokenId].s["uri"] = _uri;
        tokens.data[tokenId].a["coveredCurrency"] = _coveredCurrency;
        tokens.data[tokenId].n["coveredAmount"] = _coveredAmount;
        tokens.data[tokenId].n["premiumAmount"] = _premiumAmount;
        tokens.data[tokenId].a["coveredAddress"] = _coveredAddress;
        tokens.data[tokenId].n["utcStart"] = block.timestamp;
        tokens.data[tokenId].n["utcEnd"] = block.timestamp.add(_insuranceTermInDays.mul(86400));
        tokens.data[tokenId].n["status"] = uint256(CoverStatus.Active);
        tokens.counter.increment();
        return tokenId;
    }

    function getCover(uint256 tokenId) public view returns (CoverInformations memory) {
        CoverInformations[] memory r = new CoverInformations[](1);

        r[0].id = tokens.data[tokenId].n["id"];
        r[0].productId = tokens.data[tokenId].n["productId"];
        r[0].uri = tokens.data[tokenId].s["uri"];
        r[0].coveredAddress = tokens.data[tokenId].a["coveredAddress"];
        r[0].utcStart = tokens.data[tokenId].n["utcStart"];
        r[0].utcEnd = tokens.data[tokenId].n["utcEnd"];
        r[0].coveredAmount = tokens.data[tokenId].n["coveredAmount"];
        r[0].coveredCurrency = tokens.data[tokenId].a["coveredCurrency"];
        r[0].premiumAmount = tokens.data[tokenId].n["premiumAmount"];
        r[0].status = tokens.data[tokenId].n["status"];
        r[0].claimProperties = tokens.data[tokenId].s["claimProperties"];
        r[0].claimAdditionnalProperties = tokens.data[tokenId].s["claimAdditionnalProperties"];
        r[0].claimAmount = tokens.data[tokenId].n["claimAmount"];
        r[0].claimCurrency = tokens.data[tokenId].a["claimCurrency"];
        r[0].claimPayout = tokens.data[tokenId].n["claimPayout"];
        r[0].claimUtcPayoutDate = tokens.data[tokenId].n["claimUtcPayoutDate"];
        r[0].claimRewardsInCDT = tokens.data[tokenId].n["claimRewardsInCDT"];
        r[0].claimAlreadyRewardedAmount = tokens.data[tokenId].n["claimAlreadyRewardedAmount"];
        r[0].claimUtcStartVote = tokens.data[tokenId].n["claimUtcStartVote"];
        r[0].claimUtcEndVote = tokens.data[tokenId].n["claimUtcEndVote"];
        r[0].claimTotalApproved = tokens.data[tokenId].n["claimTotalApproved"];
        r[0].claimTotalUnapproved = tokens.data[tokenId].n["claimTotalUnapproved"];
        return r[0];
    }

    function getLightCoverInformation(uint256 tokenId) public view returns (address, uint256, uint256) {
        return (tokens.data[tokenId].a["coveredCurrency"], tokens.data[tokenId].n["coveredAmount"], tokens.data[tokenId].n["status"]);
    }

    function getCoversCount() public view returns (uint256) {
        return tokens.counter.current();
    }

    function getVoteOf(uint256 _insuranceTokenId, address _addr) public view returns (Vote memory) {
        return Vote(
            claimsParticipators[_insuranceTokenId][_addr].a["voter"],
            claimsParticipators[_insuranceTokenId][_addr].n["totalApproved"],
            claimsParticipators[_insuranceTokenId][_addr].n["totalUnapproved"]
        );
    }

    ////////
    // Internals
    ////////

    function _contribute(address token, address to) internal returns (uint256 liquidity) {
        uint256 _reserve = pools[token].n["reserve"]; // gas savings
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 amount = balance.sub(_reserve);

        uint256 _totalSupply = pools[token].n["totalSupply"]; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = amount;
        } else {
            liquidity = amount.mul(_totalSupply) / _reserve;
        }
        require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');
        pools[token].n["totalSupply"] = pools[token].n["totalSupply"].add(liquidity);
        _sync(token);
        _balances[token][to] = _balances[token][to].add(liquidity); // add lp
        _holdTimes[token][to] = block.timestamp;
    }

    function _unContribute(address token, address from, address to, uint256 liquidityAmount) internal returns (uint256 amount) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(liquidityAmount <= _balances[token][from], 'INSUFFICIENT_LIQUIDITY_OWNED');

        uint256 _totalSupply = pools[token].n["totalSupply"]; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount = liquidityAmount.mul(balance) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
        pools[token].n["totalSupply"] = pools[token].n["totalSupply"].sub(liquidityAmount);
        _balances[token][from] = _balances[token][from].sub(liquidityAmount); // burn lp
        TransferHelper.safeTransfer(token, to, amount);
        _sync(token);
    }

    function _sync(address token) internal {
        pools[token].n["reserve"] = IERC20(token).balanceOf(address(this));
    }

    function _insuranceTokenURI(uint256 tokenId) private view returns (string memory) {
        return string(abi.encodePacked("ipfs://", tokens.data[tokenId].s["uri"]));
    }

}