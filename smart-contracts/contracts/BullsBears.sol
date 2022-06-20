// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract BullsBears is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    KeeperCompatibleInterface,
    VRFConsumerBaseV2
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    enum PriceTrend {BULL, BEAR}

    uint public /* immutable */ interval; // TODO: enable immutable modifier
    uint public lastTimestamp;

    AggregatorV3Interface public btcPriceFeedAggregator;
    uint256 public currentPrice;
    PriceTrend private priceTrend = PriceTrend.BULL;

    mapping(PriceTrend => string[]) private tokenUris;


    // VRF Configuration
    VRFCoordinatorV2Interface private immutable coordinator = VRFCoordinatorV2Interface(VRF_COORDINATOR);
    uint64 private subscriptionId;
    address private constant VRF_COORDINATOR = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    bytes32 private immutable keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 private immutable callbackGasLimit = 100000;
    uint16 private immutable requestConfirmations = 3;
    uint32 private numWords =  0; // changes dynamically very time setAllTokensUris is called

    event PriceTrendUpdated(string trend);

    constructor(uint updateInterval, address btcPriceFeed) ERC721("Bulls & Bears", "BnB") VRFConsumerBaseV2(VRF_COORDINATOR) {
        // keeper
        interval = updateInterval;
        lastTimestamp = block.timestamp;

        // price data feed
        btcPriceFeedAggregator = AggregatorV3Interface(btcPriceFeed);
        currentPrice = getLatestPrice();

        tokenUris[PriceTrend.BULL] = [
            "https://ipfs.io/ipfs/QmSFifprqzxcaoJznJQPUDgWsYQHuyhCSNaFhrk6p83GYG?filename=gamer_bull.json",
            "https://ipfs.io/ipfs/QmakHqXHqxESNvHzmbpRnJQNmdfAzo5MwQMZyRqkrj3psK?filename=party_bull.json",
            "https://ipfs.io/ipfs/QmRcsDtMB1uJMWPH6PRTHCRzKrwC1BrbNMqVWvnNnm4B8Y?filename=simple_bull.json"
        ];
        tokenUris[PriceTrend.BEAR] = [
            "https://ipfs.io/ipfs/QmScXgY1SRS7XFtbagVc7VtLguLhGGyjkumAR7cKNu855m?filename=beanie_bear.json",
            "https://ipfs.io/ipfs/QmQXkmc4iq138ud3PfuT74UKJYqyEJy9EpRPa9accQaoqL?filename=coolio_bear.json",
            "https://ipfs.io/ipfs/QmS6H9TskkfQ77Drd39szuNXq6kfGuGgBv2P9ZPAww3wEJ?filename=simple_bear.json"
        ];
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        string memory defaultUri = getSemiRandomTokenUri();
        _setTokenURI(tokenId, defaultUri);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage)
        returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getLatestPrice() private view returns(uint256) {
        (
            /* uint80 roundID */,
            int price,
            /* uint startedAt */,
            /* uint timeStamp */,
            /* uint80 answeredInRound */
        ) = btcPriceFeedAggregator.latestRoundData();

        return uint256(price);
    }

    function getSemiRandomTokenUri() private view returns(string memory) {
        uint idx = uint(keccak256(
            abi.encodePacked(
                block.number,
                block.timestamp,
                block.difficulty,
                msg.sender,
                msg.sig
            )
        )) % tokenUris[priceTrend].length;

        return tokenUris[priceTrend][idx];
    }

    function setAllTokensUris() private {
        uint n = _tokenIdCounter.current();
        if (subscriptionId == 0) {
            for (uint idx = 0; idx < n; ++idx ) {
                _setTokenURI(idx, getSemiRandomTokenUri());
            }
            emit PriceTrendUpdated(priceTrend == PriceTrend.BULL ? "bull" : "bear");
        } else {
            numWords = uint32(n);
            requestRandomNumbers();
        }
    }

    // Chainlink Keepers
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimestamp) > interval;

        return (upkeepNeeded, bytes(""));
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - lastTimestamp) > interval ) {
            lastTimestamp = block.timestamp;
            uint lastPrice = getLatestPrice();

            if (lastPrice != currentPrice) {
                priceTrend = lastPrice < currentPrice? PriceTrend.BEAR : PriceTrend.BULL;
                setAllTokensUris();
                currentPrice = lastPrice;
            }
        }
    }

    // Chianlink VRF
    function setVRFSubscriptionId(uint64 id) public onlyOwner {
        subscriptionId = id;
    }

    function requestRandomNumbers() private onlyOwner {
        coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
        require(_tokenIdCounter.current() == randomWords.length, "Random numbers mismatch");

        uint totalUniqueNfts = tokenUris[priceTrend].length;
        for (uint idx = 0; idx < randomWords.length; ++idx) {
            _setTokenURI(idx, tokenUris[priceTrend][randomWords[idx] % totalUniqueNfts]);
        }
    }
}
