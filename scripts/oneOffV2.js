const https = require("https");
const hre = require("hardhat");

const parseUnits = ethers.utils.parseUnits;

async function main() {
  const signer = await ethers.getSigner();
  const gasPrice = (await signer.getGasPrice()).mul(150).div(100);
  const Contract = await hre.ethers.getContractFactory("TSAggregatorUniswapV2");
  const contract = Contract.attach("0x7C38b8B2efF28511ECc14a621e263857Fb5771d3");
  const apiUrl = "https://midgard.ninerealms.com/v2/thorchain/inbound_addresses";
  // const apiUrl = "https://stagenet-midgard.ninerealms.com/v2/thorchain/inbound_addresses";
  const ethChain = (await httpRequest(apiUrl)).find((c) => c.chain === "ETH");
  const router = ethChain.router;
  const vault = ethChain.address;
  const sushi = "0x6b3595068778dd592e39a122f4f5a5cf09c90fe2";
  const tx = await contract.swapIn(
    router,
    vault,
    "=:THOR.RUNE:thor1mgh2gjlkca0ad9clrnh9g9cths6pk7l70nphze:1",
    sushi,
    parseUnits("0.1"),
    1,
    (Date.now() / 1000) | (60 * 60),
    { gasPrice }
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

function httpRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let responseBody = "";
      res.on("data", (chunk) => {
        responseBody += chunk;
      });
      res.on("end", () => {
        try {
          if (res.statusCode < 200 || 300 <= res.statusCode) {
            throw new Error(
              `Non 2xx status code: ${res.statusCode}: ${responseBody}`
            );
          }
          resolve(JSON.parse(responseBody));
        } catch (err) {
          reject(err);
        }
      });
      res.on("error", (err) => {
        reject(err);
      });
    });
    req.end();
  });
}
