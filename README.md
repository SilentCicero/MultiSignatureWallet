## MultiSignatureWallet (311 bytes)

The smallest known EIP712 compliant MultiSignatureWallet for the Ethereum Virutal Machine.

## Design

The design of this multi-signature wallet was based around Christian Lundkvist's Simple-Multisig.

Christians Wallet:
https://github.com/christianlundkvist/simple-multisig

Our design accomplishes a similar security profile to Christians simple-multi-sig for a substantially less deployment and execution cost.

While this was designed on Yul (an experimental language), the instruction complexity compiled, allows us to better understand
what is going on under the hood and thus potentially better verify the wallets design integrity.

This wallet has yet to be audited and is experimental.

## Stats

####Contract Size (bytes):
Christian   2301 bytes
Nick        311 bytes

####Opcodes Used:
Christian   1926 opcodes
Nick        233 opcodes

####Deployment Cost (using 2 Signatories):
Christian:
 transaction cost 	656197 gas
 execution cost 	454473 gas

Nick:
 transaction cost 	190592 gas
 execution cost 	144616 gas

## Reference Implimentation (Solidity)

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

## Notes

- Signatures must be organized in increasing order s0 > s1 > sN (duplicate and zero value address attack prevention)
- We allow the call to ecrecover pre-compile to fail, because it will produce either zero value address or the previous address
which the above signature scheme will prevent from passing the signature validation steps

## Hash Construction (JS using Ethers.js)

```js
// MultiSignatureWallet EIP712 Hash Generation Code
const ethers = require('ethers');
const ethUtil = require('eth-sig-util');
const coder = new ethers.utils.AbiCoder();

// Transaciton Data
const destination = String('0x9dd1e8169e76a9226b07ab9f85cc20a5e1ed44dd').toLowerCase();
const gasLimit = '600000';
const data = '0x654321';
const nonce = '0';

// EIP712 Execute Typehash
const EXECUTE_TYPEHASH = ethers.utils.keccak256(ethers.utils.solidityPack(
  ['string'], ['Execute(uint256 nonce,address destination,uint256 gasLimit,bytes data)']
));

// EIP712 Domain Seperator
const DOMAIN_SEPARATOR = ethers.utils.keccak256(coder.encode(
  ['bytes32', 'bytes32', 'bytes32', 'uint256'], [
    ethers.utils.keccak256(ethers.utils.solidityPack(
      ['string'], ['EIP712Domain(string name,string version,uint256 chainId)']
    )),
    ethers.utils.keccak256(ethers.utils.solidityPack(['string'], ['MultiSignatureWallet'])), // name
    ethers.utils.keccak256(ethers.utils.solidityPack(['string'], ['1'])), // version 1
    1, // chain id homestead (mainnet)
  ]
));

// EIP712 Transaction Hash
const RELEASE_HASH = ethers.utils.keccak256(ethers.utils.solidityPack(
  ['string', 'bytes32', 'bytes32'], [
    "\x19\x01",
    DOMAIN_SEPARATOR,
    ethers.utils.keccak256(coder.encode(
      ['bytes32', 'uint256', 'address', 'uint256', 'bytes32'],
      [
        EXECUTE_TYPEHASH,
        nonce,
        destination,
        gasLimit,
        ethers.utils.keccak256(data),
      ],
    )),
  ],
));

console.log('DATA Hash', ethers.utils.keccak256(data));
console.log('EXECUTE HASH', EXECUTE_TYPEHASH);
console.log('DOMAIN SEPERATOR', DOMAIN_SEPARATOR);
console.log('RELEASE HASH', RELEASE_HASH);
console.log('DATA', destination, gasLimit, data, nonce);
```

## EIP712 Signature Request (web3.provider)

```js

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

## LICENCE

```
Copyright 2019 Nick Dodson <thenickdodson@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
