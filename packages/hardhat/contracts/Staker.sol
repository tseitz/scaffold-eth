pragma solidity >=0.6.0 <0.7.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    uint256 deadline = now + 30 seconds;
    uint256 public constant threshold = 1 ether;
    bool public openForWithdrawal = false;
    mapping(address => uint256) public balances;

    event Stake(address, uint256);

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    modifier beforeDeadline() {
        require(now < deadline, "Too soon");
        _;
    }

    modifier afterDeadline() {
        require(now > deadline, "Too late");
        _;
    }

    modifier notCompleted() {
        require(
            exampleExternalContract.completed() == false,
            "Contract already completed"
        );
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable beforeDeadline notCompleted {
        require(msg.value > 0, "Stake amount not greater than 0");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, balances[msg.sender]);

        // execute automatically if complete
        if (deadline < now && address(this).balance >= threshold) {
            execute();
        }
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    function execute() public beforeDeadline notCompleted {
        require(
            address(this).balance >= threshold,
            "Not enough funds to execute"
        );
        exampleExternalContract.complete{value: address(this).balance}();
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    function withdraw() public afterDeadline notCompleted {
        if (!openForWithdrawal && address(this).balance < threshold) {
            openForWithdrawal = true;
        }

        if (openForWithdrawal && balances[msg.sender] > 0) {
            msg.sender.transfer(balances[msg.sender]);
        }
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (now >= deadline) {
            return 0;
        }
        return deadline - now;
    }
}
