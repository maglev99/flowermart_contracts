pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Stores flower coin 
contract FlowerCoinStorage is Ownable {
    using Address for address;

    address private flowerConductor;

    constructor() {
        // Set the deployer as the initial owner
        transferOwnership(msg.sender);
    }

    // MODIFIER that limits to only flower conductor can perform action
    modifier onlyFlowerConductor() {
        require(msg.sender == flowerConductor, "Only flower conductor can perform action");
        _;
    }

    // tracks total flower coin balance of each address
    mapping ( address => uint256 ) public totalBalances;

    // tracks total supply of flower coin
    uint256 public totalSupply;
    // tracks total flower coins burned
    uint256 public totalBurned;

    // event
    event SetFlowerConductor(address indexed flowerConductorAddress);

    // set flower conductor
    function setFlowerConductor(address _addr) public onlyOwner {
        require(_addr.isContract(), "address must be a contract");
        flowerConductor = _addr;

        // emit event
        emit SetFlowerConductor(_addr);
    }

    // mint flower coins to address
    function mint(address addr, uint256 amount) public onlyFlowerConductor {
        // update total balance in address
        totalBalances[addr] += amount;
        // update total supply of tokens
        totalSupply += amount;
    }
   
    // transfer flower coins to address
    function transfer(address from, address to, uint256 amount) public onlyFlowerConductor {
        require(totalBalances[from] >= amount, "From address does not have enough FlowerCoins to transfer");

        // subtract amount from from adress
        totalBalances[from] -= amount;
        // add amount to to address
        totalBalances[to] += amount;
    }

    // burn flower coins
    function burn(address addr, uint256 amount) public onlyFlowerConductor {
        require(totalBalances[addr] >= amount, "Address does not have enough FlowerCoins to burn");

        // subtract amount from address
        totalBalances[addr] -= amount;
        // subtract amount from total supply
        totalSupply -= amount;
        // add amount to total burned
        totalBurned += amount;
    }

}