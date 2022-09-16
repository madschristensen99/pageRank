// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";

contract pageRank {
    // The first thing we need for rankings on a list is the basic structure for an item on a list
    struct listItem {
        string listItemName;
        uint votes;
    }
    // secondly we create a collection of these list items to form a Ranked List
    struct rankedList {
        listItem [] listItems;
        string listName;
        // every list has an assosiated owner book containing the owners and how much they have deposited into the list
        ownershipStake [] owners;
    }
    // Each list has owners which share stakes in the list
    struct ownershipStake {
        address owner;
        uint amountStaked;
    }
    // In order to form a list, a user submits the name of the list and initial items desired to be in the list
   function formList(string memory listName, string [] memory listItems) public payable{
       require(formedLists[listName].owners.length == 0, "list already exists");
       require(msg.value > 99, "Not enough dough");
       rankedList memory newRankedList;
       newRankedList.listName = listName;
       // loop that adds listItems in with Votes built in
       for(uint i = 0; i < listItems.length; i++){
            newRankedList.listItems[i].listItemName = listItems [i];
            newRankedList.listItems[i].votes = listItems.length - i;
       }
       emit listFormation(newRankedList);
        newRankedList.owners[0].owner = msg.sender;
        newRankedList.owners[0].amountStaked = msg.value;
   }
   // To append the list, the name of the list and the list item are required as well as a payment to the current list owners
   event listAppend(string listHasBeenAddedTo);
   function appendList(string memory listToAppend, string memory newListItem) public payable{
       require(msg.value >= totalListValue(formedLists[listToAppend]), "Not enough ETH sent");
       // require that newListItem is not already in the list
        for (uint i = 0; i < formedLists[listToAppend].listItems.length; i ++){
            require(keccak256(abi.encodePacked(formedLists[listToAppend].listItems[i].listItemName)) != keccak256(abi.encodePacked(newListItem)));
        }
        // Spread funds to current list owners
        for (uint i = 0; i < formedLists[listToAppend].owners.length; i ++){
            formedLists[listToAppend].owners[i].owner.call{value: formedLists[listToAppend].owners[i].amountStaked}("");
        }
        // announce appendation
        emit listAppend(newListItem);
        // add to list
        formedLists[listToAppend].listItems[formedLists[listToAppend].listItems.length].listItemName = newListItem;
        formedLists[listToAppend].listItems[formedLists[listToAppend].listItems.length].votes = 0;
   }
   // It is necessary to allow users to withdraw funds from a list
   function withdraw(rankedList memory listToBeWithdrawnFrom) public {
       require(hasStake(listToBeWithdrawnFrom, msg.sender), "Does not hold ETH in this list");
       uint i = 0;
       for(; i < listToBeWithdrawnFrom.owners.length; i++){
           if(listToBeWithdrawnFrom.owners[i].owner == msg.sender){
               break;
           }
       }
       msg.sender.call{value: listToBeWithdrawnFrom.owners[i].amountStaked}("");
   }
    mapping(string => rankedList) formedLists;

    function hasStake(rankedList memory listToBeVotedOn, address voter) internal pure returns(bool){
        for(uint i = 0; i < listToBeVotedOn.owners.length; i++){
            if(listToBeVotedOn.owners[i].owner == voter){
                return true;
            }
        }
        return false;
    }
    // function that sums up value staked in a list
    function totalListValue(rankedList memory list) internal pure returns(uint){
        uint sum = list.owners[0].amountStaked;
        for(uint i = 1; i < list.owners.length; i ++){
            sum += list.owners[i].amountStaked;
        }
        return sum;
    }
    function deposit(uint256 amount) payable public {
      require(msg.value == amount);
    }   
   event listFormation(rankedList newList);
   struct ballot {
       uint timeOfCreation;
       uint ballotID;
       address voter;
       string nameOfList;
       string [5][2] matchups;
       uint [5] selections;
   }
   function hasVoted (address potentialVoter) internal view returns(bool){
       for(uint i = createdBallots.length; createdBallots[i].timeOfCreation + 86400 > block.timestamp; i--){
           if(createdBallots[i].voter == potentialVoter){
               return true;
           }
       }
       return false;
   }
    function random(uint number, uint secondNum, uint thirdNum) internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp * thirdNum,block.difficulty * secondNum,  
        msg.sender))) % number;
    }
   function createBallot(rankedList memory listToBeVotedOn) public returns(ballot memory){
       require(formedLists[listToBeVotedOn.listName].listItems.length > 1, "List does not exist");
       require(hasStake(listToBeVotedOn, msg.sender), "Does not hold a stake");
       require(!hasVoted(msg.sender), "Already voted today");
       ballot memory newBallot;
        // make sure nobody can ever have more than five votes
       // distribute five random matchups for the voter to vote on
       newBallot.timeOfCreation = block.timestamp;
       newBallot.ballotID = createdBallots.length;
       newBallot.voter = msg.sender;
       newBallot.nameOfList = listToBeVotedOn.listName;
       for(uint j = 0; j <5; j ++){
           newBallot.matchups [j][0] = listToBeVotedOn.listItems[random(listToBeVotedOn.listItems.length, j, 3)].listItemName;
           newBallot.matchups [j][1] = listToBeVotedOn.listItems[random(listToBeVotedOn.listItems.length, j, 7)].listItemName;
       }
       createdBallots[createdBallots.length] = newBallot;
       return(newBallot);
   }
   // increment votes function
   function incrementVotes(ballot memory ballotToBeSubmitted) internal{
       for(uint i =0; i < 5; i ++){
           for(uint j = 0; j < formedLists[ballotToBeSubmitted.nameOfList].listItems.length; j ++){
               if(  keccak256(abi.encodePacked(formedLists[ballotToBeSubmitted.nameOfList].listItems[j].listItemName)) == 
                    keccak256(abi.encodePacked(ballotToBeSubmitted.matchups[i][ballotToBeSubmitted.selections[i]]))){
                        formedLists[ballotToBeSubmitted.nameOfList].listItems[j].votes++;
               }
           }
       }
  }
   // ballotInputValid function
   function ballotInputValid(ballot memory ballotToBeSubmitted) internal view returns(bool){
        require(ballotToBeSubmitted.timeOfCreation + 86400 > block.timestamp, "Expired Ballot");
        // outer loop iterates through existing ballots to find name match
        for(uint i = createdBallots.length; createdBallots[i].timeOfCreation + 86400 > block.timestamp; i--){
            if(keccak256(abi.encodePacked(ballotToBeSubmitted.nameOfList)) == keccak256(abi.encodePacked(createdBallots[i].nameOfList))){
                // inner loop verifies ballot elements match
                for(uint cnt = 0; cnt < 5; cnt++){
                    require(ballotToBeSubmitted.selections[cnt] == 0 || ballotToBeSubmitted.selections[cnt] == 1, "Invalid vote");
                    for(uint cnt2 = 0; cnt2 < 1; cnt2 ++){
                        if(keccak256(abi.encodePacked(ballotToBeSubmitted.matchups[cnt][cnt2])) != keccak256(abi.encodePacked(createdBallots[i].matchups[cnt][cnt2]))){
                            return false;
                        }
                    }
                }
                return true;
            }
        }
        return false;
   }
   function vote(ballot memory ballotToBeSubmitted) public {
       // If ballot is valid and message is from proper ballot owner, listToBeVotedOn is altered
      require(msg.sender == ballotToBeSubmitted.voter, "Wrong Sender");
      require(ballotInputValid(ballotToBeSubmitted), "Invalid ballot");
      incrementVotes(ballotToBeSubmitted);
   }
    ballot [] createdBallots;

   // perhaps we want a struct called a vote which is generated upon a function call and only the voter can alter it
   // Why might someone send money to one of these contracts?
   // create a new list
   // append an existing list
   // defend a list from being appended (user adding extra funds to list they are already an owner of)

    // a list has a value staked in it that defneds it from alteration
    // VERSION 2: if that value is eclipsed by a nomination, the nomination is appended and list owners are rewarded
    // VERSION 2: Reward quality voters
    // VERSION 2: Dynamic governace of lists
    // Version2: Reward those who staked money in listItems that grew in votes, showing they were good at predicting
    // those who staked value in the nomination then stake it into the list
    // votes are distributed to those who seek them by variable reward 1v1 matchups

// Generate list of rankings
// methods: New ranking list, add list member, vote, 
// users rewarded for nominating a placement who goes on to move up in rankings
// Each object in the list has an assosiated amount of votes which indicates its rank in the list
// each day, votes are distrivuted to users who stake into a list
// 5 "matchups" between members of the list are generated for each voter
// The results of the matchups update the list
// The advantage is that we want to create a "mount rushmore" for things
// doesnt have to be four things, but there needs to be a finite list between which the memebers compete for placement
}
