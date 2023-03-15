pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "./FlowerCoinStorage.sol";
import "./FlowerStorage.sol";
import "./TBNode.sol";

// handles minting (for now) and transfer and sending expired flower tokens to burn address 
contract FlowerConductor is Ownable {
    FlowerStorage public flowerStorage;
    FlowerCoinStorage public flowerCoinStorage;

    // time to expire when calling flower token actions
    uint256 public timeToExpire = 30;

    // exchange rate for burning flower token to mint flowerCoin
    uint256 public flowersPerFlowerCoin = 1;

    // Flower Events 
    event MintFlower(address indexed addr, uint256 indexed timestamp, uint256 amount);
    event ExpireFlower(address indexed addr, uint256 indexed timestamp, uint256 amount);
    event BurnFlower(address indexed addr, uint256 indexed timestamp, uint256 amount);

    // FlowerCoin Events
    event MintFlowerCoin(address indexed from, address indexed to, uint256 amount); // use from and to address here since mint happens when there is a transfer and knowing sender/receiver address more useful 
    event BurnFlowerCoin(address indexed addr, uint256 indexed timestamp, uint256 amount);   
    event TransferFlowerCoin(address indexed from, address indexed to, uint256 amount);  

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

    // Get a set number/all nodes for an address in flowerStorage to know how many tokens are expiring at what time
    function getBalanceNodes(address _addr, uint256 _numNodes) public view returns (TBNode[] memory) {
        // get total length of nodes in address by subtracting last and first node 
        uint head = flowerStorage.firstTBNode(_addr);
        uint256 len = flowerStorage.lastTBNode(_addr) - head + 1;
        // if num nodes to return not specified or greater than length of linked list return all nodes
        if (_numNodes == 0 || _numNodes > len) {
            _numNodes = len;
        }

        // create array of nodes
        TBNode[] memory nodes = new TBNode[](_numNodes);
        uint256 index = 0;

        // add nodes to array
        while (index < _numNodes)
        {
            nodes[index] = flowerStorage.getTBNodeByIndex(_addr, head);
            // increment head to fetch next node
            head++;
            index++;
        }

        return nodes;
    }

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
        uint256 currentIndex = flowerStorage.firstTBNode(addr);  
        TBNode memory currentNode = flowerStorage.getTBNodeByIndex(addr, currentIndex);

        // stores amount of tokens expired to be removed from address total balance at the end
        uint256 totalTokensExpired = 0;

        // if nodes exist iterate through and remove nodes that have expired
        while (currentIndex != 0 && currentNode.timestamp + timeToExpire <= block.timestamp)
        {
            // set firstTBNode to next node
            flowerStorage.setFirstTBNode(addr, currentNode.next);
            // if node is the only node availble set lastTBNode to next node (which is 0)
            if (flowerStorage.lastTBNode(addr) == currentIndex)
            {
                flowerStorage.setLastTBNode(addr, currentNode.next);
            }

            // add add node balance to total tokens that have expired
            totalTokensExpired += currentNode.balance;
            
            // remove the node from the tbNodeByIndex mapping
            flowerStorage.removeTBNodeByIndex(addr, currentIndex);

            // set current index to next node
            currentIndex = currentNode.next;
            currentNode = flowerStorage.getTBNodeByIndex(addr, currentIndex);       
        }

        // update total balance in address to subract expired tokens 
        flowerStorage.subtractBalance(addr, totalTokensExpired);

        // update total supply of tokens
        flowerStorage.subtractTotalSupply(totalTokensExpired);

        // update total expired tokens
        flowerStorage.addTotalExpired(totalTokensExpired);

        // EVENT: emit expire flower event
        emit ExpireFlower(addr, block.timestamp, totalTokensExpired);
    }

    // mint flower 
    function mintFlower(address addr, uint256 amount) public onlyOwner {
        // remove expired tokens before adding new ones
        expireFlower(addr);

        //set time added
        uint256 timeAdded = block.timestamp;
        // add tokens and timestamp to linked list
        flowerStorage.addNode(addr, timeAdded, amount);
        // update total balance in address
        flowerStorage.addBalance(addr, amount);
        // update total supply of tokens
        flowerStorage.addTotalSupply(amount);

        // EVENT: emit mint flower event
        emit MintFlower(addr, timeAdded, amount);
    }

    // burn flower
    // iterate through mapping starting from first node to remove flower tokens 
    function burnFlower(address addr, uint256 amount) public onlyOwner {
        // remove expired tokens first
        // NOTE: tokens not actually removed if require statement below fails since whole transaction reverts
        expireFlower(addr);

        // require amount remaining after removing expired tokens to be enough to burn
        require(flowerStorage.totalBalances(addr) >= amount, "Not enough tokens to burn");

        // get current index and node to iterate
        uint256 currentIndex =  flowerStorage.firstTBNode(addr);
        TBNode memory currentNode = flowerStorage.getTBNodeByIndex(addr, currentIndex);

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
                flowerStorage.removeTBNodeByIndex(addr, currentIndex);

                // set firstTBNode to next node
                flowerStorage.setFirstTBNode(addr, currentNode.next);
                // if node is the only node availble set lastTBNode to next node (which is 0)
                if (flowerStorage.lastTBNode(addr) == currentIndex)
                {
                    flowerStorage.setLastTBNode(addr, currentNode.next);
                }

                // set current index to next node
                currentIndex = currentNode.next;
                currentNode = flowerStorage.getTBNodeByIndex(addr, currentIndex);
            }

            // if difference in balance less than node balance subtract difference from balance 
            else
            {
                // update the amount burned
                amountBurned += diff;
                // update the balance of the node to subtract
                flowerStorage.subtractTBNodeByIndexBalance(addr, currentIndex, diff);
            }
        }

        // update total balance in address to subract burned tokens 
        flowerStorage.subtractBalance(addr, amountBurned);
        // update total supply of tokens
        flowerStorage.subtractTotalSupply(amountBurned);
        // update total burned tokens
        flowerStorage.addTotalBurned(amountBurned);

        // EVENT: emit burn flower event
        emit BurnFlower(addr, block.timestamp, amountBurned);
    }

    // mint flower coins 
    function mintFlowerCoin(address to, uint256 amount) public onlyOwner {
        flowerCoinStorage.mint(to, amount);

        // EVENT: emit mint flower coins event
        emit MintFlowerCoin(msg.sender, to, amount);
    }

    // burn flower coins
     function burnFlowerCoin(address addr, uint256 amount) public onlyOwner {
        flowerCoinStorage.burn(addr, amount);

        // EVENT: burn mint flower coins event
        emit BurnFlowerCoin(addr, block.timestamp, amount);
    }

    // mint flower coins by burning flower tokens
    function mintFlowerCoinWithFlower(address to, uint256 amount) public {
        // burn flower tokens in from address 
        burnFlower(msg.sender, amount * flowersPerFlowerCoin);
        // mint flowerCoins to address
        mintFlowerCoin(to, amount);
    }

    // transfer flower coins 
    function transferFlowerCoin(address to, uint256 amount) public {
        flowerCoinStorage.transfer(msg.sender, to, amount);

        // EVENT: emit transfer flower coin event
        emit TransferFlowerCoin(msg.sender, to, amount);
    }

    // transfer both flower and flowercoins at once 
    function transfer(address to, uint256 flowerAmount, uint256 flowerCoinAmount) public {
        mintFlowerCoinWithFlower(to, flowerAmount);

        transferFlowerCoin(to, flowerCoinAmount);
    }
}
