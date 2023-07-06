// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";


contract TokenTeste is ERC20Capped, ERC20Burnable {
    address payable public owner;
    uint256 public blockReward;
    address public uniswapPairAddress;
    address public uniswapRouterAddress;
    address public constant ETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public UNISWAP_ROUTER_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;


    constructor(uint256 cap, uint256 reward) ERC20("token teste", "TOT") ERC20Capped(cap * (10**decimals())) {
        owner = payable(msg.sender);
        _mint(owner, 10000000 * (10 ** decimals()));
        blockReward = reward * (10**decimals()); 

        IUniswapV2Factory uniswapFactory = IUniswapV2Factory(UNISWAP_ROUTER_ADDRESS); 
        address token1 = address(this);
        address token2 = ETH_ADDRESS; 
        uniswapPairAddress = uniswapFactory.getPair(token1, token2);
        uniswapRouterAddress = UNISWAP_ROUTER_ADDRESS; 
    } 

    /**
     * @dev Mint function overriding ERC20Capped's _mint function to enforce token supply cap.
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20Capped, ERC20) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    /**
     * @dev Internal function to mint additional tokens to the miner of the current block as a reward.
     */
    function _mintMinerReward() internal {
        _mint(block.coinbase, blockReward);
    }

    /**
     * @dev Hook function called before any token transfer.
     * Mint additional tokens as a reward to the miner if applicable.
     */
    function _beforeTokenTransfer(address from, address to, uint256 value) internal virtual override {
        if (from != address(0) && to != block.coinbase && block.coinbase != address(0)) {
            _mintMinerReward();
        }
        super._beforeTokenTransfer(from, to, value);
    }

    /**
     * @dev Set the block reward amount for miners.
     * @param reward The new block reward amount.
     */
    function setBlockReward(uint256 reward) public onlyOwner {
        blockReward = reward * (10**decimals()); 
    }

    /**
     * @dev Transfer tokens to a specified address, applying a 2% fee that is sent to the contract owner.

     */
    function transfer(address recipient, uint256 value) public virtual override returns (bool) {
        if (recipient == uniswapRouterAddress || recipient == uniswapPairAddress) {
            uint256 fee = (value * 2) / 100; // 2% fee
            uint256 netAmount = value - fee;

            _transfer(_msgSender(), recipient, netAmount);
            _transfer(_msgSender(), owner, fee);
        } else {
            _transfer(_msgSender(), recipient, value);
        }

        return true;
    }
    /**
    * @dev Transfer tokens from a specified address to another address, applying a 2% fee that is sent to the contract owner.
    * This function can only be called by a spender that has been granted an allowance by the token owner.
    */
    function transferFrom(address sender, address recipient, uint256 value) public virtual override returns (bool) {
        if (recipient == uniswapRouterAddress || recipient == uniswapPairAddress) {
            uint256 fee = (value * 2) / 100; // 2% fee
            uint256 netAmount = value - fee;

            _transfer(sender, recipient, netAmount);
            _transfer(sender, owner, fee);
            _approve(sender, _msgSender(), allowance(sender, _msgSender()) - value);
        } else {
            _transfer(sender, recipient, value);
            _approve(sender, _msgSender(), allowance(sender, _msgSender()) - value);
        }

        return true;
    }

    modifier onlyOwner{
        require(msg.sender == owner , "Only owner can call");
        _;
    }
    }