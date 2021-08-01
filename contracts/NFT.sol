pragma solidity ^0.8.4;

//Import the OZ ERC 731 Contract
//Can call this because we NPM installed this moduel that recognises the contract
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//Gives set Token URI
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

//Utility for incrementing numbers
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;

    constructor(address marketPlaceAddress) ERC721("Metaverse Tokens", "METT")
    {
        //Assign Marketplace Address
        contractAddress = marketPlaceAddress;
    }

    function createToken(string memory tokenURI) public returns(uint)
    {
        //Increment Token Ids
        _tokenIds.increment();
        //Assign the new Token ID
        uint256 newItemId = _tokenIds.current();
        //Mint the token
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        //Gives marketplace permission to transact this token between users
        setApprovalForAll(contractAddress, true);

        return newItemId;
    }
}
