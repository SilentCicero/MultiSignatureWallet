// A script to grab storage from a multi-signature wallet
const { Eth } = require('ethjs-extras');
const { utils } = require('ethers');

// details
const httpProvider = 'https://mainnet.infura.io/v3/727cc32d299f441ca441963ad90bc3e7';
const walletAddress = '0x3b7fad72773e034a62a595fa59f53f6a5ddd1fc1';
const signerAddress = '0xf498406A8489385601bFb12B09b55B6855e545ff';

// provider
const eth = Eth({ httpProvider });

// Check Required Signatures Value
eth.raw('eth_getStorageAt', walletAddress, utils.hexlify(utils.padZeros(walletAddress, 32)), 'latest')
.then(console.log)
.catch(console.log);

// Check Signer Address Weight
eth.raw('eth_getStorageAt', walletAddress, utils.hexlify(utils.padZeros(signerAddress, 32)), 'latest')
.then(console.log)
.catch(console.log);
