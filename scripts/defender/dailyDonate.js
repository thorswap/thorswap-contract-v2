const { Relayer } = require("defender-relay-client");
const { ethers } = require("ethers");
const {
  DefenderRelaySigner,
  DefenderRelayProvider,
} = require("defender-relay-client/lib/ethers");

const abi = ["function transfer(address, uint256)"];

const contractThor = "0xa5f2211b9b8170f694421f2046281775e8468044";
const contractVthor = "0x...";

exports.handler = async function (event) {
  const provider = new DefenderRelayProvider(event);
  const signer = new DefenderRelaySigner(event, provider, { speed: "fast" });
  const contract = new ethers.Contract(contractThor, abi, signer);
  const amount = ethers.utils.parseUnits("100");
  const tx = await contract.transfer(contractThor, amount);
  return { tx: tx.hash, amount: ethers.utils.formatUnits(amount) };
};
