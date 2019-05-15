Title: Skinny Signed Typed Data V4

## Motivation

The existing versions of typed signing specified in EIP712 are either incredibly awkward to implement and is computationally inefficient to validate on-chain, making them a poor fit for highly gas-sensitive transactions which require some typed signature data (such as meta-transactions or everyday multi-signature wallet transactions). In this EIP, I will introduce a lean, incredibly flexible, computationally efficient signing scheme for Ethereum typed signature production.

## Principles

1) Reduction Efficiency: Computational Efficiency for On-Chain and Off-Chain Reduction and Verification
2) Informative: Informs the Signer of the Data being signed in a helpful, verifiable way
3) Fraud-Resistant: Prevents dApps from Suggesting Data Descriptors to wallets which are not Intended by the Contract Developers (or signature verifiers)
4) Unique: Prevent attacks such as Replay Attacks, where signatures target either one or many specified contract or signing targets

## Specification

Internal Data Layout: [prefix 1901][20 byte hash domain][data to be signed]

### Hash Construction (JS)

```js
const { utils } = require('ethers');

// Contract Target
const contractAddress = '0x';

// DOMAIN Hash

const domainHash = `0x${utils.keccak256(utils.encodePacked(
  [
    "DomainHash(string name, string version, uint256 chainId)"
    "MultiSignatureWallet", // name
    "1.0.0", // version
    1, // chain id
  ],
)).slice(0, 20)}`;

// Final Hash Construction (20 bytes only..)

const hash = utils.keccak256(utils.encodePacked(
  ['bytes2', 'bytes20', 'address', 'bytes'],
  ['0x1901', domainHash, contractAddress, utils.encode(DATA...)]
));
```

### Call to Wallet from Injected Provider (JS)

```js
web3.currentProvider.sendAsync({
  method: "eth_signedTypedDataV4",
  params: [
    signerAddress, // address of signer in question
    {
      name: 'MultiSignatureWallet', // domain hash details as an object
      version: '1.0.0',
      chainId: 1,
    },
    contractAddress, // contract address in question
    data... // data in question to sign
  ],
}, (err, result) => {
  // returns an object:
  /*
  {
      domainHash, (20 byte)
      hash, (32 byte)
      signature, (65 byte hex encoded)
  }
  */

  console.log(err, result.domainHash, result.hash, result.signature);
});
```

### Hash Reduction On-Chain (Assembly via Solidity)

```js
assembly {
  calldatacopy(64, 0, calldatasize())
  mstore(0, 0x190110040600039806000f350fe6000361515600b578) // 0x1901 + produced 20 byte Domain Hash prefix hash
  mstore(32, address()) // unique and simple replay attack protection

  let hash := keccak256(10, add(52, calldatasize())) // start 10 bytes in
}
```

### Hash Reduction On-Chain (Solidity)

```js
contract Recover {
 function recover(...) {
   bytes32 hash = keccak256(abi.encodePacked(bytes2(1901), bytes20(0x10040600039806000f350fe6000361515600b578), address(this), ...);
 }
}
```
