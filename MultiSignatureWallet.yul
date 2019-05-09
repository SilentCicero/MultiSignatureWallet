/**
  * @title MultiSignatureWallet
  * @author Nick Dodson <thenickdodson@gmail.com>
  * @notice 311 byte EIP712 Signing Compliant Delegate-Call Enabled MultiSignature Wallet for the Ethereum Virtual Machine
  */
object "MultiSignatureWallet" {
  code {
    // constructor: uint256(signatures required) + address[] signatories (bytes32 sep|chunks|data...)
    codecopy(0, 311, codesize()) // setup constructor args: mem positon 0 | code size 280 (before args) | 1000 bytes of address args (30)
    sstore(address(), mload(0)) // map contract address => signatures required

    for { let i := 96 } lt(i, add(96, mul(32, mload(64)))) { i := add(i, 32) } { // iterate through signatory addresses
       sstore(mload(i), mload(i)) // map signer address => signer address
    }

    datacopy(0, dataoffset("Runtime"), datasize("Runtime")) // now switch over to runtime code from constructor
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    code {
      if calldatasize() { // call data: bytes4(sig) bytes32(dest) bytes32(gasLimit) bytes(data) bytes32[](signatures) | supports fallback
        calldatacopy(1060, 0, calldatasize()) // copy calldata to memory
        
        let dataLength := mload(1192) // size of the bytes data
        
        // build EIP712 release hash
        mstore(1000, 0x4a0a6d86122c7bd7083e83912c312adabf207e986f1ac10a35dfeb610d28d0b6) // EIP712 Execute TypeHash: Execute(uint256 nonce,address destination,uint256 gasLimit,bytes data)
        mstore(1032, sload(add(address(), 1))) // map wallet nonce to memory (nonce: storage(address + 1))
        mstore(1128, keccak256(1224, dataLength)) // we have to hash the bytes data due to EIP712... why....
        
        mstore8(0, 0x19) // EIP712 0x1901 prefix
        mstore8(1, 0x01)
        mstore(2, 0xb0609d81c5f719d8a516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f2) // EIP712 Domain Seperator: EIP712Domain(string name,string version,uint256 chainId)
        mstore(34, keccak256(1000, 160)) // EIP712 Execute() Type Hash
        
        let EIP712Hash := keccak256(0, 66) // EIP712 final signing hash
        let previousAddress := 0 // comparison variable, used to check for duplicate signer accounts
        
        for { let i := 0 } lt(i, sload(address())) { i := add(i, 1) } { // signature validation: loop through signatures (i < required signatures)
            let memPosition := add(add(1064, mload(1160)), mul(i, 96)) // new memory position -32 bytes from sig start
            
            mstore(memPosition, EIP712Hash) // place hash before each sig in memory: hash + v + r + s | hash + vN + rN + sN
            
            let result := call(3000, 1, 0, memPosition, 128, 300, 32) // call ecrecover precompile with ecrecover(hash,v,r,s) | failing is okay here
            
            if iszero(gt(sload(mload(300)), previousAddress)) { revert(0, 0) } // sload(current address) > prev address OR revert
            
            previousAddress := mload(300) // set previous address for future comparison
        }
        
        sstore(add(address(), 1), add(1, mload(1032))) // increase nonce: nonce = nonce + 1
        
        if iszero(delegatecall(mload(1096), mload(1064), 1224, dataLength, 0, 0)) { revert (0, 0) } // make delegate call, revert on fail
      }
    }
  }
}

/*
===========================
Design
===========================

The design of this multi-signature wallet was based around Christian Lundkvist's Simple-Multisig.

Christians Wallet:
https://github.com/christianlundkvist/simple-multisig

Our design accomplishes a similar security profile to Christians simple-multi-sig for a substantially less deployment and execution cost.

While this was designed on Yul (an experimental language), the instruction complexity compiled, allows us to better understand
what is going on under the hood and thus potentially better verify the wallets design integrity.

This wallet has yet to be audited and is experimental.

===========================
Comparitive Stats
===========================

Contract Size (bytes):
Christian   2301 bytes
Nick        311 bytes

Opcodes Used:
Christian   1926 opcodes
Nick        233 opcodes

Deployment Cost (using 2 Signatories):
Christian:
 transaction cost 	656197 gas
 execution cost 	454473 gas

Nick:
 transaction cost 	190592 gas
 execution cost 	144616 gas

===========================
Storage Layout
===========================

address()         | uint256 | required signatures
address() + 1     | uint256 | nonce
signatory address | address | signator address

to invalidate signator address, simply set it to 0 in storage via delegate call.

Solidity ABI:
constructor(uint256 requiredSignatures,address[] signatories)
function execute(address destination,uint256 gasLimit,bytes data,bytes32[] signatures)
function () // i.e. fallback open

Note, open calls to the contract are allowed, but will do no computation within the contract.

===========================
Constructor Memory Layout
===========================

0)   bytes32(signatures required) // uint256 requiredSignatures
32)  bytes32(signatories start) // address[] signatories
64)  bytes32(signatories length)
96)  bytes32(address 1)..
128) bytes32(address 2)..

===========================
Runtime Memory Layout
===========================

[0 - 66]
0)  bytes2(1901) -- EIP712 preface
2)  bytes32(EIP712 DomainSeperator)
34) bytes32(EIP712 Execute Typehash)

// override 0 with new hash
0)  bytes32(EIP712 Typehash) -- main hash used for address ecrecover

300) ecrecovered address

[1000 -> 1224 -> dynamic]
1000) bytes32(EIP712 Execute type hash)
1032) bytes32(nonce) -- this will overrite 4 byte sig ahead
1064) bytes32(destination)
1096) bytes32(gasLimit)
1128) bytes32(keccak256(data))

1128) bytes32(bytes data length) -- begining of bytes data
1160) bytes32(bytes end position)
1192) bytes32(bytes unpadded chunk size)
1224) bytes raw data (bytes actual dynamic)

// signature data
add(1064, mload(1160)) ) bytes32(signatures length)
add(1096, mload(1160)) ) bytes32(v1), bytes32(r1), bytes32(s1), bytes32(vN), bytes32(rN), bytes32(sN), ...

===========================
Solidity Reference Impl.
===========================

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

===========================
Notes
===========================

- Signatures must be organized in increasing order s0 > s1 > sN (duplicate and zero value address attack prevention)
- We allow the call to ecrecover pre-compile to fail, because it will produce either zero value address or the previous address
which the above signature scheme will prevent from passing the signature validation steps

===========================
Hash Construction In JS
===========================

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

============================================
Continued Hash Signing (web3.provider) in JS
============================================

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
*/
