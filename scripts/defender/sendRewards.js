const { Relayer } = require("defender-relay-client");
const { ethers } = require("ethers");
const {
  DefenderRelaySigner,
  DefenderRelayProvider,
} = require("defender-relay-client/lib/ethers");

const abi = ["function sendRewards()"];

const contractRewardsForwarder = "0x8f631816043c8e8Cad0C4c602bFe7Bff1B22b182";

exports.handler = async function (event) {
  const provider = new DefenderRelayProvider(event);
  const signer = new DefenderRelaySigner(event, provider, { speed: "fast" });
  const contract = new ethers.Contract(contractRewardsForwarder, abi, signer);
  const tx = await contract.sendRewards();
  return { tx: tx.hash };
};
