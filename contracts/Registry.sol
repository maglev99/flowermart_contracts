pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT

import "./FlowerCoinStorage.sol";
import "./FlowerStorage.sol";

// creates and keeps track of other smart contracts 
contract Registry {
    FlowerStorage public flowerStorage;
    FlowerCoinStorage public flowerCoinStorage;

    // deploy contracts on instantiation
    constructor() {
        flowerStorage = new FlowerStorage();
        flowerCoinStorage = new FlowerCoinStorage();
    }
}