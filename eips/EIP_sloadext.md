Title: Skinny SLOADEXT

## Preamble

Presently, Ethereum developers are limited to internal assembly level contract storage reads only via the `sload` opcode Contracts may only read external data by accessing pre-specified getters, which are accessible only through external third-party calls. In this EIP, I introduce a simple but powerful opcode akin to what is already available through the RPC via `eth_getStorageAt` called `sloadext` which allows any contract to read the current state storage of another contract.

## Specification

An opcode to retrieve the storage of another contract.

```
sloadext(address:u160, position:u256) -> result:u256
```

#### OpCode

SLOADEXT

#### Inputs (2)

1) `address` always 20 bytes -- the address of the target contract to load storage from
2) `position` always 32 bytes-- the storage position in the target contract (similar to `sload` `position` or `p`)

#### Outputs (1)

`result` always 32 bytes -- the 32 byte storage result output

Where `address` is the address of the contract to read from, `position` is the position in contract `address`s storage, and the opcode output is simply a 32 byte data return from contract `address`'s storage similar to that produced by `sload`.

#### Gas (recommendation)

200 Wei -- The equivalent gas cost to the existing `sload` opcode as there would be no implementation difference at the Node level, see: [SLOAD in Go-Ethereum](https://github.com/ethereum/go-ethereum/blob/7504dbd6eb3f62371f86b06b03ffd665690951f2/core/vm/instructions.go#L629), we would simply be exposing the lookup efficiency of `sload` at the EVM level.

## Motivation

*Generally* it would reduce the cost of L1 contract deployments and runtime execution of inter-contract storage reads (commonly specified as `public` `getters`) that are highly gas-sensitive across the board, such as: proxy contracts, L2 contracts (i.e. plasma chains and state-channels) and generic use multi-signature wallets.

*Reduced Runtime Gas-Cost*: Reading external contract storage must currently be done through calls using the `getter` design model, which requires the use of at least several opcodes to retrieve external storage data. There are many cases where a single contract would want to perform a precise low-level read of another contracts storage, without having to make tedious `getter` calls (which require both an assembly of the method signature and the use of a low-level `call`).

*Language Level Expansion*: An external storage opcode would allow Ethereum developers to access storage across the entire chain at a low level without being forced to use the `getter` call design pattern. This can provide new contract design models and higher-level language expansion (for `Vyper` and `Solidity`) to better and more efficiently access Ethereum contract storage across the board.

*Reduced Deployment Cost*: An added benefit for factory pattern produced contracts is that `getters` would no longer have to be included in every contract instance. While a `delegatecall` proxy design similar to the one used by the `GnosisSafe` would remedy deployment  gas cost for contracts more generally, for contracts that do not use this factory design pattern (which is common), the inclusion of `getters` would no longer have to be included in every produced contract instance, which reduces final deployment gas cost of deployed Layer 1 contract instances.

*Proxy Runtime Cost Reduction*: if a contract is using a delegate proxy design akin to that of the `GnosisSafe` (which is becoming more popular as a factory design pattern) every call currently must run through the `delegatecall` fallback method bypass including retrieving storage data using `getters`. By adding an external storage load capability, `getter` like data calls from other contracts can be significantly reduced at Runtime, as each execution would not have to run through the `delegatecall` fallback process, but could instead access the proxy contracts instances storage directly.

*Interpreting Storage Post Deployment*: Ethereum contracts can be used in ways we cannot foresee in the future, the case of having a contract deployed to the L1 chain but not being able to build new lean getters in the future would deprive future, potentially more-efficient, smart-contract development in production contracts. While this could be remedied by deploying a new contract and or upgradeable designs, those introduce design complexity which could otherwise be avoided by simply allowing new low-level interpretation of the contracts storage from another new contract.

*Node Implementability*: unlike other opcodes, Etheruem Node Developers have largely already implemented this opcode a reality via `getStorageAt` and would simply have to bring this down to the opcode level.

Completed here is the actual ballpark implimentation of `sloadext` in the Go-Ethereum Client, see: [SLOADEXT Go-Ethereum Pull-Request 19566](https://github.com/ethereum/go-ethereum/pull/19566) -- as you can see, the code is fairly trivial to impliment in the client.

*State-Channel and Plasma Chain Cost Reduction*: state-channel and plasma chain contract design is extremely L1 gas-cost sensitive, if there are cases where getters are to be used for any of these contracts, deployment and runtime cost could be further reduced by pairing both the `proxy` design patterns and `getter` contract design patterns using `sloadext` featured in this EIP.

*EVM Design Clarity*: Lastly, the current Ethereum 1.0 specification oddly allows a contract to externally access another contracts code via `extcodecopy`, but does not allow another contract to access it's storage raw at a low-level. This seems counter-intuitive as a low-level EVM design model and would be remedied by allowing a low-level storage access opcode such as `sloadext`.

## Caveats

*a) Conceptual Changes*: `private` or `internal` Solidity variables would effectively be publicly accessible by other contracts. In response: considering this is a public blockchain and all storage and code is public, I see no issue with this expanded functionality. This would affect contracts such as Oracles, which currently leverage shielded storage behind private or internal storage. This however, is not a good business model at the very least, as anyone could simply view the data on-chain (as it's a "public" blockchain) and relay it on their own separate contract. If `sloadext` where to be allowed, developers would need to be informed that private variables can be accessed, but only through a very specific low-level call.

*b) Node Development Cost*: additional development and testing overhead at the node level (i.e. this is more work for the Node developers). In response: I would say this provides a potential new set of interesting design patterns which higher level languages such as Solidity and Vyper could leverage in many different gas-saving ways, and that Node developers have already made possible this functionality to the API node level, and would simply have to expose it at the lower EVM level.

*d) Ethereum 2.0*: this might prove difficult to implement in a Sharded Ethereum, however, I'm not entirely sure at this point. I would need to consult with the 2.0 researchers to determine a potential new gas specification if this is indeed computationally expensive to run in a sharded Ethereum.

## Example (usage in Solidity)

```
contract MyContractInstance {
  uint256 someStoredVariable;

  // developer has left out getter to reduce deployment cost
}
```

```
contract MyContractGetters {
  function someStorageVariable(address target) external view returns (uint256 ret) {
    assembly {
      ret := sloadext(target, 0)
    }

    // low-level access now possible, there will be little change to for dapps to migrate over to the new call model, saving the L1 cost of having to deploy getters to every contract instance.
  }
}
```

```
contract LanguageLevelPotential {
  uint256 external someStoredVariable; // marked for external sload usage, which will be added to a getter contract
}

// when deployed, a separate `getter` contract as the one specified above as `MyContractGetters` could be produced automatically by the compiler and deployed separately to the instance, thus further reducing final deployment cost of `MyContractInstance` without limiting the instance functionality
```

While the above example is primitive and the common response would be to always to specify a getter for `someStoredVariable` by making it `public`, there are many cases where storage in contracts is also complex or the contract is highly deployment cost sensitive, and a more refined inter-contractual storage reading solution at the lower-level or at the higher language level would be preferred to large `call`s to the target contract. Writing such a getter for deployed L1 contract instances could be very costly, whereas the above model would significantly reduce that cost.

In cases where separate contracts must do a myriad of storage reads from another contract, the developer must currently resort to internal `call` design patterns to extract this data, where a more surgical `sloadext` would provide far greater flexibility and allow inter-contract storage access to be far less expensive (given sloadext is considered less expensive than a `call`, `callcode`, `staticcall` or `delegatecall` operation for example).

## Notes

Naming convention: is akin to `sload` (i.e. "storage load") and `ext` akin to `extcodecopy` (i.e. "external code copy"). Similarly, the opcode could be titled `extsload` however, I found this notation to be hard to read.
