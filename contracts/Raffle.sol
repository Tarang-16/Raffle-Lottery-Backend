// Raffle
// Enter the lottery (paying some amount)
// Pick a random winner (verifiably random)
// Winner to be selected every X minutes -> completely automate
// Chainlink Oracle -> Randomness, Automated Execution (Chainlink Keeper)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/* Imports */
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "hardhat/console.sol";

/* Errors */
error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NOTOPEN();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

/**@title A sample Raffle Contract
 * @author Tarang Tyagi
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Type Declaration */
    enum RaffleState {
        OPEN, CALCULATING
    } // it's like uint256 0 = OPEN, 1 = CALCULATING

    /* State Variables */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;              // upper limit of gas to be used.
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;  // number of blocks confirmation required.
    uint32 private immutable i_callbackGasLimit;  // gas limit for any function to be reverted.
    uint32 private constant NUM_WORDS = 1;
  
    /* Lottery Variables */
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    /* Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event  WinnerPicked(address indexed player);

    /* Functions */
    constructor (address vrfCoordinatorV2, uint256 entranceFee, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit, uint256 interval) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;

    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NOTOPEN();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that the chainlink keeper nodes call
     * they look for the upkeepneeded to return true:
     * our time interval should have passed
     * the lottery should have atleast 1 player, and have some ETH
     * Our subscription is funded with LINK
     * The lottery should be in an "open" state
     */

    function checkUpkeep (bytes memory /*checkData*/) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        upkeepNeeded = (timePassed && hasBalance && hasPlayers && isOpen);
        return (upkeepNeeded,"0*0");
    }

    // requestRandomWinner has been renamed performUpkeep
    function performUpkeep (bytes calldata /* performData */) external override{  
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }     
        // Request the random number
        // Once we get it, do something with it
        // 2 transaction process
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) internal override{
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success)
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* View/Pure Functions */
    function getEntranceFee() public view returns(uint256) {
        return i_entranceFee;           
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner()public view returns(address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns(RaffleState) {
        return s_raffleState;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }


}