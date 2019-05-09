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
