// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../interfaces/ICheckDotInsuranceStore.sol";
import "../../interfaces/ICheckDotInsuranceRiskDataCalculator.sol";
import "../../utils/SafeMath.sol";
import "../../utils/Counters.sol";
import "../../structs/ModelCovers.sol";
import "../../token/ERC721.sol";

contract CheckDotERC721InsuranceToken is ERC721 {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct CoverTokens {
        mapping(uint256 => ModelCovers.Cover) map;
        ModelCovers.Cover[] availables;
        Counters.Counter counter;
    }

    CoverTokens private tokens;

    mapping(address => uint256) totalCoveredAmounts;

    address private store;
    address private insuranceProtocolAddress;
    address private insurancePoolFactoryAddress;
    address private insuranceRiskDataCalculatorAddress;

    function initialize(bytes memory _data) external onlyOwner {
        (address _storeAddress) = abi.decode(_data, (address));

        require(_storeAddress != address(0), "STORE_EMPTY");
        store = _storeAddress;
        if (bytes(name()).length == 0) {
            super._initialize("CDTInsurance", "ICDT");
        }
        insuranceProtocolAddress = ICheckDotInsuranceStore(store).getAddress("INSURANCE_PROTOCOL");
        insurancePoolFactoryAddress = ICheckDotInsuranceStore(store).getAddress("INSURANCE_POOL_FACTORY");
        insuranceRiskDataCalculatorAddress = ICheckDotInsuranceStore(store).getAddress("INSURANCE_RISK_DATA_CALCULATOR");
    }

    modifier onlyInsuranceProtocol {
        require(msg.sender == insuranceProtocolAddress, "Only InsuranceProtocol is allowed");
        _;
    }

    function mintInsuranceToken(uint256 _productId, address _coveredAddress, uint256 _insuranceTermInDays, uint256 _premiumAmount, address _coveredCurrency, uint256 _coveredAmount, string calldata _uri) external onlyInsuranceProtocol returns (uint256) {
        return _mintInsuranceToken(_productId, _coveredAddress, _insuranceTermInDays, _premiumAmount, _coveredCurrency, _coveredAmount, _uri);
    }

    function setClaim(uint256 _tokenId, uint256 _claimAmount, string calldata _claimProperties) external onlyInsuranceProtocol {
        require(tokens.map[_tokenId].status == ModelCovers.CoverStatus.Active, "ALREADY_IN_CLAIM");
        tokens.map[_tokenId].claimProperties = _claimProperties;
        tokens.map[_tokenId].claimPayout = _claimAmount;
        tokens.map[_tokenId].status = ModelCovers.CoverStatus.ClaimApprobation;
    }

    function revokeExpiredCovers() external payable onlyInsuranceProtocol {
        _revokeExpiredCovers();
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
     * @dev Returns the Insurance Pool Factory address.
     */
    function getInsurancePoolFactoryAddress() external view returns (address) {
        return insurancePoolFactoryAddress;
    }

    /**
     * @dev Returns the Insurance Risk Data Calculator address.
     */
    function getInsuranceRiskDataCalculatorAddress() external view returns (address) {
        return insuranceRiskDataCalculatorAddress;
    }

    /**
     * @dev Returns the ModelCovers.Cover informations by tokenId.
     */
    function getCover(uint256 tokenId) external view returns (ModelCovers.Cover memory) {
        return tokens.map[tokenId];
    }

    function coverIsAvailable(uint256 tokenId) external view returns (bool) {
        return tokens.map[tokenId].utcEnd > block.timestamp;
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
        ICheckDotInsuranceRiskDataCalculator calculator = ICheckDotInsuranceRiskDataCalculator(insuranceRiskDataCalculatorAddress);
        
        // burn expired covers tokens
        for (uint256 i = 0; i < tokens.availables.length; i++) {
            if (tokens.availables[i].utcEnd < block.timestamp) {
                revokableTokensCount++;
                tokens.availables[i].status = ModelCovers.CoverStatus.Canceled;

                // update totalCoverAmount on calculator
                calculator.subCoverAmountByCurrency(tokens.availables[i].coveredCurrency, tokens.availables[i].coveredAmount);
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

        tokens.counter.increment();

        // update totalCoverAmount on calculator
        ICheckDotInsuranceRiskDataCalculator(insuranceRiskDataCalculatorAddress).addCoverAmountByCurrency(_coveredCurrency, _coveredAmount);

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