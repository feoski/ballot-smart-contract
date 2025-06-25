# Decentralized Voting System

## Description
A decentralized ballot to conduct the election without a centralized system manipulating it. Ballot can add candidates to it, People can cast their votes to their favourite candidate and get the result once the election is concluded without a middle man manipulation.


## Usage
### Adding candidates
Every ballot needs candidates for people to choose. Using the 'AddedCandidate' function only owner can add candidates to the ballot. This function uses another modifier 'checkCandidate' to avoid adding same candidate twice and avoid adding candidate once the election started.

### Vote
A ballot is used to cast votes in an election, allowing voters to select candidates while maintaining secrecy. Using voteFor() function people can really vote for their favourite candidate. And modifier 'checkVoter' to avoid same voter voting twice and avoid voting before election starts and after election ends.

### Declaring winner
Every election concludes with declaring the majority as winner. Using declareWinner() function only owner (maybe head of election commision) can declare the winner.

### Possible features in future
#### The tie issue:
This version of ballot can't handle (provide correct result), when two candidates got exact same number of votes, which is very rare but will be handled in future updates.

#### Reusablity (major issue yet to solve):
This version of ballot is not yet reusable once deployed, because all the storage is handled via mappings, i haven't found a way to reset the mapping cause of cliche id generation. Expect a better way to solve this issue.

## Note
This project is completely created as a hobby project. Not to disrespect the current system nor can be used as real election system replacement, YET !

## License
This project is licensed under [MIT](LICENSE). Anyone can edit, fork, distribute this project in any way.