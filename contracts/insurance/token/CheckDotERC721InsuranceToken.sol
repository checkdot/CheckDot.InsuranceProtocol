// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../interfaces/ICheckDotInsuranceStore.sol";
import "../../interfaces/ICheckDotPoolFactory.sol";
import "../../interfaces/ICheckDotInsuranceRiskDataCalculator.sol";
import "../../utils/SafeMath.sol";
import "../../utils/Counters.sol";
import "../../structs/ModelCovers.sol";
import "../../token/ERC721.sol";

contract CheckDotERC721InsuranceToken is ERC721 {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string private constant STORE = "STORE";
    string private constant INSURANCE_PROTOCOL = "INSURANCE_PROTOCOL";
    string private constant INSURANCE_POOL_FACTORY = "INSURANCE_POOL_FACTORY";
    string private constant INSURANCE_RISK_DATA_CALCULATOR = "INSURANCE_RISK_DATA_CALCULATOR";

    bool internal locked;

    // V1 DATA

    /* Map of Essentials Addresses */
    mapping(string => address) private protocolAddresses;

    struct CoverTokens {
        mapping(uint256 => ModelCovers.Cover) map;
        ModelCovers.Cover[] availables;
        Counters.Counter counter;
    }

    CoverTokens private tokens;

    mapping(address => uint256) totalCoveredAmounts;

    // END V1

    function initialize(bytes memory _data) external onlyOwner {
        (address _storeAddress) = abi.decode(_data, (address));

        require(_storeAddress != address(0), "STORE_EMPTY");
        protocolAddresses[STORE] = _storeAddress;
        if (bytes(name()).length == 0) {
            super._initialize("CDTInsurance", "ICDT");
        }
        protocolAddresses[INSURANCE_PROTOCOL] = ICheckDotInsuranceStore(protocolAddresses[STORE]).getAddress(INSURANCE_PROTOCOL);
        protocolAddresses[INSURANCE_POOL_FACTORY] = ICheckDotInsuranceStore(protocolAddresses[STORE]).getAddress(INSURANCE_POOL_FACTORY);
        protocolAddresses[INSURANCE_RISK_DATA_CALCULATOR] = ICheckDotInsuranceStore(protocolAddresses[STORE]).getAddress(INSURANCE_RISK_DATA_CALCULATOR);
    }

    modifier onlyInsuranceProtocol {
        require(msg.sender == protocolAddresses[INSURANCE_PROTOCOL], "Only InsuranceProtocol is allowed");
        _;
    }

    modifier onlyInsurancePoolFactory {
        require(msg.sender == protocolAddresses[INSURANCE_POOL_FACTORY], "Only InsurancePoolFactory is allowed");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    function mintInsuranceToken(uint256 _productId, address _coveredAddress, uint256 _insuranceTermInDays, uint256 _premiumAmount, address _coveredCurrency, uint256 _coveredAmount, string calldata _uri) public noReentrant onlyInsuranceProtocol returns (uint256) {
        return _mintInsuranceToken(_productId, _coveredAddress, _insuranceTermInDays, _premiumAmount, _coveredCurrency, _coveredAmount, _uri);
    }

    function claim(uint256 _tokenId, uint256 _claimAmount, string calldata _claimProperties) external noReentrant {
        require(ownerOf(_tokenId) == msg.sender, "FORBIDEN");
        require(tokens.map[_tokenId].status == ModelCovers.CoverStatus.Active, "ALREADY_IN_CLAIM");
        uint256 claimId = ICheckDotPoolFactory(protocolAddresses[INSURANCE_POOL_FACTORY]).claim(_tokenId, _claimAmount, _claimProperties);
        tokens.map[_tokenId].claimId = claimId;
        tokens.map[_tokenId].claimProperties = _claimProperties;
        tokens.map[_tokenId].claimPayout = _claimAmount;
        tokens.map[_tokenId].status = ModelCovers.CoverStatus.ClaimApprobation;
    }

    function teamApproveClaim(uint256 _tokenId, uint256 _claimId, bool approved, string calldata _claimAdditionnalProperties) external noReentrant onlyOwner {
        require(tokens.map[_tokenId].claimId == _claimId, "FORBIDEN");
        require(tokens.map[_tokenId].status == ModelCovers.CoverStatus.ClaimApprobation, "FORBIDEN");
        ICheckDotPoolFactory(protocolAddresses[INSURANCE_POOL_FACTORY]).teamApproveClaim(_claimId, approved, _claimAdditionnalProperties);
        if (approved) {
            tokens.map[_tokenId].status = ModelCovers.CoverStatus.Claim;
        } else {
            tokens.map[_tokenId].status = ModelCovers.CoverStatus.Canceled;
        }
        tokens.map[_tokenId].claimAdditionnalProperties = _claimAdditionnalProperties;
    }

    function payoutClaim(uint256 _tokenId) external noReentrant {
        require(tokens.map[_tokenId].status == ModelCovers.CoverStatus.Claim, "ALREADY_IN_CLAIM");
        ICheckDotPoolFactory(protocolAddresses[INSURANCE_POOL_FACTORY]).payoutClaim(tokens.map[_tokenId].claimId);
        tokens.map[_tokenId].status = ModelCovers.CoverStatus.Canceled;
        tokens.availables[_tokenId].utcEnd = block.timestamp;
    }

    function revokeExpiredCovers() public noReentrant onlyInsuranceProtocol {
        _revokeExpiredCovers();
    }

    /**
     * @dev Returns the Store address.
     */
    function getStoreAddress() external view returns (address) {
        return protocolAddresses[STORE];
    }

    /**
     * @dev Returns the Insurance Protocol address.
     */
    function getInsuranceProtocolAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_PROTOCOL];
    }

    /**
     * @dev Returns the Insurance Pool Factory address.
     */
    function getInsurancePoolFactoryAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_POOL_FACTORY];
    }

    /**
     * @dev Returns the Insurance Risk Data Calculator address.
     */
    function getInsuranceRiskDataCalculatorAddress() external view returns (address) {
        return protocolAddresses[INSURANCE_RISK_DATA_CALCULATOR];
    }

    function getCoverIdsByOwner(address _owner) public view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](balanceOf(_owner));
        uint256 resultIndex = 0;

        for (uint256 i = 0; i < tokens.availables.length; i++) {
            if (tokens.availables[i].coveredAddress == _owner && tokens.availables[i].utcEnd >= block.timestamp) {
                results[resultIndex++] = tokens.availables[i].id;
            }
        }
        return results;
    }

    function getCoversByOwner(address _owner) external view returns (ModelCovers.Cover[] memory) {
        uint256[] memory ids = getCoverIdsByOwner(_owner);
        ModelCovers.Cover[] memory results = new ModelCovers.Cover[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            results[i] = tokens.map[ids[i]];
        }
        return results;
    }

    /**
     * @dev Returns the ModelCovers.Cover informations by tokenId.
     */
    function getCover(uint256 tokenId) external view returns (ModelCovers.Cover memory) {
        return tokens.map[tokenId];
    }

    function coverIsAvailable(uint256 tokenId) external view returns (bool) {
        return tokens.map[tokenId].status == ModelCovers.CoverStatus.Active && tokens.map[tokenId].utcEnd > block.timestamp;
    }

    function getTotalCoveredAmountFromCurrency(address _currency) external view returns (uint256) {
        return totalCoveredAmounts[_currency];
    }

    //////////
    // Views
    //////////

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
        require(_insuranceTokenIdExists(tokenId), "URI query for nonexistent token");
        return _insuranceTokenURI(tokenId);
    }

    //////////
    // Internal virtuals
    //////////

    function _revokeExpiredCovers() internal virtual {
        uint256 revokableTokensCount = 0;
        // burn expired covers tokens
        for (uint256 i = 0; i < tokens.availables.length; i++) {
            if (tokens.availables[i].utcEnd < block.timestamp) {
                revokableTokensCount++;
                tokens.availables[i].status = ModelCovers.CoverStatus.Canceled;

                // update totalCoveredAmount
                totalCoveredAmounts[tokens.availables[i].coveredCurrency] = totalCoveredAmounts[tokens.availables[i].coveredCurrency].sub(tokens.availables[i].coveredAmount);
                super._burn(tokens.availables[i].id);
            } else if (revokableTokensCount > 0) {
                tokens.availables[i - revokableTokensCount] = tokens.availables[i];
            }
        }
        for (uint256 i = 0; i < revokableTokensCount; i++) {
            tokens.availables.pop();
        }
    }

    /**
     * @dev Creates a new insurance token sent to `insured`.
     */
    function _mintInsuranceToken(uint256 _productId, address _coveredAddress, uint256 _insuranceTermInDays, uint256 _premiumAmount, address _coveredCurrency, uint256 _coveredAmount, string calldata _uri) internal virtual returns (uint256) {
        require(bytes(_uri).length > 0, "URI doesn't exists on product");
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned, so we need a separate counter.
        uint256 tokenId = tokens.counter.current();

        _mint(_coveredAddress, tokenId);

        tokens.map[tokenId].id = tokenId;
        tokens.map[tokenId].productId = _productId;
        tokens.map[tokenId].uri = _uri;
        tokens.map[tokenId].coveredCurrency = _coveredCurrency;
        tokens.map[tokenId].coveredAmount = _coveredAmount;
        tokens.map[tokenId].premiumAmount = _premiumAmount;
        tokens.map[tokenId].coveredAddress = _coveredAddress;
        tokens.map[tokenId].utcStart = block.timestamp;
        tokens.map[tokenId].utcEnd = block.timestamp.add(_insuranceTermInDays.mul(86400));
        tokens.map[tokenId].status = ModelCovers.CoverStatus.Active;

        tokens.availables.push(tokens.map[tokenId]);

        tokens.counter.increment();

        // update totalCoveredAmount
        totalCoveredAmounts[_coveredCurrency] = totalCoveredAmounts[_coveredCurrency].add(_coveredAmount);

        return tokenId;
    }

    /**
     * @dev See {IERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(from == address(0) || to == address(0), "Soul Bound Token are not exchangeable");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    //////////
    // Privates
    //////////

    function _insuranceTokenIdExists(uint256 tokenId) private view returns (bool) {
        return _exists(tokenId)
            && tokens.map[tokenId].id == tokenId;
    }

    function _insuranceTokenURI(uint256 tokenId) private view returns (string memory) {
        return string(abi.encodePacked("ipfs://", tokens.map[tokenId].uri));
    }

}