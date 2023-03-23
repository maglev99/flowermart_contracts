pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./FlowerCoinStorage.sol";
import "./FlowerStorage.sol";
import "./FlowerFaucet.sol";
import "./TBNode.sol";

// handles minting (for now) and transfer and sending expired flower tokens to burn address 
contract FlowerConductor is Ownable, ReentrancyGuard {
    using Address for address;

    FlowerStorage public immutable flowerStorage;
    FlowerCoinStorage public immutable flowerCoinStorage;
    
    // use private variable since doesn't need to call functions of this contract
    address private flowerFaucet;

    // time to expire when calling flower token actions
    uint256 public timeToExpire = 30;

    // exchange rate for burning flower token to mint flowerCoin
    uint256 public flowersPerFlowerCoin = 1;

    // Flower Events 
    event MintFlower(address indexed _addr, uint256 indexed _timestamp, uint256 _amount);
    event ExpireFlower(address indexed _addr, uint256 indexed _timestamp, uint256 _amount);
    event BurnFlower(address indexed _addr, uint256 indexed _timestamp, uint256 _amount);

    event SetTimeToExpire(uint256 indexed _timestamp, uint256 _newTimeToExpire);

    // FlowerCoin Events
    event MintFlowerCoin(address indexed _from, address indexed _to, uint256 _amount); // use from and to address here since mint happens when there is a transfer and knowing sender/receiver address more useful 
    event BurnFlowerCoin(address indexed _addr, uint256 indexed _timestamp, uint256 _amount);   
    event TransferFlowerCoin(address indexed _from, address indexed _to, uint256 _amount);  

    // FlowerFaucet Events
    event SetFlowerFaucet(address indexed _flowerFaucetAddress);

    // FlowerConductor Events
    event SetFlowersPerFlowerCoin(uint256 indexed _timestamp, uint256 _amount);

    // MODIFIER that limits to only contract owner or flower faucet can perform action
    modifier onlyOwnerOrFlowerFaucet() {
        require(msg.sender == flowerFaucet || msg.sender == owner(), "Only owner or flower faucet can perform action");
        _;
    }

    constructor(address _flowerStorageAddress, address _flowerCoinStorageAddress) {
        // Require FlowerStorage FlowerCoinStorage FlowerFaucet to be contract addresses
        // Open Zepellin isContract function
        require(_flowerStorageAddress.isContract(), "address must be a contract");
        require(_flowerCoinStorageAddress.isContract(), "address must be a contract");
 
        // Set the deployer as the initial owner
        transferOwnership(msg.sender);

        // set flowerStorage address
        flowerStorage = FlowerStorage(_flowerStorageAddress);

        // set flowerCoinStorage address
        flowerCoinStorage = FlowerCoinStorage(_flowerCoinStorageAddress);
    }

    // VIEW functions for Flower
    function FlowerTotalBalance(address _addr) external view returns (uint256) {
        return flowerStorage.totalBalances(_addr);
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

    // Set flower faucet to new address
    function setFlowerFaucet(address _addr) public onlyOwner {
        require(_addr.isContract(), "address must be a contract");
        flowerFaucet = _addr;

        // EVENT: emit set flower faucet event
        emit SetFlowerFaucet(_addr);
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

    // set time that flower tokens will expire
    // affects all flower tokens in storage as time to expire passed into expiry function in flowerStorage
    function setTimeToExpire(uint256 _time) public onlyOwner {
        timeToExpire = _time;

        // emit event to show time to expire has changed
        emit SetTimeToExpire(block.timestamp, _time);
    }

    // set exchange rate for burning flower token and minting flower coin
    function setFlowersPerFlowerCoin(uint256 _amount) public onlyOwner {
        flowersPerFlowerCoin = _amount;

        // emit event when set new exchange rate
        emit SetFlowersPerFlowerCoin(block.timestamp, _amount);
    }

    // expire flower
    function expireFlower(address _addr) public onlyOwnerOrFlowerFaucet {
        uint256 currentIndex = flowerStorage.firstTBNode(_addr);  
        TBNode memory currentNode = flowerStorage.getTBNodeByIndex(_addr, currentIndex);

        // stores amount of tokens expired to be removed from address total balance at the end
        uint256 totalTokensExpired = 0;

        // if nodes exist iterate through and remove nodes that have expired
        while (currentIndex != 0 && currentNode.timestamp + timeToExpire <= block.timestamp)
        {
            // set firstTBNode to next node
            flowerStorage.setFirstTBNode(_addr, currentNode.next);
            // if node is the only node availble set lastTBNode to next node (which is 0)
            if (flowerStorage.lastTBNode(_addr) == currentIndex)
            {
                flowerStorage.setLastTBNode(_addr, currentNode.next);
            }

            // add add node balance to total tokens that have expired
            totalTokensExpired += currentNode.balance;
            
            // remove the node from the tbNodeByIndex mapping
            flowerStorage.removeTBNodeByIndex(_addr, currentIndex);

            // set current index to next node
            currentIndex = currentNode.next;
            currentNode = flowerStorage.getTBNodeByIndex(_addr, currentIndex);       
        }

        // update balances of flower storage on expire
        flowerStorage.updateBalanceOnExpire(_addr, totalTokensExpired);

        // EVENT: emit expire flower event
        emit ExpireFlower(_addr, block.timestamp, totalTokensExpired);
    }

    // mint flower 
    function mintFlower(address _addr, uint256 _amount) public onlyOwnerOrFlowerFaucet {
        // remove expired tokens before adding new ones
        expireFlower(_addr);

        //set time added
        uint256 timeAdded = block.timestamp;

        // update balances of flower storage on mint
        flowerStorage.updateBalanceOnMint(_addr, timeAdded, _amount);

        // EVENT: emit mint flower event
        emit MintFlower(_addr, timeAdded, _amount);
    }

    // burn flower
    // iterate through mapping starting from first node to remove flower tokens 
    function burnFlower(address _addr, uint256 _amount) public onlyOwner {
        // remove expired tokens first
        // NOTE: tokens not actually removed if require statement below fails since whole transaction reverts
        expireFlower(_addr);

        // require amount remaining after removing expired tokens to be enough to burn
        require(flowerStorage.totalBalances(_addr) >= _amount, "Not enough tokens to burn");

        // get current index and node to iterate
        uint256 currentIndex =  flowerStorage.firstTBNode(_addr);
        TBNode memory currentNode = flowerStorage.getTBNodeByIndex(_addr, currentIndex);

        // create temp variable for counting number of tokens that have been burned by node
        uint256 amountBurned = 0;

        // iterate through nodes until amount burned equals amount 
        // INFO potentially costly for gas
        while (amountBurned < _amount)
        {
            // get difference between amount and amount burned
            uint256 diff = _amount - amountBurned;

            // empty and remove current node if it contains tokens less than or equal to amount
            if (diff >= currentNode.balance)
            {
                // add current node balance to amount burned 
                amountBurned += currentNode.balance;

                // remove the node from the tbNodeByIndex mapping
                flowerStorage.removeTBNodeByIndex(_addr, currentIndex);

                // set firstTBNode to next node
                flowerStorage.setFirstTBNode(_addr, currentNode.next);
                // if node is the only node availble set lastTBNode to next node (which is 0)
                if (flowerStorage.lastTBNode(_addr) == currentIndex)
                {
                    flowerStorage.setLastTBNode(_addr, currentNode.next);
                }

                // set current index to next node
                currentIndex = currentNode.next;
                currentNode = flowerStorage.getTBNodeByIndex(_addr, currentIndex);
            }

            // if difference in balance less than node balance subtract difference from balance 
            else
            {
                // update the amount burned
                amountBurned += diff;
                // update the balance of the node to subtract
                flowerStorage.subtractTBNodeByIndexBalance(_addr, currentIndex, diff);
            }
        }

        // update balances of flower storage on burn
        flowerStorage.updateBalanceOnBurn(_addr, amountBurned);      

        // EVENT: emit burn flower event
        emit BurnFlower(_addr, block.timestamp, amountBurned);
    }

    // mint flower coins 
    function mintFlowerCoin(address _to, uint256 _amount) private {
        flowerCoinStorage.mint(_to, _amount);

        // EVENT: emit mint flower coins event
        emit MintFlowerCoin(msg.sender, _to, _amount);
    }

    // burn flower coins
     function burnFlowerCoin(address _addr, uint256 _amount) private {
        flowerCoinStorage.burn(_addr, _amount);

        // EVENT: burn mint flower coins event
        emit BurnFlowerCoin(_addr, block.timestamp, _amount);
    }

    // mint flower coins by burning flower tokens
    function mintFlowerCoinWithFlower(address _to, uint256 _amount) public nonReentrant {
        // burn flower tokens in from address 
        burnFlower(msg.sender, _amount * flowersPerFlowerCoin);
        // mint flowerCoins to address
        mintFlowerCoin(_to, _amount);
    }

    // transfer flower coins 
    function transferFlowerCoin(address _to, uint256 _amount) public nonReentrant {
        flowerCoinStorage.transfer(msg.sender, _to, _amount);

        // EVENT: emit transfer flower coin event
        emit TransferFlowerCoin(msg.sender, _to, _amount);
    }

    // transfer both flower and flowercoins at once 
    function transfer(address _to, uint256 _flowerAmount, uint256 _flowerCoinAmount) public nonReentrant {
        // transfer flowercoins that are minted using sender's flower balance
        mintFlowerCoinWithFlower(_to, _flowerAmount);

        // transfer flowercoins from sender's flowercoin balance
        flowerCoinStorage.transfer(msg.sender, _to, _flowerCoinAmount);

        // EVENT: emit transfer flower coin event
        emit TransferFlowerCoin(msg.sender, _to, _flowerCoinAmount);
    }
}
