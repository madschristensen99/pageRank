// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0


pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";

contract ethersTest {
    struct linky {
        uint totalBalance;
        mapping (address => uint) stakerBalance;
    }
    mapping (string => linky) urlHolders;
    function addToLink (string calldata link, string calldata optionalInput) public payable {
        // if url does not exist
        if (urlHolders[link].totalBalance == 0){
            // if the code gets here, then the url is not found. Add the url and the msg.sender/msg.value
            urlHolders[link].stakerBalance[msg.sender] = msg.value;
            urlHolders[link].totalBalance = msg.value;
            emit Deposit("New Link", msg.value, link);
        }
        else{
            urlHolders[link].stakerBalance[msg.sender] += msg.value;
            urlHolders[link].totalBalance += msg.value;
            emit Deposit(optionalInput, msg.value, link);
        }
    }

   function withdraw(string calldata url) public payable{
        // sends money back to person who staked
        msg.sender.call{value: urlHolders[url].stakerBalance[msg.sender]}("");
    }

    //Declare an Event.
    event Deposit(string testMessage, uint msgVal, string relevantUrl);
 
}
