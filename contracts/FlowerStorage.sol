pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

// Stores flower token in different pools 
contract FlowerStorage is Ownable {
    constructor() {
        // Set the deployer as the initial owner
        transferOwnership(msg.sender);
    }

    // tracks total flower token balance of each address
    mapping ( address => uint256 ) public totalBalances;

    // timed balance node (TBNode) struct that represents balance by timestamp
    struct TBNode {
        uint256 timestamp;
        uint256 balance;
        uint256 next;
    }

    // tracks flower token balance of each address by the time it was transferred to the address for expiry function
    // maps first node of balancesByTimestamp linked list by address
    mapping(address => uint256) public firstTBNode;
    // maps last node of balancesByTimestamp linked list by address
    mapping(address => uint256) public lastTBNode;
    // stores actual nodes based on index
    mapping(address => mapping(uint256 => TBNode)) public tbNodeByIndex;

    // add a node to TBNode linked list when a user picks flowers
    function addNode(address addr, uint256 timestamp, uint256 balance) public {
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

    // remove expired TBNodes based on time to expire
    function removeExpiredTokens(address addr, uint256 timeToExpire) public {
        uint256 currentIndex =  firstTBNode[addr];
        TBNode memory currentNode = tbNodeByIndex[addr][currentIndex];

        // stores amount of tokens expired to be removed from address total balance at the end
        uint256 totalTokensExpired = 0;

        // if nodes exist iterate through and remove nodes that have expired
        while (currentIndex != 0 && currentNode.timestamp + timeToExpire <= block.timestamp)
        {
            // set firstTBNode to next node
            firstTBNode[addr] = currentNode.next;
            // if node is the only node availble set lastTBNode to next node (which is 0)
            if (lastTBNode[addr] == currentIndex)
            {
                lastTBNode[addr] = currentNode.next;
            }

            // add add node balance to total tokens that have expired
            totalTokensExpired += currentNode.balance;
            
            // remove the node from the tbNodeByIndex mapping
            delete tbNodeByIndex[addr][currentIndex];

            // set current index to next node
            currentIndex = currentNode.next;
            currentNode = tbNodeByIndex[addr][currentIndex];          
        }

        // update total balance in address to subract expired tokens 
        totalBalances[addr] -= totalTokensExpired;
    }

    // add flower tokens to address
    function addTokens(address addr, uint256 amount, uint256 timeToExpire) public {
        // remove expired tokens before adding new ones
        removeExpiredTokens(addr, timeToExpire);

        //set time added
        uint256 timeAdded = block.timestamp;
        // add tokens and timestamp to linked list
        addNode(addr, timeAdded, amount);
        // update total balance in address
        totalBalances[addr] += amount;
    }

    // TODO: (readonly) return total balance of address

    // TODO: (readonly) return all nodes of address
}