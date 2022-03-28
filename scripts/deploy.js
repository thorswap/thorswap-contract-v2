const hre = require("hardhat");

async function main() {
  const signer = await ethers.getSigner();
  const Contract = await hre.ethers.getContractFactory(
    "TSAggregator2LegUniswapV2"
  );
  const args = [
    "0xF892Fef9dA200d9E84c9b0647ecFF0F34633aBe8", // TTP
    "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", // Mainnet WETH
    "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", // Mainnet UniV2 router
    // "0xE592427A0AEce92De3Edee1F18E0157C05861564", // Mainnet UniV3 router
    // "10000", // V3 poolFee
    // "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45", // Mainnet UniV2/V3 Router
    // "0xc778417E063141139Fce010982780140Aa0cD5Ab", // Ropsten WETH
    // "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45", // Ropsten UniV2/V3 Router
    "0xE308B9562de7689B2d31C76a41649933F38ab761", // Mainnet USDC
  ];
  //const contract = await Contract.deploy(...args);
  //await contract.deployed();
  const contract = { address: "0x77b34A3340eDdD56799749be4Be2c322547E2428" };
  console.log(contract.address, args);
  if (hre.network.name !== "hardhat") {
    await new Promise((resolve) => setTimeout(resolve, 30000));
    await hre.run("verify:verify", {
      address: contract.address,
      constructorArguments: args,
    });
  }
  console.log("Contract deployed to:", contract.address);
  //await (await contract.setFee("50", signer.address)).wait();
  //console.log("Fee set");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
