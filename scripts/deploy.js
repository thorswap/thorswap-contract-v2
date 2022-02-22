const hre = require("hardhat");

async function main() {
  const signer = await ethers.getSigner();
  const Contract = await hre.ethers.getContractFactory("TSAggregatorGeneric");
  const args = [
    // "3000", // V3 poolFee
    // "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", // Mainnet WETH
    // "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45", // Mainnet UniV2/V3 Router
    // "0xc778417E063141139Fce010982780140Aa0cD5Ab", // Ropsten WETH
    // "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45", // Ropsten UniV2/V3 Router
  ];
  const contract = await Contract.deploy(...args);
  await contract.deployed();
  //const contract = { address: "0x1e181df53d07b698c6a58ca6308ab5d827f116e1" };
  console.log(contract.address, args);
  if (hre.network.name !== "hardhat") {
    await new Promise((resolve) => setTimeout(resolve, 20000));
    await hre.run("verify:verify", {
      address: contract.address,
      constructorArguments: args,
    });
  }
  console.log("Contract deployed to:", contract.address);
  await (await contract.setFee("50", signer.address)).wait();
  console.log("Fee set");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
