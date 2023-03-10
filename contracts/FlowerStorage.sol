pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT

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

    // timed balance node (TBNode) struct that represents balance by timestamp
    struct TBNode {
        uint256 timestamp;
        uint256 balance;
        uint256 next;
    }

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

    // add a node to TBNode linked list when a user picks flowers
    function addNode(address addr, uint256 timestamp, uint256 balance) private {
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

    // TODO: move expire , mint burn into flower conductor
    // remove expired TBNodes based on time to expire
    function expire(address addr, uint256 timeToExpire) public onlyOwner {
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
        // update total supply of tokens
        totalSupply -= totalTokensExpired;
        // update total expired tokens
        totalExpired += totalTokensExpired;
    }

    // NOTE: think about separating just storage to separate contract
    // mint flower tokens to address
    function mint(address addr, uint256 amount, uint256 timeToExpire) public onlyOwner {
        // remove expired tokens before adding new ones
        expire(addr, timeToExpire);

        //set time added
        uint256 timeAdded = block.timestamp;
        // add tokens and timestamp to linked list
        addNode(addr, timeAdded, amount);
        // update total balance in address
        totalBalances[addr] += amount;
        // update total supply of tokens
        totalSupply += amount;
    }

    // burn tokens from address such as when burning Flower Token to mint Flower Coin
    // iterate through mapping starting from first node to remove flower tokens 
    function burn(address addr, uint256 amount, uint256 timeToExpire) public onlyOwner {
        // remove expired tokens first
        // NOTE: tokens not actually removed if require statement below fails since whole transaction reverts
        expire(addr, timeToExpire);

        // require amount remaining after removing expired tokens to be enough to burn
        require(totalBalances[addr] >= amount, "Not enough tokens to burn");

        // get current index and node to iterate
        uint256 currentIndex =  firstTBNode[addr];
        TBNode memory currentNode = tbNodeByIndex[addr][currentIndex];

        // create temp variable for counting number of tokens that have been burned by node
        uint256 amountBurned = 0;

        // iterate through nodes until amount burned equals amount 
        while (amountBurned < amount)
        {
            // get difference between amount and amount burned
            uint256 diff = amount - amountBurned;

            // empty and remove current node if it contains tokens less than or equal to amount
            if (diff >= currentNode.balance)
            {
                // add current node balance to amount burned 
                amountBurned += currentNode.balance;

                // remove the node from the tbNodeByIndex mapping
                delete tbNodeByIndex[addr][currentIndex];

                // set firstTBNode to next node
                firstTBNode[addr] = currentNode.next;
                // if node is the only node availble set lastTBNode to next node (which is 0)
                if (lastTBNode[addr] == currentIndex)
                {
                    lastTBNode[addr] = currentNode.next;
                }

                // set current index to next node
                currentIndex = currentNode.next;
                currentNode = tbNodeByIndex[addr][currentIndex];          
            }

            // if difference in balance less than node balance subtract difference from balance 
            else
            {
                // update the amount burned
                amountBurned += diff;
                // update the balance of the node to subtract
                tbNodeByIndex[addr][currentIndex].balance -= diff;
            }
        }

        // update total balance in address to subract burned tokens 
        totalBalances[addr] -= amountBurned;
        // update total supply of tokens
        totalSupply -= amountBurned;
        // update total burned tokens
        totalBurned += amountBurned;
    }
}