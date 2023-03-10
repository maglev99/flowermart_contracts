pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "./FlowerCoinStorage.sol";
import "./FlowerStorage.sol";

// handles minting (for now) and transfer and sending expired flower tokens to burn address 
contract FlowerConductor is Ownable {
    FlowerStorage public flowerStorage;
    FlowerCoinStorage public flowerCoinStorage;

    // time to expire when calling flower token actions
    uint256 public timeToExpire = 30;

    // exchange rate for burning flower token to mint flowerCoin
    uint256 public flowersPerFlowerCoin = 1;

    // TODO: Add events

    constructor(address flowerStorageAddress, address flowerCoinStorageAddress) {
        // Set the deployer as the initial owner
        transferOwnership(msg.sender);

        // set flowerStorage address
        flowerStorage = FlowerStorage(flowerStorageAddress);

        // set flowerCoinStorage address
        flowerCoinStorage = FlowerCoinStorage(flowerCoinStorageAddress);
    }

    // view functions for Flower
    function FlowerTotalBalance(address addr) external view returns (uint256) {
        return flowerStorage.totalBalances(addr);
    }

    function FlowerTotalSupply() external view returns (uint256) {
        return flowerStorage.totalSupply();
    }

    function FlowerTotalExpired() external view returns (uint256) {
        return flowerStorage.totalExpired();
    }

    function FlowerTotalBurned() external view returns (uint256) {
        return flowerStorage.totalBurned();
    }

    // TODO: get a set number/all nodes for an address in flowerStorage to know how many tokens are expiring when

    // view functions for FlowerCoin
    function FlowerCoinTotalBalance(address addr) external view returns (uint256) {
        return flowerCoinStorage.totalBalances(addr);
    }

    function FlowerCoinTotalSupply() external view returns (uint256) {
        return flowerCoinStorage.totalSupply();
    }

    function FlowerCoinTotalBurned() external view returns (uint256) {
        return flowerCoinStorage.totalBurned();
    }

    // set time that flower tokens will expire
    // affects all flower tokens in storage as time to expire passed into expiry function in flowerStorage
    function setTimeToExpire(uint256 time) public onlyOwner {
        timeToExpire = time;
    }

    // set exchange rate for burning flower token and minting flower coin
        function setFlowersPerFlowerCoin(uint256 amount) public onlyOwner {
        flowersPerFlowerCoin = amount;
    }

    // expire flower
    function expireFlower(address addr) public onlyOwner {
        flowerStorage.expire(addr, timeToExpire);
    }

    // mint flower 
    function mintFlower(address addr, uint256 amount) public onlyOwner {
        flowerStorage.mint(addr, amount, timeToExpire);
    }

    // burn flower
    function burnFlower(address addr, uint256 amount) public onlyOwner {
        flowerStorage.burn(addr, amount, timeToExpire);
    }

    // mint flower coins 
    function mintFlowerCoin(address to, uint256 amount) public onlyOwner {
        flowerCoinStorage.mint(to, amount);
    }

    // burn flower coins
     function burnFlowerCoin(address addr, uint256 amount) public onlyOwner {
        flowerCoinStorage.burn(addr, amount);
    }

    // mint flower coins by burning flower tokens
    function mintFlowerCoinWithFlower(address to, uint256 amount) public {
        // burn flower tokens in from address 
        burnFlower(msg.sender, amount * flowersPerFlowerCoin);
        // mint flowerCoins to address
        // flowerCoins should only stay in the flowerCoinStorage contract and the contract keeps a mapping of who has what amount
        flowerCoinStorage.mint(to, amount);
    }

    // transfer flower coins 
    function transferFlowerCoin(address to, uint256 amount) public {
        flowerCoinStorage.transfer(msg.sender, to, amount);
    }

    // transfer both flower and flowercoins at once 
    function transfer(address to, uint256 flowerAmount, uint256 flowerCoinAmount) public {
        mintFlowerCoinWithFlower(to, flowerAmount);
        transferFlowerCoin(to, flowerCoinAmount);
    }

}
