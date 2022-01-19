const hre = require("hardhat");

async function main() {
  const Contract = await hre.ethers.getContractFactory("TSAggregatorUniswapV2");
  const args = [
    "3000",
    "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
    "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
  ];
  //const contract = await Contract.deploy(...args);
  //await contract.deployed();
  const contract = { address: "0x2f8aedd149afbdb5206ecaf8b1a3abb9186c8053" };
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
