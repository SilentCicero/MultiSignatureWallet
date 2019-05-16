// MultiSignatureWallet EIP712 Hash Generation Code
const ethers = require('ethers');
const ethUtil = require('eth-sig-util');
const coder = new ethers.utils.AbiCoder();

// Transaciton Data
const destination = String('0xff12adc0B8c870F9f08ec2e5659484d857c746Fa').toLowerCase();
const gasLimit = '600000';
const verifyingContract = '0xff12adc0B8c870F9f08ec2e5659484d857c746Fa';
const data = '0x';
const nonce = '0';

// Below is the code for Web3 Wallets / i.e. MetaMask in browser
const typedData = {
  types: {
    EIP712Domain: [
      { name: "chainId", type: "uint256" },
      { name: "verifyingContract", type: "address" },
      { name: "nonce", type: "uint256" },
      { name: "destination", type: "address" },
      { name: "gasLimit", type: "uint256" },
      { name: "data", type: "bytes" },
    ],
  },
  domain: {
    chainId: 1,
    verifyingContract,
    nonce,
    destination,
    gasLimit,
    data,
  },
  primaryType: "EIP712Domain",
  message: {},
};

// metamask/trust/coinbase if you have it
if (typeof window.web3 !== "undefined") {
  const signerAddress = '0x4f008D72757E63954b91a5E254CC61bB4cbc655E';

  web3.currentProvider.sendAsync(
  {
      method: "eth_signTypedData_v3",
      params: [signerAddress, JSON.stringify(typedData)],
      from: signerAddress,
  }, (err, result) => {
    if (err) return console.error(err);

    const DOMAIN_SEPARATOR = ethers.utils.keccak256(coder.encode(
      ['bytes32', 'uint256', "address", 'uint256', 'address', 'uint256', 'bytes32'], [
        ethers.utils.keccak256(ethers.utils.solidityPack(
          ['string'], ['EIP712Domain(uint256 chainId,address verifyingContract,uint256 nonce,address destination,uint256 gasLimit,bytes data)']
        )),
        1, // chain id homestead (mainnet)
        verifyingContract,
        nonce,
        destination,
        gasLimit,
        ethers.utils.keccak256(data),
      ]
    ));

    const DOMAIN_SEPARATOR2 = ethers.utils.keccak256(coder.encode(
      ['bytes32', 'uint256', "address", 'uint256', 'address', 'uint256', 'bytes32'], [
        ethers.utils.keccak256(ethers.utils.solidityPack(
          ['string'], ['EIP712Domain(uint256 chainId,address verifyingContract,uint256 nonce,address destination,uint256 gasLimit,bytes data)']
        )),
        0, // chain id homestead (mainnet)
        // '0xff12adc0B8c870F9f08ec2e5659484d857c746Fa'
        '0x0000000000000000000000000000000000000000',
        0,
        '0x0000000000000000000000000000000000000000',
        0,
        ethers.utils.keccak256('0'),
      ]
    ));

    console.log(DOMAIN_SEPARATOR2, ethers.utils.hexlify(ethUtil.TypedDataUtils.hashStruct('EIP712Domain', typedData.message, typedData.types)));

    // EIP712 Transaction Hash
    const RELEASE_HASH = ethers.utils.keccak256(ethers.utils.solidityPack(
      ['string', 'bytes32','bytes32'], [
        "\x19\x01",
        DOMAIN_SEPARATOR,
        DOMAIN_SEPARATOR,
      ],
    ));

    console.log(ethers.utils.recoverAddress(RELEASE_HASH, result.result));

    /*

    console.log('RECOVERED ADDRESS', recoverAddress);
    console.log('Recover Success', signerAddress.toLowerCase() === recoverAddress.toLowerCase());
    */

    console.log('Signature', result.result)
    console.log('Signature Split', ethers.utils.splitSignature(result.result));
  });
}
