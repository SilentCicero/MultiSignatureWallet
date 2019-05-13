## MultiSignatureWallet (311 bytes)

The smallest known EIP712 compliant MultiSignatureWallet for the Ethereum Virutal Machine.

## Features:

- Tiny deployment cost (311 Bytes / 233 opcodes)
- Smallest known multi-signature wallet that is EIP712 compliant
- Close-To-The-Metal: Easily auditable at the opcode level (easier for formal-verification)
- Reduced execution cost (when executing transactions)
- Written with similar security profile to common multi-signature designs
- Standard Numerical Nonce system to prevent double-spends
- EIP712 Signing Compliant (signing works with all major Ethereum wallets)
- Delegate-Call Enabled
- Specify unfixed amount of signatories and thresholds
- MIT License; completely open source to do with as you please

## Design

The design of this multi-signature wallet was based around Christian Lundkvist's Simple-Multisig.

Christians Wallet:
https://github.com/christianlundkvist/simple-multisig

Our design accomplishes a similar security profile to Christians simple-multi-sig for a substantially less deployment and execution cost.

While this was designed on Yul (an experimental language), the instruction complexity compiled, allows us to better understand
what is going on under the hood and thus potentially better verify the wallets design integrity.

***This wallet has yet to be audited and is experimental.***

## Implementation

The final wallet code can be found in the `MultiSignatureWallet.yul` file.

## Stats

Below are stats comparing Christians simple-multi-sig with it's Yul implemented counterpart. The results are fairly stagering.

#### Contract Size (bytes):

Christian:   2301 bytes

Nick:        ***311 bytes***

#### Opcodes Used:

Christian:   1926 opcodes

Nick:        ***233 opcodes***

#### Deployment Cost (using 2 Signatories):

Christian:

 transaction cost: 	656197 gas

 execution cost: 	454473 gas

Nick:

 transaction cost: 	***190592 gas***

 execution cost: 	***144616 gas***

## Reference Implementation (Solidity)

Below is a rough design of the Yul implemented version with specific optimizations made. Hashes are pre-computed and tucked into the execution method to avoid expensive storage reads.

```js

pragma solidity ^0.5.0;

contract EIP712MultiSig {
    uint256 public nonce;
    uint256 public threshold;
    mapping(address => bool) public isOwner;

    function () external payable {}

    constructor(address[] memory owners, uint256 requiredSignatures) public {
        threshold = requiredSignatures;
        for (uint256 i = 0; i < owners.length; i++)
            isOwner[owners[i]] = true;
    }

    function execute(address dest, bytes calldata data, bytes32[] calldata signatures) external {
        bytes32 hash = keccak256(abi.encodePacked(
          "\x19\x01",
          bytes32(0xb0609d81c5f719d8a516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f2),
          keccak256(abi.encode(0x4a0a6d86122c7bd7083e83912c312adabf207e986f1ac10a35dfeb610d28d0b6, dest, nonce++, data))));

        address prev;

        for (uint256 i = 0; i < threshold; i++) {
            address addr = ecrecover(hash, uint8(signatures[i][31]), signatures[i + 1], signatures[1 + 2]);
            assert(isOwner[addr] == true);
            assert(addr > prev); // check for duplicates or zero value
            prev = addr;
        }

        if(!dest.delegatecall(data)) revert();
    }
}
```

## Bytecode

Specified here the bytecode for this wallet in full. Of-course constructor arguments would be encoded and appended during deployment.

```
0x38610137600039600051305560605b60405160200260600181101561002f5780518151555b60208101905061000e565b5060f780610040600039806000f350fe361560f65760003681610424376104a8516103e87f4a0a6d86122c7bd7083e83912c312adabf207e986f1ac10a35dfeb610d28d0b68152600180300180546104088181526104c8915085822061046852601987538384537fb0609d81c5f719d8a516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f260025260a0852060225260428720945086875b305481101560d0576104286060820261048851010187815261012c6020816080848e8c610bb8f1508381515411151560c0578a8bfd5b8051935050505b8581019050608a565b505080518401835550858686836104285161044851f4151560ef578586fd5b5050505050505b
```

## OpCode Instructions

Specified here is the opcodes used for this multi-signature wallet. As you can see, it varies little from the Yul implimented source code.

```
CODESIZE PUSH2 0x137 PUSH1 0x0 CODECOPY PUSH1 0x0 MLOAD ADDRESS SSTORE PUSH1 0x60 JUMPDEST PUSH1 0x40 MLOAD PUSH1 0x20 MUL PUSH1 0x60 ADD DUP2 LT ISZERO PUSH2 0x2F JUMPI DUP1 MLOAD DUP2 MLOAD SSTORE JUMPDEST PUSH1 0x20 DUP2 ADD SWAP1 POP PUSH2 0xE JUMP JUMPDEST POP PUSH1 0xF7 DUP1 PUSH2 0x40 PUSH1 0x0 CODECOPY DUP1 PUSH1 0x0 RETURN POP INVALID CALLDATASIZE ISZERO PUSH1 0xF6 JUMPI PUSH1 0x0 CALLDATASIZE DUP2 PUSH2 0x424 CALLDATACOPY PUSH2 0x4A8 MLOAD PUSH2 0x3E8 PUSH32 0x4A0A6D86122C7BD7083E83912C312ADABF207E986F1AC10A35DFEB610D28D0B6 DUP2 MSTORE PUSH1 0x1 DUP1 ADDRESS ADD DUP1 SLOAD PUSH2 0x408 DUP2 DUP2 MSTORE PUSH2 0x4C8 SWAP2 POP DUP6 DUP3 KECCAK256 PUSH2 0x468 MSTORE PUSH1 0x19 DUP8 MSTORE8 DUP4 DUP5 MSTORE8 PUSH32 0xB0609D81C5F719D8A516AE2F25079B20FB63DA3E07590E23FBF0028E6745E5F2 PUSH1 0x2 MSTORE PUSH1 0xA0 DUP6 KECCAK256 PUSH1 0x22 MSTORE PUSH1 0x42 DUP8 KECCAK256 SWAP5 POP DUP7 DUP8 JUMPDEST ADDRESS SLOAD DUP2 LT ISZERO PUSH1 0xD0 JUMPI PUSH2 0x428 PUSH1 0x60 DUP3 MUL PUSH2 0x488 MLOAD ADD ADD DUP8 DUP2 MSTORE PUSH2 0x12C PUSH1 0x20 DUP2 PUSH1 0x80 DUP5 DUP15 DUP13 PUSH2 0xBB8 CALL POP DUP4 DUP2 MLOAD SLOAD GT ISZERO ISZERO PUSH1 0xC0 JUMPI DUP11 DUP12 REVERT JUMPDEST DUP1 MLOAD SWAP4 POP POP POP JUMPDEST DUP6 DUP2 ADD SWAP1 POP PUSH1 0x8A JUMP JUMPDEST POP POP DUP1 MLOAD DUP5 ADD DUP4 SSTORE POP DUP6 DUP7 DUP7 DUP4 PUSH2 0x428 MLOAD PUSH2 0x448 MLOAD DELEGATECALL ISZERO ISZERO PUSH1 0xEF JUMPI DUP6 DUP7 REVERT JUMPDEST POP POP POP POP POP POP JUMPDEST
```

## Notes

- We store all storage data at specific addresses, this reduces execution code and is safe so long as Ethereum addresses are geenerated using strong entropy etc.
- Signatures must be organized in increasing order s0 > s1 > sN (duplicate and zero value address attack prevention)
- We allow the call to ecrecover pre-compile to fail (i.e. return zero), because it will produce either zero value address or the previous address
which the above signature scheme will prevent from passing the signature validation steps

## Solidity ABI Specification

Below is the Solidity ABI specification for the MultiSignatureWallet written in Yul.

```js
interface MultiSignatureWallet {
  function construct(uint256 requiredSignatures, address[] calldata signatories) external;
  function execute(address destination, uint256 gasLimit, bytes calldata data, bytes32[] calldata signatures) external;
  function () external;
}
```

Note, the constructor method is specified above, even though we would not usually specify this in an Interface contract.

##

## EIP712 Specification

Below you can find the used EIP712 domain specifications and the single Execute type method specification.

### Domain Separator  

***ABI***
```
EIP712Domain(string name,string version,uint256 chainId)
```

***Values***
- name "MultiSignatureWallet"
- version "1"
- chainId 1

### Execute Method Specification

***ABI***
```
Execute(uint256 nonce,address destination,uint256 gasLimit,bytes data)
```

## Hash Construction (JS using Ethers.js)

Full example can be found in the `/examples/hash-creation.js` file.

```js
// MultiSignatureWallet EIP712 Hash Generation Code
const ethers = require('ethers');
const coder = new ethers.utils.AbiCoder();

// Transaciton Data
const destination = String('0x9dd1e8169e76a9226b07ab9f85cc20a5e1ed44dd').toLowerCase();
const gasLimit = '600000';
const data = '0x654321';
const nonce = '0';

// EIP712 Transaction Hash
const RELEASE_HASH = ethers.utils.keccak256(ethers.utils.solidityPack(
  ['string', 'bytes32', 'bytes32'], [
    "\x19\x01",
    '0xb0609d81c5f719d8a516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f2',
    ethers.utils.keccak256(coder.encode(
      ['bytes32', 'uint256', 'address', 'uint256', 'bytes32'],
      [
        '0x4a0a6d86122c7bd7083e83912c312adabf207e986f1ac10a35dfeb610d28d0b6',
        nonce,
        destination,
        gasLimit,
        ethers.utils.keccak256(data),
      ],
    )),
  ],
));

console.log('RELEASE HASH', RELEASE_HASH);
console.log('DATA', destination, gasLimit, data, nonce);
```

## EIP712 Signature Request (web3.provider)

```js
const ethers = require('ethers');

// Below is the code for Web3 Wallets / i.e. MetaMask in browser
const typedData = {
  types: {
    EIP712Domain: [
      { name: "name", type: "string" },
      { name: "version", type: "string" },
      { name: "chainId", type: "uint256" },
    ],
    Execute: [
      { name: "nonce", type: "uint256" },
      { name: "destination", type: "address" },
      { name: "gasLimit", type: "uint256" },
      { name: "data", type: "bytes" },
    ],
  },
  domain: {
    name: "MultiSignatureWallet",
    version: "1",
    chainId: 1,
  },
  primaryType: "Execute",
  message: {
    nonce,
    destination,
    gasLimit,
    data,
  },
};

// metamask/trust/coinbase if you have it
if (typeof window.web3 !== "undefined") {
  const signerAddress = PUT_YOUR_ADDRES_HERE_DUMMY;

  web3.currentProvider.sendAsync(
  {
      method: "eth_signTypedData_v3",
      params: [signerAddress, JSON.stringify(typedData)],
      from: signerAddress,
  }, (err, result) => {
    if (err) return console.error(err);

    const recoverAddress = ethers.utils.recoverAddress(RELEASE_HASH, result.result);

    console.log('RECOVERED ADDRESS', recoverAddress);
    console.log('Recover Success', signerAddress.toLowerCase() === recoverAddress.toLowerCase());
    console.log('Signature', result.result)
    console.log('Signature Split', ethers.utils.splitSignature(result.result));
  });
}
```

## TODO

- Write many more tests
- Formal Verification of Assembly
- Adjust memory positions for optimal memory usage (during execution)

## LICENCE

```
Copyright 2019 Nick Dodson <thenickdodson@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
