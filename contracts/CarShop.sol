//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract myCarShop is ReentrancyGuard,Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemSold;

    struct car{
        uint256 itemId;
        address nftAddress;
        uint256 tokenId;
        string category;
        uint256 price;
        uint256 status;
        address payable seller;
        address payable owner;
    }

    uint256 public marketFee; //Total 1000

    mapping (uint256 => car) private idToCar;

    event carListed(uint256 indexed itemId,address indexed owner);
    event carSold(uint256 indexed itemId,address indexed newOwner);

    function setMarketFee(uint256 _fee) public onlyOwner {
        marketFee = _fee;
    }

    function withdraw() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function listMyCar(uint256 _price, string memory _category,address carNFT, uint256 _tokenId) external {
        require(IERC721(carNFT).ownerOf(_tokenId)==msg.sender, "Not your car to sell!");
        require(_price > 0, "We dont sell cars for free!");
        _itemIds.increment();
        uint256 _itemId = _itemIds.current();
        IERC721(carNFT).transferFrom(msg.sender, address(this), _tokenId); //Needs to be approved before calling
        idToCar[_itemId] = car(
            _itemId,
            carNFT,
            _tokenId,
            _category,
            _price,
            0,
            payable(msg.sender),
            payable(address(0))   //Not sold yet
        );
        emit carListed(_itemId,msg.sender);

    } 
    function carSale(address carNFT, uint256 _itemId) public payable nonReentrant {
        uint256 _price = idToCar[_itemId].price;
        uint256 _tokenId = idToCar[_itemId].tokenId;
        require(msg.value == _price, "Paid price is not correct!");
        uint256 fee = marketFee * _price/1000;
        idToCar[_itemId].seller.transfer(msg.value - fee); 
        IERC721(carNFT).transferFrom(address(this), msg.sender, _tokenId);
        idToCar[_itemId].status = 1;
        idToCar[_itemId].owner = payable(msg.sender);
        idToCar[_itemId].seller = payable(address(0));
        _itemSold.increment();
        emit carSold(_itemId,msg.sender);
    }

    function salesMade() public view returns(uint256,uint256) {
        return (_itemSold.current(), address(this).balance);
    }

    function getMarketItem(uint256 _itemId) public view returns(car memory){
        return idToCar[_itemId];
    }
}