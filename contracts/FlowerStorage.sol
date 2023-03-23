pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./TBNode.sol";

// Stores flower token in different pools 
contract FlowerStorage is Ownable {
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

    event SetFlowerConductor(address indexed _flowerConductorAddress);

    // set flower conductor
    function setFlowerConductor(address _addr) public onlyOwner {
        require(_addr.isContract(), "address must be a contract");
        flowerConductor = _addr;

        // emit event
        emit SetFlowerConductor(_addr);
    }

    // SET totalBalances 
    function addBalance(address _addr, uint256 _amount) external onlyFlowerConductor {
        totalBalances[_addr] += _amount;
    }

    function subtractBalance(address _addr, uint256 _amount) external onlyFlowerConductor {
        totalBalances[_addr] -= _amount;
    }

    // SET totalSupply 
    function addTotalSupply(uint256 _amount) external onlyFlowerConductor {
        totalSupply += _amount;
    }

    function subtractTotalSupply(uint256 _amount) external onlyFlowerConductor {
        totalSupply -= _amount;
    }

    // SET totalExpired
    function addTotalExpired(uint256 _amount) external onlyFlowerConductor {
        totalExpired += _amount;
    }

    function subtractTotalExpired(uint256 _amount) external onlyFlowerConductor {
        totalExpired -= _amount;
    }

    // SET totalBurned
    function addTotalBurned(uint256 _amount) external onlyFlowerConductor {
        totalBurned += _amount;
    }

    function subtractTotalBurned(uint256 _amount) external onlyFlowerConductor {
        totalBurned -= _amount;
    }

    // SET firstTBNode
    function setFirstTBNode(address _addr, uint256 _index) public onlyFlowerConductor {
        firstTBNode[_addr] = _index;
    }

    // SET lastTBNode
    function setLastTBNode(address _addr, uint256 _index) public onlyFlowerConductor {
        lastTBNode[_addr] = _index;
    }

    // GET tbNodeByIndex
    function getTBNodeByIndex(address _addr, uint256 _index) public view returns (TBNode memory) {
        return tbNodeByIndex[_addr][_index];
    }

    // SET tbNodeByIndex
    function subtractTBNodeByIndexBalance(address _addr, uint256 _index, uint256 _amount) external onlyFlowerConductor {
        tbNodeByIndex[_addr][_index].balance -= _amount;
    }

    function removeTBNodeByIndex(address _addr, uint256 _index) external onlyFlowerConductor {
        // remove the node from the tbNodeByIndex mapping
        delete tbNodeByIndex[_addr][_index];      
    }

    // add a node to TBNode linked list when a user picks flowers
    function addNode(address _addr, uint256 _timestamp, uint256 _balance) public onlyFlowerConductor {
        // create a new TBNode
        TBNode memory newNode = TBNode({
            timestamp: _timestamp,
            balance: _balance,
            next: 0
        });

        // get the index of the last node in the linked list
        uint256 lastIndex = lastTBNode[_addr];

        // store the new node in the tbNodeByIndex mapping with a new index
        uint256 newIndex = lastIndex + 1;
        tbNodeByIndex[_addr][newIndex] = newNode;

        // update the next field of the previous last node to point to the new node
        if (lastIndex != 0) {
            tbNodeByIndex[_addr][lastIndex].next = newIndex;
        }

        // update the lastTBNode mapping to point to the new node
        lastTBNode[_addr] = newIndex;

        // if this is the first node, also update the firstTBNode mapping to point to it
        if (firstTBNode[_addr] == 0) {
            firstTBNode[_addr] = newIndex;
        }
    }

    // batch function that runs to update token balances on expire
    function updateBalanceOnExpire(address _addr, uint256 _amount) public onlyFlowerConductor {
        // update total balance in address to subtract expired tokens 
        totalBalances[_addr] -= _amount;
        // update total supply of tokens
        totalSupply -= _amount;
        // update total expired tokens
        totalExpired += _amount;
    }

    // batch function that runs to update token balances on mint
    function updateBalanceOnMint(address _addr, uint256 _timeAdded, uint256 _amount) public onlyFlowerConductor {
        // add tokens and timestamp to linked list
        addNode(_addr, _timeAdded, _amount);
        // update total balance in address
        totalBalances[_addr] += _amount;
        // update total supply of tokens
        totalSupply += _amount;
    }

    // batch function that runs to update token balances on burn
    function updateBalanceOnBurn(address _addr, uint256 _amount) public onlyFlowerConductor {
        // update total balance in address to subract burned tokens 
        totalBalances[_addr] -= _amount;
        // update total supply of tokens
        totalSupply -= _amount;
        // update total burned tokens
        totalBurned += _amount;    
    }

}