const hre = require("hardhat");

const parseUnits = ethers.utils.parseUnits;

async function main() {
  const signer = await ethers.getSigner();
  const gasPrice = (await signer.getGasPrice()).mul(150).div(100);
  const Contract = await hre.ethers.getContractFactory("TSAggregatorUniswapV2");
  const contract = Contract.attach(
    "0x2f8aedd149afbdb5206ecaf8b1a3abb9186c8053"
  );
  // https://stagenet-midgard.ninerealms.com/v2/thorchain/inbound_addresses
  const router = "0xf5583092dE43C2E40dA895e22CD43978C054241B";
  const vault = "0xfa02bd37099f283852a3b7122f9f6539cd627ef6";
  const sushi = "0x6b3595068778dd592e39a122f4f5a5cf09c90fe2";
  const tx = await contract.swapIn(
    router,
    vault,
    "=:THOR.RUNE:thor1mgh2gjlkca0ad9clrnh9g9cths6pk7l70nphze:1",
    sushi,
    parseUnits("0.1"),
    1,
    (Date.now() / 1000) | (60 * 60),
    { gasLimit: 600000, gasPrice }
  );
  console.log("hash", tx.hash);
  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
