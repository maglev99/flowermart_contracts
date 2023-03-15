pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT

import "./FlowerCoinStorage.sol";
import "./FlowerStorage.sol";
import "./FlowerConductor.sol";

// creates and keeps track of other smart contracts 
contract Registry {
    FlowerStorage public flowerStorage;
    FlowerCoinStorage public flowerCoinStorage;
    FlowerConductor public flowerConductor;

    // deploy contracts on instantiation
    constructor() {
        flowerStorage = new FlowerStorage();
        flowerCoinStorage = new FlowerCoinStorage();
        flowerConductor = new FlowerConductor(address(flowerStorage), address(flowerCoinStorage));

        // set owners of flowerStorage and flowerCoinStorage contracts
        flowerStorage.transferOwnership(address(flowerConductor));
        flowerCoinStorage.transferOwnership(address(flowerConductor));
    }
}