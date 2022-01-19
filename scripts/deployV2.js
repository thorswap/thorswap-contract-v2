const hre = require("hardhat");

async function main() {
  const Contract = await hre.ethers.getContractFactory("TSAggregatorUniswapV2");
  const args = [
    "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
    "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  ];
  //const contract = await Contract.deploy(...args);
  //await contract.deployed();
  const contract = { address: "0x1e181df53d07b698c6a58ca6308ab5d827f116e1" };
  console.log(contract.address, args);
  if (hre.network.name !== "hardhat") {
    //await new Promise(resolve => setTimeout(resolve, 20000));
    await hre.run("verify:verify", {
      address: contract.address,
      constructorArguments: args,
    });
  }
  console.log("Contract deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
