pragma solidity ^0.8.0;

import "./ERC20/ERC20.sol";
import "./ERC20/IERC20.sol";

contract ETHBank {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier isOwner {
        require(msg.sender == _owner);
        _;
    }

    event successfullyChangedOwner(address from, address to);

    function transferOwnerShip(address addr) public isOwner {
        _owner = addr;
        emit successfullyChangedOwner(msg.sender, addr);
    }
    
    modifier checkAddress(address addr) {
        require(addr != address(0), "Token address must not be zero");
        require(isContract(addr), "Address must be of contract");
        _;        
    }   

    function isContract(address addr) private view returns(bool) {
        uint codeLength;
        assembly {
            codeLength := extcodesize(addr)
        }
        return codeLength == 0 ? false : true;
    }

    // userAddress => tokenAddress => token amount
    mapping (address => mapping (address => uint256)) userTokenBalance;

    event tokenDepositComplete(address tokenAddress, uint256 amount);

    function depositToken(address _tokenAddress, uint256 amount) public checkAddress(_tokenAddress) {
        require(IERC20(_tokenAddress).balanceOf(msg.sender) >= amount, "Your token amount must be greater then you are trying to deposit");
        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount));
        userTokenBalance[msg.sender][_tokenAddress] += amount;
        emit tokenDepositComplete(_tokenAddress, amount);
    }

    event tokenWithdrawalComplete(address tokenAddress, uint256 amount);

    function withDrawAll(address _tokenAddress) public checkAddress(_tokenAddress) {
        require(userTokenBalance[msg.sender][_tokenAddress] >= 0);
        uint256 amount = userTokenBalance[msg.sender][_tokenAddress];
        IERC20(_tokenAddress).transfer(msg.sender, amount);
        emit tokenWithdrawalComplete(_tokenAddress, amount);
    }

    function withDrawAmount(address _tokenAddress, uint256 amount) public checkAddress(_tokenAddress) {
        require(userTokenBalance[msg.sender][_tokenAddress] >= amount);
        IERC20(_tokenAddress).transfer(msg.sender, amount);
        emit tokenWithdrawalComplete(_tokenAddress, amount);
    }

    mapping (address => uint256) ethAmount;

    event ethDepositSuccessFully(address by, uint256 amount);

    function depositETH() public payable {
        require(msg.value > 0 ether);
        ethAmount[msg.sender] += msg.value;
        emit ethDepositSuccessFully(msg.sender, msg.value);
    }

    event ethWithDrawSuccessFully(address by, uint256 amount);

    function withDrawETH() public payable {
        require(ethAmount[msg.sender] > 0);
        uint256 amount = ethAmount[msg.sender];
        payable(msg.sender).transfer(amount);
        ethAmount[msg.sender] = 0;
        emit ethWithDrawSuccessFully(msg.sender, amount);
    }

    receive() external payable {}
}