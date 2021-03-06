# Mt Pelerin Bridge Protocol Token

## At every token's core

#### A multi-layer architecture

At its deepest level, every token is an ERC20 token.
Each layer adds new features on top of the previous layer.

The Ethereum blockchain is divided between the State and the Storage.
+ The State is the current values of all smart contracts and balances.
+ The Storage contains all the blockchain history.
By design, smart contracts can only rely on data which exists in the State.
It is also where storing data is the most expensive.
The Mt Pelerin token architecture expands the information present in the State that can be reused by other contracts externally:

| Layer name | Layer description |
|   :------: |    :----------    |
| ERC20      | Token standard for defining an interface to query balance and execute transfers |
| [Auditable](https://github.com/MtPelerin/MtPelerin-protocol/blob/master/contracts/token/AuditableToken.sol) | Add the following attributes for each token holder:<br><ul><li><b>Created At</b>: First time this address held tokens</li><li><b>Last Received At</b>: Last time this address received tokens</li><li><b>Received Count</b>: Number of times this address received tokens</li><li><b>Sent Count</b>: Number of times this address sent tokens</li><li><b>Total Received</b>: Total that has been received at this address</li><li><b>Total Sent</b>: Total that has been sent from this address</li></ul>|
| [ProvableOwnership](https://github.com/MtPelerin/MtPelerin-protocol/blob/master/contracts/token/ProvableOwnershipToken.sol) | Provide the ability to generate certificates of ownership. A certificate proves the owner held a determined amount of tokens for a specific period of time. |

#### Rules

Furthermore, one layer is then added to provide the ability to restrict transferability of the token according to specific, customizable rules.
Rules must implement the [IRule](https://github.com/MtPelerin/MtPelerin-protocol/blob/master/contracts/interface/IRule.sol) interface.
Rules can then be added or removed from the token when needed.
Whenever token rules are changed, an event will be generated to help participants track the change of rules.
It is important that this information is clearly given to participants prior to any changes.

The design of such rules should imply that they should not modify the State during the validation, but only tell if a transfer (from, to, amount) is valid or not. Changing the State would deeply increase the complexity of a transfer operation and might not validate all of the ERC20 standard.

#### Claims

Rules can limit the participants' ability to transfer tokens, whereas claims provide benefits.
Claims must implement the [IClaimable](https://github.com/MtPelerin/MtPelerin-protocol/blob/master/contracts/interface/IClaimable.sol) interface.
To name few of the already designed claims:
- Token based dividends
- Token based voting (with no dedicated voting token nor transfer restrictions !)
The list of claims to be published is not exhaustive.

Mt Pelerin encourages anyone interested to provide new claims for the community! Feel free to get in touch with us and share your ideas or code.

## The legally compliant token

The Mt Pelerin token aims at being fully compliant with all regulations.
This is crucial for all regulated assets: e.g. tokenized shares, loans or fiat currencies.

Although it is definitely hard to follow precisely existing regulations, our token framework fully allows it. But it is impossible to foresee future regulations, and the rule-based approach of the Mt Pelerin token for all transfers as well as the audit capability of the token are customizable and upgradeable to allow it to adapt to new regulation.

#### Seizability by a legal authority

In some extreme situations, the rule-based approach will not be sufficient. The regulator expects a bank to be able to control and seize assets, for example when a judge orders it, in the case of proven money laundering or other criminal activity.
Mt Pelerin tokens are designed to comply with such decision.

An authority address is provided to those in charge of the decision.
The design of a [SeizableToken](https://github.com/MtPelerin/MtPelerin-protocol/blob/master/contracts/token/SeizableToken.sol) ensures that the legal authority is accountable for all its decisions. In other words, the use of the authority key is always clearly visible on chain and distinct from Mt Pelerin day-to-day operations.

## An Open API token

Smart contracts are a very powerful tool. They do behave as an open API and Mt Pelerin welcomes intiatives to provide more services around this technology.

The on chain version of Mt Pelerin tokens provides many legal and compliance services so that developers don't have to worry about this complexity and can focus on delivering solutions and services.


## Disclaimer

Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
This content cannot be used, copied or reproduced in part or in whole without the express and written permission of Mt Pelerin Group SA.
Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
All matters regarding the intellectual property of this code or software are subjects to Swiss Law without reference to its conflicts of law rules.

