// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../interfaces/ICheckDotInsuranceStore.sol";
import "../../utils/SafeMath.sol";
import "../../utils/Counters.sol";
import "../../structs/ModelInsurances.sol";
import "../../token/ERC721.sol";

contract CheckDotERC721InsuranceToken is ERC721 {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct InsuranceTokens {
        mapping(uint256 => ModelInsurances.Insurance) map;
        ModelInsurances.Insurance[] availables;
        Counters.Counter counter;
    }

    InsuranceTokens private tokens;

    address private store;

    function initialize() external payable onlyOwner {
        super._initialize("CDTInsurance", "ICDT");
    }

    modifier onlyInsuranceProtocol {
        require(msg.sender == _getInsuranceProtocolAddress(), "Only InsuranceProtocol is allowed");
        _;
    }

    function setStore(address _store) external onlyOwner {
        require(store == address(0), "ALREADY_INITIALIZED");
        store = _store;
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
        return _getInsuranceProtocolAddress();
    }

    /**
     * @dev Returns the Insurance Pool Factory address.
     */
    function getInsurancePoolFactoryAddress() external view returns (address) {
        return _getInsurancePoolFactoryAddress();
    }

    function getCover(uint256 _id) external view returns (ModelInsurances.Insurance memory) {
        return tokens.map[_id];
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

    function _revokeExpiredInsurances() internal virtual {
        uint256 revokableTokensCount = 0;
        
        // burn expired insurances tokens
        for (uint256 i = 0; i < tokens.availables.length; i++) {
            if (tokens.availables[i].utcEnd < block.timestamp) {
                revokableTokensCount++;
                tokens.availables[i].status = ModelInsurances.InsuranceStatus.Canceled;
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
    function _mintInsuranceToken(address _coveredAddress, uint256 _insuranceTermInDays, uint256 _premiumAmount, address _coveredCurrency, uint256 _coveredAmount, string calldata _uri) internal virtual {
        require(bytes(_uri).length > 0, "URI doesn't exists on product");
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned, so we need a separate counter.
        uint256 tokenId = tokens.counter.current();

        _mint(_coveredAddress, tokenId);

        tokens.map[tokenId].id = tokenId;
        tokens.map[tokenId].uri = _uri;
        tokens.map[tokenId].coveredCurrency = _coveredCurrency;
        tokens.map[tokenId].coveredAmount = _coveredAmount;
        tokens.map[tokenId].premiumAmount = _premiumAmount;
        tokens.map[tokenId].coveredAddress = _coveredAddress;
        tokens.map[tokenId].utcStart = block.timestamp;
        tokens.map[tokenId].utcEnd = block.timestamp.add(_insuranceTermInDays.mul(86400));
        tokens.map[tokenId].status = ModelInsurances.InsuranceStatus.Active;

        tokens.counter.increment();
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

    /**
     * @dev Returns the Insurance Protocol address.
     */
    function _getInsuranceProtocolAddress() internal view returns (address) {
        return ICheckDotInsuranceStore(store).getAddress("INSURANCE_PROTOCOL");
    }

    /**
     * @dev Returns the poolsFactory address.
     */
    function _getInsurancePoolFactoryAddress() internal view returns (address) {
        return ICheckDotInsuranceStore(store).getAddress("INSURANCE_POOL_FACTORY");
    }

}