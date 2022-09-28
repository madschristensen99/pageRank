// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0


// Generate list of rankings
// users rewarded for nominating a placement which generates more interest in a list and list growth
// Each object in the list has an assosiated amount of votes which indicates its rank in the list
// each day, votes are distributed to users who stake into a list
// 5 "matchups" between members of the list are generated for each voter unless the list is small
// The results of the matchups update the list vote counts
// The goal is that we want to create a "mount rushmore" for things
// doesnt have to be four things, but there needs to be a finite list between which the members compete for placement, only people with a financial interest can vote

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
        // every list has an assosiated owner book containing the owners and how much they have deposited into the list
        ownershipStake [] owners;
    }
    // Each list has owners which share stakes in the list
    struct ownershipStake {
        address owner;
        uint amountStaked;
    }
    // Array of list names is kept
    string [] listNames;
    // Every list name/title maps to a cooresponding rankedList
    mapping(string => rankedList) formedLists;
    event listFormation(string listName, uint votes, string listHead, address owner, uint amount);
    // In order to form a list, a user submits the name of the list and initial items desired to be in the list
    function formList(string calldata listName, string calldata listHead) public payable {
        require(msg.value > 99, "Not enough dough");
        require(formedLists[listName].owners.length == 0, "list already exists");
        listNames.push(listName);
        listItem memory firstListItem;
        firstListItem.listItemName = listHead;
        firstListItem.votes = 1;
        ownershipStake memory firstOwner;
        firstOwner.owner = msg.sender;
        firstOwner.amountStaked = msg.value;
        formedLists[listName].listItems.push(firstListItem);
        formedLists[listName].owners.push(firstOwner);
        // TODO: modify event emiision so that relevant informations is posted, add getter functions
        emit listFormation(listName, firstListItem.votes, listHead, msg.sender, msg.value);
    }
   // To append the list, the name of the list and the list item are required as well as a payment to the current list owners
   event listAppend(string listHasBeenAddedTo);
   function appendList(string calldata listToAppend, string calldata newListItem) public payable{
       require(msg.value >= totalListValue(formedLists[listToAppend]), "Not enough ETH sent");
       // require that newListItem is not already in the list
        for (uint i = 0; i < formedLists[listToAppend].listItems.length; i ++){
            require(keccak256(abi.encodePacked(formedLists[listToAppend].listItems[i].listItemName)) != keccak256(abi.encodePacked(newListItem)), "item already listed");
        }
        // inputs data
        listItem memory li;
        li.listItemName = newListItem;
        li.votes = 0;
        formedLists[listToAppend].listItems.push(li);
        ownershipStake memory oS;
        oS.owner = msg.sender;
        oS.amountStaked = msg.value;
        formedLists[listToAppend].owners.push(oS);
        // Spread funds to current list owners
        for (uint i = 0; i < formedLists[listToAppend].owners.length; i ++){
            formedLists[listToAppend].owners[i].owner.call{value: formedLists[listToAppend].owners[i].amountStaked}("");
        }
 
   }
   // It is necessary to allow users to withdraw funds from a list
   function withdraw(string calldata listName) public {
       require(hasStake(listName, msg.sender), "Does not hold ETH in this list");
       uint i = 0;
       for(; i < formedLists[listName].owners.length; i++){
           if(formedLists[listName].owners[i].owner == msg.sender){
               msg.sender.call{value: formedLists[listName].owners[i].amountStaked}("");
               formedLists[listName].owners[i].amountStaked = 0;
               break;
           }
       }
   }

    function hasStake(string memory listName, address voter) internal view returns(bool){
        for(uint i = 0; i < formedLists[listName].owners.length; i++){
            if(formedLists[listName].owners[i].owner == voter &&
               formedLists[listName].owners[i].amountStaked > 100){
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
    function deposit(string calldata listName) payable public {
        ownershipStake memory newOwner;
        newOwner.owner = msg.sender;
        newOwner.amountStaked = msg.value;
       formedLists[listName].owners.push(newOwner);
    }   
   
   struct ballot {
       uint timeOfCreation;
       uint ballotID;
       address voter;
       string nameOfList;
       string [2][5] matchups;
       uint [5] selections;
   }
   function hasVoted (address potentialVoter) internal view returns(bool){
       if (createdBallots.length == 0){
           return false;
       }
       for(uint i = createdBallots.length - 1; createdBallots[i].timeOfCreation + 86400 > block.timestamp; i--){
           /*
           if(createdBallots[i].voter == potentialVoter){
               return true;
           }
           */
       }
       
       return false;

   }
    function random(uint number, uint secondNum, uint thirdNum) internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp * thirdNum,block.difficulty * secondNum,  
        msg.sender))) % number;
    }

   function createBallot(string memory listName) public returns(ballot memory){
       require(formedLists[listName].listItems.length > 2, "List does not exist or has one or two members");
       require(hasStake(listName, msg.sender), "Does not hold a stake");
       require(!hasVoted(msg.sender), "Already voted today");
       // TODO: Ensure that matchups arent with themselves or repeated
       ballot memory newBallot;
        // make sure nobody can ever have more than five votes
       // distribute five random matchups for the voter to vote on
       newBallot.timeOfCreation = block.timestamp;
       newBallot.ballotID = createdBallots.length;
       newBallot.voter = msg.sender;
       newBallot.nameOfList = listName;
       for(uint j = 0; j <5; j ++){
           newBallot.matchups [j][0] = formedLists[listName].listItems[random(formedLists[listName].listItems.length, j, 3)].listItemName;
           newBallot.matchups [j][1] = formedLists[listName].listItems[random(formedLists[listName].listItems.length, j, 7)].listItemName;
       }
       createdBallots.push(newBallot);
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
            if(keccak256(abi.encodePacked(ballotToBeSubmitted.nameOfList)) == keccak256(abi.encodePacked(createdBallots[i].nameOfList)) &&
               createdBallots[i].voter == ballotToBeSubmitted.voter){
                // inner loop verifies ballot elements match
                for(uint cnt = 0; cnt < 5; cnt++){
                    require(ballotToBeSubmitted.selections[cnt] == 1 || ballotToBeSubmitted.selections[cnt] == 2, "Invalid vote");
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
}
