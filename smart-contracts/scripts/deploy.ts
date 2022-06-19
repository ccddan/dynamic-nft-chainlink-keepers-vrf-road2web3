import { ethers } from "hardhat";

async function main() {
  const BullsBears = await ethers.getContractFactory("BullsBears");
  const updateIntervalInSeconds = 60;
  const btcUSDPriceFeedPolygonAddress =
    "0x007A22900a3B98143368Bd5906f8E17e9867581b";

  const bullsBears = await BullsBears.deploy(
    updateIntervalInSeconds,
    btcUSDPriceFeedPolygonAddress
  );

  await bullsBears.deployed();

  console.log("bullsBears deployed at:", bullsBears.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
