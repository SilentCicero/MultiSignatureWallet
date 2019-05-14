

// metamask/trust/coinbase if you have it
if (typeof window.web3 !== "undefined") {

  // enable eth
  window.ethereum.enable();

  // get accounts
  web3.currentProvider.sendAsync({ method: "eth_accounts", params: [] }, (err, accountResult) => {
    if (err) return console.error(err);

    const signerAddress = accountResult.result[0];

    web3.currentProvider.sendAsync({
      method: "eth_sign",
      params: [signerAddress, "0x879a053d4800c6354e76c7985a865d2922c82fb5b3f4577b2fe08b998954f2e0879a053d4800c6354e76c7985a865d2922c82fb5b3f4577b2fe08b998954f2e0"],
    }, (err2, signerResult) => {
      // if (err) return console.error(err);

      console.log(err2, signerResult);
    });
  });

}
