pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "./FlowerCoin.sol";
import "./FlowerStorage.sol";

// handles minting (for now) and transfer and sending expired flower tokens to burn address 
contract FlowerConductor is Ownable {
    FlowerStorage public flowerStorage;
    FlowerCoin public flowerCoin;

    // time to expire when calling flower token actions
    uint256 public timeToExpire = 30;

    // exchange rate for burning flower token to mint flowerCoin
    uint256 public flowersPerFlowerCoin = 1;

    constructor(address storageAddress, address tokenAddress) {
        // Set the deployer as the initial owner
        transferOwnership(msg.sender);

        // set flowerStorage address
        flowerStorage = FlowerStorage(storageAddress);

        // set flowerCoin token address
        flowerCoin = FlowerCoin(tokenAddress);
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

    // function calls to flowerStorage
    // get calls
    // TODO: create readonly functions to get public variables from flowerStorage

    // set calls
    function removeExpiredTokens(address addr) public onlyOwner {
        flowerStorage.removeExpiredTokens(addr, timeToExpire);
    }

    function addTokens(address addr, uint256 amount) public onlyOwner {
        flowerStorage.addTokens(addr, amount, timeToExpire);
    }

    function burnTokens(address addr, uint256 amount) public onlyOwner {
        flowerStorage.burnTokens(addr, amount, timeToExpire);
    }

    // mint flower coins by burning flower tokens
    function mintFlowerCoin(address from, address to, uint256 amount) public onlyOwner {
        // burn flower tokens in from address 
        burnTokens(from, amount * flowersPerFlowerCoin);
        // mint flowerCoins to address
        // TODO: create flowerCoinStorage contract and call the mint function to that contract
        // flowerCoins should only stay in the flowerCoinStorage contract and the contract keeps a mapping of who has what amount
        flowerCoin.mint(to, amount);
    }

    // TODO: create transfer function for when paying vendor to determine how much flower + flowerCoin to transfer to vendor

}
