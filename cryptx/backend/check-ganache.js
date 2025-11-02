const { Web3 } = require('web3');

const web3 = new Web3('http://127.0.0.1:8545');

async function checkGanache() {
    try {
        console.log('🔍 GANACHE DATA VIEWER');
        console.log('='.repeat(60));

        // 1. Network Info
        const chainId = await web3.eth.getChainId();
        const blockNumber = await web3.eth.getBlockNumber();
        const gasPrice = await web3.eth.getGasPrice();

        console.log('\n📊 NETWORK INFO:');
        console.log(`Chain ID: ${chainId}`);
        console.log(`Current Block: ${blockNumber}`);
        console.log(`Gas Price: ${web3.utils.fromWei(gasPrice, 'gwei')} Gwei`);

        // 2. All Accounts and Balances
        const accounts = await web3.eth.getAccounts();
        console.log('\n💰 ACCOUNTS & BALANCES:');
        console.log('='.repeat(60));

        let totalBalance = BigInt(0);
        for (let i = 0; i < accounts.length; i++) {
            const balance = await web3.eth.getBalance(accounts[i]);
            const balanceInEth = web3.utils.fromWei(balance, 'ether');
            totalBalance += BigInt(balance);

            console.log(`\n[${i}] ${accounts[i]}`);
            console.log(`    Balance: ${balanceInEth} ETH`);
            console.log(`    Wei: ${balance}`);
        }

        console.log('\n' + '='.repeat(60));
        console.log(`Total: ${web3.utils.fromWei(totalBalance.toString(), 'ether')} ETH`);

        // 3. Recent Blocks and Transactions
        console.log('\n📦 RECENT BLOCKS:');
        console.log('='.repeat(60));

        const blocksToShow = Math.min(5, Number(blockNumber) + 1);
        for (let i = Number(blockNumber); i >= Number(blockNumber) - blocksToShow + 1 && i >= 0; i--) {
            const block = await web3.eth.getBlock(i);
            if (block) {
                console.log(`\nBlock #${block.number}`);
                console.log(`  Hash: ${block.hash}`);
                console.log(`  Timestamp: ${new Date(Number(block.timestamp) * 1000).toLocaleString()}`);
                console.log(`  Transactions: ${block.transactions.length}`);

                // Show transaction details
                if (block.transactions.length > 0) {
                    console.log('  Transaction Details:');
                    for (const txHash of block.transactions) {
                        const tx = await web3.eth.getTransaction(txHash);
                        const receipt = await web3.eth.getTransactionReceipt(txHash);

                        console.log(`    - Hash: ${tx.hash}`);
                        console.log(`      From: ${tx.from}`);
                        console.log(`      To: ${tx.to || 'Contract Creation'}`);
                        console.log(`      Value: ${web3.utils.fromWei(tx.value, 'ether')} ETH`);
                        console.log(`      Gas Used: ${receipt.gasUsed}`);
                        console.log(`      Status: ${receipt.status ? '✅ Success' : '❌ Failed'}`);
                    }
                }
            }
        }

        // 4. Transaction Count per Account
        console.log('\n📤 TRANSACTION COUNT:');
        console.log('='.repeat(60));
        for (let i = 0; i < accounts.length; i++) {
            const txCount = await web3.eth.getTransactionCount(accounts[i]);
            console.log(`[${i}] ${accounts[i]}: ${txCount} transactions`);
        }

    } catch (error) {
        console.error('❌ Error:', error.message);
        console.log('\n⚠️  Make sure Ganache is running on http://127.0.0.1:8545');
    }
}

// Run the checker
checkGanache();
