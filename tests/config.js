const mongoose = require('mongoose');
const nodemailer = require('nodemailer');
const IPFS = require('ipfs-mini');
const { utils } = require('ethers');
const { call, Eth, balanceOf, onReceipt, HttpProvider } = require('ethjs-extras');

// SECRET ENV | connect to mongo db.
const mongoUrl = process.env.mongoPath;

// SECRET ENV | private key throw away
const privateKey = process.env.privateKey;

// SECRET ENV | infura and provider details
const infuraID = process.env.infuraID;

// the dai token address
const daiTokenAddress = '0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359';

// main proxy factory details
const nickpayAddress = '0xd27fbbba54d9a2ad8d1e91e1809030941414a24c';

// multisend address
const multiSendAddress = '0xe666c445d6a38c053dc846260718c156edf24068';

// fee collection account
const feeCollectionAccount = '0xae134F8d427cdb2145D7641ce075A03A2fF7f9B4';

// the email we use to send service reminders.
const serviceEmail = 'service@nickpay.com';

// the only tokens this
const acceptedTokens = {
  '0x0000000000000000000000000000000000000000': {
    name: 'Ether',
  },
  '0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359': {
    name: 'Dai',
  },
};

// terms
const terms = 'I agree to the terms and conditions set forth at this url: https://nickpay.com/terms';

// pickup method
const pickupABI = (new utils.Interface(['transfer(bytes32 destination,address token,uint256 amount,address feeRecipient,uint256 fee,bytes32 nonce,uint256 expiry,bytes32[] signatures)'])).abi[0];
const multisendABI = (new utils.Interface(['multiSend(uint256 gass,address to,uint256 value,uint256 dataLength,uint256 count,bytes data)'])).abi[0]

// mongoose update setting
const noMultiOrUpsert = { multi: false, upsert: false };

// mongo options
const mongoOptions = {
  // connectTimeoutMS: 1000,
  // useNewUrlParser: true,
  // bufferCommands: false, // Disable mongoose buffering
  // bufferMaxEntries: 0, // and MongoDB driver buffering
  // reconnectTries: Number.MAX_VALUE, // Never stop trying to reconnect
  // reconnectInterval: 500, // Reconnect every 500ms
  // poolSize: 100, // Maintain up to 10 socket connections
  // If not connected, return errors immediately rather than waiting for reconnect
  bufferCommands: false, // Disable mongoose buffering
  bufferMaxEntries: 0 // and MongoDB driver buffering
};

// email settings for fastmail
const emailOptions = {
  host: 'smtp.fastmail.com',
  port: 465,
  secure: true, // use SSL
  auth: {
    user: process.env.emailUser,
    pass: process.env.emailPassword,
  },
};

const infuraMainnetURL = 'https://mainnet.infura.io/v3/' + infuraID;

// mongodb connection
let connection = null;

// create connection
async function connect() {
  // connect to mongo
  if (!connection) {
    connection = await mongoose.createConnection(mongoUrl, mongoOptions);

    // Transaction modal
    connection.model('Pickup', {
      _id: String, // mongo hash id
      d: String, // data
      a: Boolean, // assigned
      c: Date, // created
    });
  }

  // return conneciton objects
  return {
    Pickup: connection.model('Pickup'),
  };
}

// nodemailer transporter
const emailTransporter = nodemailer.createTransport(emailOptions);

// send mail function as promise
const sendMail = exports.sendMail = mailOptions => new Promise((reject, resolve) => emailTransporter
  .sendMail(mailOptions, (err, result) => {
   if (err) {
     resolve(result);
   } else {
     reject(err);
   }
}));

// raw infura provider
const provider = new HttpProvider(infuraMainnetURL);

// get the allowance of a spender from dai
const daiAllowanceOf = async (from, spender, block) => utils.bigNumberify((await call({
  provider,
  address: daiTokenAddress,
  args: [from, spender],
  solidity: 'allowance(address,address):(uint256)',
  block: block || 'latest',
}))[0]);

// setup IPFS module
const ipfs = new IPFS({ host: 'ipfs.infura.io', port: 5001, protocol: 'https' });

// Eth object
const eth = Eth({ provider: new HttpProvider(infuraMainnetURL) });

// export out
module.exports = {
  multiSendAddress,
  provider,
  noMultiOrUpsert,
  acceptedTokens,
  feeCollectionAccount,
  multisendABI,
  pickupABI,
  connect,
  eth,
  ipfs,
  terms,
  provider,
  sendMail,
  daiAllowanceOf,
  nickpayAddress,
  privateKey,
  daiTokenAddress,
  ipfs,
  serviceEmail,
};
