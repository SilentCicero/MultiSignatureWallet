// MultiSignatureWallet EIP712 Hash Generation Code
const ethers = require('ethers');
const ethUtil = require('eth-sig-util');
const coder = new ethers.utils.AbiCoder();

// Transaciton Data
const destination = String('0x2b47f0d926a28adfc90a69939502dcb687ac3686').toLowerCase();
const verifyingContract = String('0xB49042552525A5336b1719AE9a11B0bB339Cd195').toLowerCase();
const gasLimit = '3000000';
const data = '0x87654321';
const nonce = '0';

// Domain TypeHash
const DOMAIN_SEPORATOR_TYPEHASH = ethers.utils.keccak256(ethers.utils.solidityPack(
  ['string'], ['EIP712Domain(uint256 chainId,address verifyingContract,uint256 nonce,address destination,uint256 gasLimit,bytes data)']
));

// data hash
const DATA_HASH = ethers.utils.keccak256(data);

// EIP712 Domain Seperator
const DOMAIN_SEPARATOR = ethers.utils.keccak256(coder.encode(
  ['bytes32', 'uint256', 'address', 'uint256', 'address', 'uint256', 'bytes32'], [
    DOMAIN_SEPORATOR_TYPEHASH,
    1, // chain id homestead (mainnet)
    verifyingContract,
    nonce,
    destination,
    gasLimit,
    DATA_HASH,
  ]
));

// EIP712 Transaction Hash
const RELEASE_HASH = ethers.utils.keccak256(ethers.utils.solidityPack(
  ['string', 'bytes32'], [
    "\x19\x01",
    DOMAIN_SEPARATOR,
  ],
));

console.log('DATA HASH', DATA_HASH);
console.log('EXECUTE DATA', verifyingContract, destination, gasLimit, data, nonce);
console.log('DOMAIN SEPERATOR TYPE HASH', DOMAIN_SEPORATOR_TYPEHASH);
console.log('DOMAIN SEPERATOR HASH', DOMAIN_SEPARATOR);
console.log('FINAL RELEASE HASH', RELEASE_HASH);
