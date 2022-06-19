# Dynamic NFTs w/ Chainlink Keepers/VRF - Road To Web3 by Alchemy - Week 5

### Usage

1. Move into `smart-contracts` and install dependencies: `npm install`
2. Define required env vars:

   1. Create `.env` file: `cp .env.example .env`
   2. Update env vars inside `.env` with your own values.

3. Compile smart contract: `npx hardhat compile`
4. Execute tests: `npx hardhat test`
5. Deploy to Mumbai network: `npx hardhat run scripts/deploy.ts --network mumbai`

6. Verify your newly deployed contract. Once the previous command finishes the deployment process, you should be able to see the address for your contract in Mumbai network, verify your contract:

   - Parameters:
     - '60': This is the interval to automatically fetch latest BTC price feed and determine the current price trend (Bull/Bear). You can change it for any value you want.
     - '0x007A22900a3B98143368Bd5906f8E17e9867581b': This is the BTC/USD price data feed address. If you change this value, make sure to change it in `smart-contracts/scripts/deploy.ts` as well.
   - Command: `npx hardhat verify --network mumbai 0xcC589b8f4A9475B8A6Ce710429239b470a7e07c9 '60' '0x007A22900a3B98143368Bd5906f8E17e9867581b'`

7. Mint a new token. With the account you used to deploy the contract mint a new token directly from Mumbai Polygon Scan web app.
8. Configure [Chainlink Keepers](https://keepers.chain.link/mumbai/new)
9. Based on the interval you defined and the BTC price, you should be able to see how the metadata for your minted NFT changes _**automagically**_ over time.

   > **NOTE:** It might be possible that the interval you defined is significantly high or that the price fluctuation of BTC is not does not change the trend (it keeps bull or it keeps bear).
