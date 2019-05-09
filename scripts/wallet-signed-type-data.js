// MultiSignatureWallet EIP712 Hash Generation Code
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
