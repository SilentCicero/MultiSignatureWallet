const { utils } = require('ethers');

const hash = '0x87b2d4b93731813f851f44e4a8e98e8e6e3680cc98081ea0c5c4ba4f6948c5a6';
const hashWithPrefix = utils.keccak256(utils.solidityPack([
  'string', 'bytes32'
], [
  "\x19Ethereum Signed Message:\n32", hash,
]));
const hashWithInvalidLengthPrefix = utils.keccak256(utils.solidityPack([
  'string', 'bytes32'
], [
  "\x19Ethereum Signed Message:\n64", hash,
]));
const hashWithInvalidLength2Prefix = utils.keccak256(utils.solidityPack([
  'string', 'bytes32'
], [
  "\x19Ethereum Signed Message:\n66", hash,
]));

// metamask/trust/coinbase if you have it
if (typeof window.web3 !== "undefined") {

  // enable eth
  window.ethereum.enable();

  // get accounts
  web3.currentProvider.sendAsync({ method: "eth_accounts", params: [] }, (err, accountResult) => {
    if (err) return console.error(err);

    const signerAddress = accountResult.result[0];

    web3.currentProvider.sendAsync({
      method: "personal_sign",
      params: [signerAddress, hash],
    }, (err, signerResult) => {
      // if (err) return console.error(err);

      document.body.innerHTML = `
        Supports Vanilla Signing (No Prefix): <br />
        ${String(signerAddress).toLowerCase() === String(utils.recoverAddress(hash, signerResult.result)).toLowerCase()}  <br /> <br />

        Supports Prefix (Byte Length): <br />
        ${String(signerAddress).toLowerCase() === String(utils.recoverAddress(hashWithPrefix, signerResult.result)).toLowerCase()}  <br /> <br />

        Supports Prefix (JS Length): <br />
        ${String(signerAddress).toLowerCase() === String(utils.recoverAddress(hashWithInvalidLengthPrefix, signerResult.result)).toLowerCase()}  <br /> <br />

        Supports Prefix (JS Length 2): <br />
        ${String(signerAddress).toLowerCase() === String(utils.recoverAddress(hashWithInvalidLength2Prefix, signerResult.result)).toLowerCase()}  <br /> <br />
      `;     // Append <li> to <ul> with id="myList"
    });
  });

}
