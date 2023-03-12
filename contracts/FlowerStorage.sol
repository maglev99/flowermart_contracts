pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT
import "./TBNode.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Stores flower token in different pools 
contract FlowerStorage is Ownable {
    constructor() {
        // Set the deployer as the initial owner
        transferOwnership(msg.sender);
    }

    // separate flower storage into just this total balance
    // tracks total flower token balance of each address
    mapping ( address => uint256 ) public totalBalances;

    // tracks total supply of flower token
    uint256 public totalSupply;
    // tracks total expired flower tokens
    uint256 public totalExpired;
    // tracks total burned flower tokens
    uint256 public totalBurned;

    // tracks flower token balance of each address by the time it was transferred to the address for expiry function
    // maps first node of balancesByTimestamp linked list by address
    mapping(address => uint256) public firstTBNode;
    // maps last node of balancesByTimestamp linked list by address
    mapping(address => uint256) public lastTBNode;
    // stores actual nodes based on index
    mapping(address => mapping(uint256 => TBNode)) public tbNodeByIndex;

    // SET totalBalances 
    function addBalance(address _addr, uint256 _amount) external onlyOwner {
        totalBalances[_addr] += _amount;
    }

    function subtractBalance(address _addr, uint256 _amount) external onlyOwner {
        totalBalances[_addr] -= _amount;
    }

    // SET totalSupply 
    function addTotalSupply(uint256 _amount) external onlyOwner {
        totalSupply += _amount;
    }

    function subtractTotalSupply(uint256 _amount) external onlyOwner {
        totalSupply -= _amount;
    }

    // SET totalExpired
    function addTotalExpired(uint256 _amount) external onlyOwner {
        totalExpired += _amount;
    }

    function subtractTotalExpired(uint256 _amount) external onlyOwner {
        totalExpired -= _amount;
    }

    // SET totalBurned
    function addTotalBurned(uint256 _amount) external onlyOwner {
        totalBurned += _amount;
    }

    function subtractTotalBurned(uint256 _amount) external onlyOwner {
        totalBurned -= _amount;
    }

    // SET firstTBNode
    function setFirstTBNode(address _addr, uint256 _index) public onlyOwner {
        firstTBNode[_addr] = _index;
    }

    // SET lastTBNode
    function setLastTBNode(address _addr, uint256 _index) public onlyOwner {
        lastTBNode[_addr] = _index;
    }

    // GET tbNodeByIndex
    function getTBNodeByIndex(address _addr, uint256 _index) public view returns (TBNode memory) {
        return tbNodeByIndex[_addr][_index];
    }

    // SET tbNodeByIndex
    function subtractTBNodeByIndexBalance(address _addr, uint256 _index, uint256 _amount) external onlyOwner {
        tbNodeByIndex[_addr][_index].balance -= _amount;
    }

    function removeTBNodeByIndex(address _addr, uint256 _index) external onlyOwner {
        // remove the node from the tbNodeByIndex mapping
        delete tbNodeByIndex[_addr][_index];      
    }

    // add a node to TBNode linked list when a user picks flowers
    function addNode(address addr, uint256 timestamp, uint256 balance) public onlyOwner {
        // create a new TBNode
        TBNode memory newNode = TBNode({
            timestamp: timestamp,
            balance: balance,
            next: 0
        });

        // get the index of the last node in the linked list
        uint256 lastIndex = lastTBNode[addr];

        // store the new node in the tbNodeByIndex mapping with a new index
        uint256 newIndex = lastIndex + 1;
        tbNodeByIndex[addr][newIndex] = newNode;

        // update the next field of the previous last node to point to the new node
        if (lastIndex != 0) {
            tbNodeByIndex[addr][lastIndex].next = newIndex;
        }

        // update the lastTBNode mapping to point to the new node
        lastTBNode[addr] = newIndex;

        // if this is the first node, also update the firstTBNode mapping to point to it
        if (firstTBNode[addr] == 0) {
            firstTBNode[addr] = newIndex;
        }
    }
}