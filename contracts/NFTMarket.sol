pragma solidity ^0.8.4;
//Import the OZ ERC 731 Contract
//Can call this because we NPM installed this moduel that recognises the contract
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//Non-re-entrant prevention
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//Utility for incrementing numbers
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarket is ReentrancyGuard{
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemSold;

    address payable owner;
    uint256 listingPrice = 0.025 ether;


    constructor() 
    {
        owner = payable(msg.sender);
    }

    struct MarketItem{
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    //Mapping from Id to Market Item
    mapping(uint256 => MarketItem) private idToMarketItem;

    //Event (can listen to later)
    event MarketItemCreated(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    //Get The listing price
    function getListingPrice() public view returns (uint256){
        return listingPrice;
    }

    //
    function createMarketItem(address nftContract, uint256 tokenId, uint256 price) public payable nonReentrant 
    {
        //Make sure ammount is same as listing
        require (price > 0, "Price must be at least 1 wei");
        require (msg.value == listingPrice, "Price Must be equal to listing price");

        //Increment Item Id
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        //Create the market Item at new item ID in the mapping
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)), //Address with 0 = empty address
            price,
            false
            );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);


        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
            );
    }

    function createMarketSale(address nftContract, uint itemId) public payable nonReentrant 
    {
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;

        //Check Price
        require(msg.value == price, "Please Submit the asking price in order to complete the purchase");

        //Transfers the amount to the sellers address
        idToMarketItem[itemId].seller.transfer(msg.value);

        //Transfer the ownership of the NFT
        IERC721(nftContract).transferFrom(address(this), msg.sender , tokenId);
        //Update the mapping with new owner
        idToMarketItem[itemId].owner = payable(msg.sender);
        //Update mapping to item sold
        idToMarketItem[itemId].sold = true;
        //Increase number of Items sold
        _itemSold.increment();
        payable(owner).transfer(listingPrice);
    }

    function fetchMarketItems() public view returns (MarketItem[] memory)
    {
        //Get Items Count
        uint itemCount = _itemIds.current();
        //Unsold Items Count
        uint unsoldItemCount = _itemIds.current() - _itemSold.current();
        //Index of new array for inserting items
        uint currentIndex = 0;

        //Array of Market items length == unsold items 
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);

        //Loop through all Items
        for(uint i = 0; i < itemCount; i++)
        {
            //If Not been sold
            if(idToMarketItem[i + 1].owner == address(0))
            {
                uint currentId = idToMarketItem[i + 1].itemId;
                //Pointer to Market Item from mapping
                MarketItem storage currentItem = idToMarketItem[currentId];
                //Insert Item to Array
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        //Return Items array
        return items;
    }

    function fetchMyNFTs() public view returns(MarketItem[] memory)
    {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        //Get Ammount of Items owned by msg sender
        for(uint i = 0; i < totalItemCount; i++)
        {
            if(idToMarketItem[i + 1].owner == msg.sender)
            {
                itemCount++;
            }
        }

        //New Array of Market Items, size == amount of NFTs msg sender owns
        MarketItem[] memory items = new MarketItem[](itemCount);

        //Add owned items to the array
        for(uint i =0 ; i < totalItemCount; i++)
        {

            if(idToMarketItem[i + 1].owner == msg.sender)
            {
                uint currentId = idToMarketItem[i+1].itemId;
                //Pointer to market Item
                MarketItem storage currentItem = idToMarketItem[currentId];
                //Add item to array
                items[currentIndex] = currentItem;
                //increase index
                currentIndex++;
            }
        }
        return items;
    }

    function fetchItemsCreated() public view returns (MarketItem[] memory)
    {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        //Get Ammount of Items selling by msg sender
        for(uint i = 0; i < totalItemCount; i++)
        {
            if(idToMarketItem[i + 1].seller == msg.sender)
            {
                itemCount++;
            }
        }

        //New Array of Market Items, size == amount of NFTs msg sender selling
        MarketItem[] memory items = new MarketItem[](itemCount);

        //Add owned items to the array
        for(uint i =0 ; i < totalItemCount; i++)
        {

            if(idToMarketItem[i + 1].seller == msg.sender)
            {
                uint currentId = idToMarketItem[i+1].itemId;
                //Pointer to market Item
                MarketItem storage currentItem = idToMarketItem[currentId];
                //Add item to array
                items[currentIndex] = currentItem;
                //increase index
                currentIndex++;
            }
        }
        return items;
    }
}