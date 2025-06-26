# 🗳️ Ballot - Decentralized Voting Smart Contract

A one-time-use decentralized voting smart contract built with Solidity. Designed for secure, transparent elections with no chance of vote manipulation.

## ✍️ Author

> [0xfeoski (Santhosh K)](https://github.com/feoski)

---

## 🚀 Features

- ✅ One-time election system
- 👤 Only owner can add candidates and control election state
- 📦 Voter can vote only once
- 🔒 Cannot vote before election starts or after it ends
- 📣 Emits events on key actions
- 🧪 Fully tested with Foundry

---

## 🔐 Requirements

- Solidity `^0.8.25`
- Foundry (for testing)
- OpenZeppelin `Ownable`

---

## 🛠 Functions

### 👑 Owner-only

| Function | Description |
|---------|-------------|
| `addCandidate(string name, string party)` | Adds a new candidate |
| `startElection()` | Starts the election |
| `endElection()` | Ends the election |
| `declareWinner()` | Declares the winner based on vote count |

### 🧑‍🤝‍🧑 Public

| Function | Description |
|----------|-------------|
| `voteFor(string name, string party)` | Vote for a candidate |
| `getAllCandidates()` | View all candidates with votes |
| `getElectionState()` | Returns the current election state |
| `s_winner()` | View the declared winner (after election ends) |

---

## 🧪 Tests Overview

All critical paths and edge cases are covered using Foundry:

- Adding single/multiple candidates
- Owner-only protection
- Reverts on:
  - Adding duplicate candidates
  - Voting twice
  - Invalid candidates
  - Declaring winner more than once
  - Starting/ending election at invalid times
- Vote count tracking and winner declaration
- Full event assertion for all actions

---

## ❌ Known Limitations

- 🚫 No tie resolution — first highest vote wins.
- 🔤 Case-sensitive `name` and `party` identifiers.
- 🧑 No voter identity tracking (by default).

---

## 📂 Directory Structure

```
.
├── src/
│   └── Ballot.sol
├── test/
│   └── TestBallot.t.sol
├── script/
│   └── DeployBallot.s.sol
└── foundry.toml
```

---

## 🧱 Built With

- [Foundry](https://book.getfoundry.sh/)
- [Solidity](https://soliditylang.org/)
- [OpenZeppelin](https://docs.openzeppelin.com/contracts/4.x/access-control)

---

## 📜 License

[MIT](LICENSE)
