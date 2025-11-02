const Ganache = require("ganache-cli");
const { Web3 } = require('web3');

const options = {
  port: 8545,
  network_id: 5777,
  total_accounts: 5,
  default_balance_ether: 100,
  gasLimit: 8000000,
  mnemonic: 'test test test test test test test test test test test junk',
  // Thêm CORS headers cho web
  _cors: {
    origin: '*',
    credentials: true
  }
};

const ganache = Ganache.server(options);

ganache.listen(options.port, async (err, blockchain) => {
  if (err) {
    console.error("Error starting Ganache:", err);
  } else {
    console.log(`Ganache running on http://127.0.0.1:${options.port}`);

    const provider = ganache.provider;
    const web3 = new Web3(`http://127.0.0.1:${options.port}`);

    console.log("\nAvailable accounts");
    console.log("==================\n");

    // Get accounts
    const accounts = await web3.eth.getAccounts();

    for (let i = 0; i < accounts.length; i++) {
      const address = accounts[i];
      const balance = await web3.eth.getBalance(address);
      const balanceInEth = web3.utils.fromWei(balance, 'ether');

      // Get private key from provider
      provider.manager.state.unlocked_accounts[address.toLowerCase()];
      const wallet = provider.manager.state.accounts[address.toLowerCase()];
      const privateKey = wallet.secretKey.toString('hex');

      console.log(`[${i}] ${address}`);
      console.log(`    Private Key: 0x${privateKey}`);
      console.log(`    Balance: ${balanceInEth} ETH\n`);
    }

    console.log("Copy these private keys to your .env file as:");
    console.log("DEFAULT_WALLET_PRIVATE_KEY, DEFAULT_WALLET_PRIVATE_KEY2, etc.\n");
  }
});