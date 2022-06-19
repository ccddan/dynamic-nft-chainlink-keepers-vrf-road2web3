import {
  BullsBears,
  BullsBears__factory,
  MockV3Aggregator,
} from "../typechain";

import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("BullsBears", function () {
  const LATEST_PRICE = 120_000_000;

  let mockAggregator: MockV3Aggregator;
  let BullsBears: BullsBears__factory;

  this.beforeAll(async () => {
    const MockAggregator = await ethers.getContractFactory("MockV3Aggregator");
    mockAggregator = await MockAggregator.deploy(8, LATEST_PRICE);
    await mockAggregator.deployed();

    BullsBears = await ethers.getContractFactory("BullsBears");
  });

  it("Should return latest BTC price (USD)", async function () {
    const bullsBears = await BullsBears.deploy(60, mockAggregator.address);
    await bullsBears.deployed();

    let currentPrice = await bullsBears.currentPrice();
    expect(currentPrice).to.equal(BigNumber.from(LATEST_PRICE));
  });

  it("Should mint new token", async function () {
    const [owner, account1] = await ethers.getSigners();

    const bullsBears = await BullsBears.deploy(60, mockAggregator.address);
    await bullsBears.deployed();

    let tx = await bullsBears.connect(owner).safeMint(account1.address);
    await tx.wait();

    expect(
      await bullsBears.connect(account1).balanceOf(account1.address)
    ).to.equal(1);
    expect(await bullsBears.connect(account1).totalSupply()).to.equal(1);
  });

  it("Should list token metadata per owner", async function () {
    const [owner, account1, account2] = await ethers.getSigners();

    const bullsBears = await BullsBears.deploy(60, mockAggregator.address);
    await bullsBears.deployed();

    let tx = await bullsBears.connect(owner).safeMint(account1.address);
    await tx.wait();
    tx = await bullsBears.connect(owner).safeMint(account1.address);
    await tx.wait();
    tx = await bullsBears.connect(owner).safeMint(account1.address);
    await tx.wait();
    tx = await bullsBears.connect(owner).safeMint(account1.address);
    await tx.wait();
    tx = await bullsBears.connect(owner).safeMint(account1.address);
    await tx.wait();
    tx = await bullsBears.connect(owner).safeMint(account2.address);
    await tx.wait();
    tx = await bullsBears.connect(owner).safeMint(account2.address);
    await tx.wait();
    tx = await bullsBears.connect(owner).safeMint(account2.address);
    await tx.wait();
    tx = await bullsBears.connect(owner).safeMint(account2.address);
    await tx.wait();
    tx = await bullsBears.connect(owner).safeMint(account2.address);
    await tx.wait();

    let acc1Total = (
      await bullsBears.connect(account1).balanceOf(account1.address)
    ).toNumber();
    let acc2Total = (
      await bullsBears.connect(account2).balanceOf(account2.address)
    ).toNumber();
    console.log("Account1 total tokens:", acc1Total);
    console.log("Account2 total tokens:", acc2Total);

    expect(acc1Total).to.equal(5);
    expect(acc2Total).to.equal(5);
    expect(await bullsBears.totalSupply()).to.equal(acc1Total + acc2Total);

    for (let i = 0; i < acc1Total; i++) {
      const tokenId = await bullsBears
        .connect(account1)
        .tokenOfOwnerByIndex(account1.address, i);
      console.log(
        `Acc1 token id = ${tokenId.toNumber()}:`,
        await bullsBears.connect(account1).tokenURI(tokenId)
      );
    }
    console.log();
    for (let i = 0; i < acc2Total; i++) {
      const tokenId = await bullsBears
        .connect(account2)
        .tokenOfOwnerByIndex(account2.address, i);
      console.log(
        `Acc2 token id = ${tokenId.toNumber()}:`,
        await bullsBears.connect(account2).tokenURI(tokenId)
      );
    }
  });

  it("Should change tokens metadata to bear price trend", async () => {
    // Get accounts
    const [owner, acc1, acc2] = await ethers.getSigners();

    // Deploy contract
    const bullsBears = await BullsBears.deploy(
      1 /* one second interval */,
      mockAggregator.address
    );
    await bullsBears.deployed();

    // Mint Tokens
    let tx = await bullsBears.connect(owner).safeMint(acc1.address);
    await tx.wait();
    tx = await bullsBears.connect(owner).safeMint(acc2.address);
    await tx.wait();

    // Get initial account tokens URI
    const acc1TokenId = await bullsBears
      .connect(acc1)
      .tokenOfOwnerByIndex(acc1.address, 0);
    const acc1TokenURIInitial = await bullsBears
      .connect(acc1)
      .tokenURI(acc1TokenId);
    const acc2TokenId = await bullsBears
      .connect(acc2)
      .tokenOfOwnerByIndex(acc2.address, 0);
    const acc2TokenURIInitial = await bullsBears
      .connect(acc2)
      .tokenURI(acc2TokenId);

    console.log("Acc1 token URI (Bull):", acc1TokenURIInitial);
    console.log("Acc2 token URI (Bull):", acc2TokenURIInitial);

    // Update btc price in aggregator
    const newBTCPrice = 100_000_000;
    tx = await mockAggregator.connect(owner).updateAnswer(newBTCPrice);
    await tx.wait();

    // Check upkeep interval has passed
    const upkeep = await bullsBears.connect(owner).checkUpkeep([]); // no params are passed
    console.log("Upkeep:", upkeep);
    expect(upkeep[0]).to.equal(true);

    // Perform upkeep
    tx = await bullsBears.connect(owner).performUpkeep([]);
    await tx.wait();

    // Fetch updated token URIs
    const acc1TokenURIFinal = await bullsBears
      .connect(acc1)
      .tokenURI(acc1TokenId);
    const acc2TokenURIFinal = await bullsBears
      .connect(acc2)
      .tokenURI(acc2TokenId);

    console.log("Acc1 token URI (Bear):", acc1TokenURIFinal);
    console.log("Acc2 token URI (Bear):", acc2TokenURIFinal);

    expect(acc1TokenURIInitial).not.equal(acc1TokenURIFinal);
    expect(acc2TokenURIInitial).not.equal(acc2TokenURIFinal);
  });
});
