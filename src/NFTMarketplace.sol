// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarketplace is Ownable, ReentrancyGuard {
    using Address for address payable;

    uint private commissionPool;

    string public constant AUTHOR = "Jason Yapri";
    uint8 public constant COMMISSION = 1;

    constructor(address initialOwner) Ownable(initialOwner) {}

    struct Auction {
        address payable seller;
        uint minPrice;
        uint highestBid;
        address payable highestBidder;
        uint deadline;
        bool ended;
    }

    mapping(uint => Auction) public auctions;
    uint numOfAuctions;

    event BidPlaced(
        uint indexed auctionId,
        address indexed bidder,
        uint amount
    );
    event AuctionEnded(
        uint indexed auctionId,
        address indexed winner,
        uint amount
    );

    error InvalidMinPrice();
    error InvalidDuration();
    error AuctionDeadlineNotReached();
    error AuctionNotFound();
    error AuctionHasEnded();
    error BidTooLow();

    function createAuction(
        uint _tokenId,
        uint _minPrice,
        uint _duration
    ) external {
        if (_minPrice == 0) revert InvalidMinPrice();
        if (_duration == 0) revert InvalidDuration();

        // TODO: Store NFT
        auctions[++numOfAuctions] = Auction({
            seller: payable(msg.sender),
            minPrice: _minPrice,
            highestBid: 0,
            highestBidder: payable(address(0)),
            deadline: block.timestamp + _duration,
            ended: false
        });
    }

    function placeBid(uint _auctionId) external payable nonReentrant {
        Auction storage auction = auctions[_auctionId];

        if (auction.seller == address(0)) revert AuctionNotFound();
        if (auction.ended) revert AuctionHasEnded();
        if (auction.deadline > block.timestamp)
            revert AuctionDeadlineNotReached();
        if (msg.value < auction.minPrice || msg.value < auction.highestBid)
            revert BidTooLow();

        if (auction.highestBid != 0) {
            uint highestBid = auction.highestBid;
            auction.highestBid = 0;
            auction.highestBidder.sendValue(highestBid);
        }
        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);

        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    function endAuction(uint _auctionId) external nonReentrant {
        if (auctions[_auctionId].deadline < block.timestamp) {
            Auction storage auction = auctions[_auctionId];
            auction.ended = true;
            // TODO: Send NFT
            auction.seller.sendValue(
                (auction.highestBid * (100 - COMMISSION)) / 100
            );
            commissionPool += (auction.highestBid * COMMISSION) / 100;

            emit AuctionEnded(
                _auctionId,
                auction.highestBidder,
                auction.highestBid
            );
        } else {
            revert AuctionDeadlineNotReached();
        }
    }

    function withdrawCommission() external onlyOwner nonReentrant {
        uint commissionToBeTransferred;
        commissionPool = 0;
        payable(owner()).sendValue(commissionToBeTransferred);
    }
}
