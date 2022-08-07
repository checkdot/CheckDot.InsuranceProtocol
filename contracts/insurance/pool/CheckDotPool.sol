// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../interfaces/IERC20.sol";
import "../../interfaces/ICheckDotPool.sol";
import "../../utils/SafeMath.sol";
import "../../utils/Counters.sol";

contract CheckDotERC20 is IERC20 {
    using SafeMath for uint;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor() {
        _name = "CheckDot LPs";
        _symbol = "Cdt-LP";
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address to, uint amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        _balances[from] = _balances[from].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(from, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

}

contract CheckDotPool is CheckDotERC20 {
    using SafeMath for uint;
    using Counters for Counters.Counter;

    // --- Start Constants
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    uint8 public constant version = 1;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    // --- End Constants

    // --- Start Vars
    address public factory;
    address public token;

    uint256 private reserve;
    // --- End Vars

    constructor() CheckDotERC20() {
        factory = msg.sender;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, 'CheckDotPool: FORBIDDEN'); // sufficient check
        _;
    }

    // called once by the factory at time of deployment
    function initialize(address _token) external onlyFactory {
        token = _token;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external onlyFactory returns (uint256 liquidity) {
        uint256 _reserve = getReserves(); // gas savings
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 amount = balance.sub(_reserve);

        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = amount.sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = amount.mul(_totalSupply) / _reserve;
        }
        require(liquidity > 0, 'CheckDotPool: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);
        _update(balance);
    }

    function burn(address to) external onlyFactory returns (uint256 amount) {
        address _token = token; // gas savings
        uint256 balance = IERC20(_token).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));

        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount = liquidity.mul(balance) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount > 0, 'CheckDotPool: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(to, amount);
        sync();
    }

    function refund(address to, uint256 amount) external onlyFactory {
        _safeTransfer(to, amount);
        sync();
    }

    // force reserves to match balances
    function sync() public onlyFactory {
        _update(IERC20(token).balanceOf(address(this)));
    }

    function getReserves() public view returns (uint256) {
        return reserve;
    }

    function getFactory() public view returns (address) {
        return factory;
    }

    function getCaller() public view returns (address) {
        return msg.sender;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint256 balance) private {
        reserve = balance;
    }

    function _safeTransfer(address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'CheckDotPool: TRANSFER_FAILED');
    }

}