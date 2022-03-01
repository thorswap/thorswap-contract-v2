const { Relayer } = require("defender-relay-client");
const { ethers } = require("ethers");
const {
  DefenderRelaySigner,
  DefenderRelayProvider,
} = require("defender-relay-client/lib/ethers");

const abiThor = ["function transfer(address, uint256)"];
const abiSushi = [
  "function getAmountsOut(uint256, address[]) returns (uint256[])",
  "function swapExactETHForTokens(uint256, address[], address, uint256)",
];

const contractWeth = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
const contractSushi = "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F";
const contractThor = "0xa5f2211b9b8170f694421f2046281775e8468044";
const contractVthor = "0x...";
const contractTreasury = "0x...";

exports.handler = async function (event) {
  const provider = new DefenderRelayProvider(event);
  const signer = new DefenderRelaySigner(event, provider, { speed: "fast" });
  const contractSushi = new ethers.Contract(contractSushi, abiSushi, signer);
  const contractThor = new ethers.Contract(contractThor, abiThor, signer);

  const amount = await signer.getBlance().sub(ethers.utils.parseUnits("1"));
  const buybackAmount = amount.mul("75").div("100");

  // Send 25% of ETH balance to treasury
  const txT = signer.sendTransaction({
    to: contractTreasury,
    value: amount.sub(buybackAmount),
  });

  // Swap 75% of ETH balance to THOR
  const swapPath = [contractWeth, contractThor];
  const swapTo = contractVthor;
  const swapDeadline = ((Date.now() / 1000) | 0) + 10 * 60;
  const quoteAmounts = await contractSushi.getAmountsOut(
    buybackAmount,
    swapPath
  );
  const swapMinOut = quoteAmounts[1].mul("975").div("1000");
  let txS = await contractSushi.swapExactETHForTokens(
    swapMinOut,
    swapPath,
    swapTo,
    swapDeadline,
    { value: buybackAmount }
  );
  return {
    txTreasury: txT.hash,
    txSwap: txS.hash,
    amount: ethers.utils.formatUnits(amount),
  };
};
