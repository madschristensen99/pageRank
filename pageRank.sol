// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0
pragma solidity >=0.7.0 <0.9.0;

// probably going to be easiest for every list to have its own contract, address, could limit interop between lists
contract pageRank {
    // every item in a list has a name, a number of votes
    struct listItem {
        string listItemName;
        uint votes;
    }
    struct rankedList {
        listItem [] listItems;
        string listName;
        // every list has an assosiated owner book containing the owners and how much they have deposited into the list
        ownershipStake [] owners;
        // TODO: add a balance for each owner
    }
    // need map/assosiative array which points every name to its cooresponding list
    struct ownershipStake {
        address owner;
        uint amountStaked;
    }
    function hasStake(rankedList memory listToBeVotedOn, address voter) internal returns(bool){
        for(uint i = 0; i < listToBeVotedOn.owners.length; i++){
            if(listToBeVotedOn.owners[i].owner == voter){
                return true;
            }
        }
        return false;
    }
    // function that sums up value staked in a list
    function totalListValue(rankedList memory list) internal returns(uint){
        uint sum = list.owners[0].amountStaked;
        for(uint i = 1; i < list.owners.length; i ++){
            sum += list.owners[i].amountStaked;
        }
        return sum;
    }

   event Deposit(string depositMessage);
   function deposit(string memory listName) public payable {      
   }
   event listFormation(rankedList newList);
   function formList(string memory listName, string [] memory listItems) public payable{
       // TODO: require list does not already exist
       // TODO: require some fee to be paid/staked, minimum amount
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
   function appendList(rankedList memory listToAppend, string memory newListItem) public payable{
       require(msg.value >= totalListValue(listToAppend), "Not enough ETH sent");
        // TODO: pay existing owners of list according to shares owned
        listToAppend.listItems[listToAppend.listItems.length].listItemName = newListItem;
        listToAppend.listItems[listToAppend.listItems.length].votes = 0;
   }
   // withdraw from list function
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
   // TODO: Voting
   function getVotes(rankedList memory listToBeVotedOn) public returns(string [5][2] memory){
       // require that person has not voted today
       require(hasStake(listToBeVotedOn, msg.sender), "Does not hold a stake");
        // make sure nobody can ever have more than five votes
       // distribute five random matchups for the voter to vote on

   }
   function vote(rankedList memory listToBeVotedOn) public {
       // require voter has votes
   }
   // Why might someone send money to one of these contracts?
   // create a new list
   // append an existing list
   // defend a list from being appended (user adding extra funds to list they are already an owner of)

    // a list has a value staked in it that defneds it from alteration
    // if that value is eclipsed by a nomination, the nomination is appended and list owners are rewarded
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