pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Flower is ERC20, Ownable {
    // only addresses that map to true can mint
    mapping(address => bool) public minters;

    constructor() ERC20("Flower", "FLOWER") {
       // Set the deployer as the initial owner
        transferOwnership(msg.sender);
    }

    // modifier that limits to only minter can perform action
    modifier onlyMinter() {
        require(minters[msg.sender] == true, "Only minters can perform action");
        _;
    }

    function addMinter(address _addr) public onlyOwner {
        minters[_addr] = true;
    }

    function removeMinter(address _addr) public onlyOwner {
        minters[_addr] = false;
    }

    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }
}
