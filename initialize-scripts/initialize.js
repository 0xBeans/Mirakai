const fs = require("fs");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Initializing contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // todo: Update the addresses to attach to after deploy
  const MirakaiDnaParser = await ethers.getContractFactory("MirakaiDnaParser");
  const mirakaiDnaParser = await MirakaiDnaParser.attach("0x949dfbceac07d95c1e416b6ddd82f23a8bf3b44e");

  const MirakaiScrollsRenderer = await ethers.getContractFactory("MirakaiScrollsRenderer");
  const mirakaiScrollsRenderer = await MirakaiScrollsRenderer.attach("0x6a2fc780120a689cdc4b703805945ec86ac04836");

  // read base64 encoded font
  const file = await fs.readFileSync(
    __dirname + '/slkscreen.txt'
  );

  const content = file.toString();
  
  // font file is < 24KB and can be set in a single txn in contract storage
  let setFontTxn = await mirakaiScrollsRenderer.saveFile(0, content);

  console.log('setFontTxn', setFontTxn);

  // These values will change to real weights and traits when we deploy to mainnet
  const traitsAndWeights = [
    {
      index: 0,
      traitNames: ["clan 1","clan 2","clan 3","clan 4","clan 5"],
      traitWeights: [2000,2000,2000,2000,2000]
    },
    {
      index: 1,
      traitNames: ["genus 1","genus 2","genus 3","genus 4","genus 5"],
      traitWeights: [2000,2000,2000,2000,2000]
    },
    {
      index: 2,
      traitNames: ["head 1","head 2","head 3","head 4","head 5","head 6","head 7","head 8","head 9","head 10","head 11", "head 12"],
      traitWeights: [200,200,200,200,200,500,500,1000,1000,1000,2000,3000]
    },
    {
      index: 3,
      traitNames: ["eye 1","eye 2","eye 3","eye 4","eye 5","eye 6","eye 7","eye 8","eye 9","eye 10","eye 11", "eye 12"],
      traitWeights: [200,200,200,200,200,500,500,1000,1000,1000,2000,3000]
    },
    {
      index: 4,
      traitNames: ["mouth 1","mouth 2","mouth 3","mouth 4","mouth 5","mouth 6","mouth 7","mouth 8","mouth 9","mouth 10","mouth 11", "mouth 12"],
      traitWeights: [200,200,200,200,200,500,500,1000,1000,1000,2000,3000]
    },
    {
      index: 5,
      traitNames: ["top 1","top 2","top 3","top 4","top 5","top 6","top 7","top 8","top 9","top 10","top 11", "top 12"],
      traitWeights: [200,200,200,200,200,500,500,1000,1000,1000,2000,3000]
    },
    {
      index: 6,
      traitNames: ["bottom 1","bottom 2","bottom 3","bottom 4","bottom 5","bottom 6","bottom 7","bottom 8","bottom 9","bottom 10","bottom 11", "bottom 12"],
      traitWeights: [200,200,200,200,200,500,500,1000,1000,1000,2000,3000]
    },
    {
      index: 7,
      traitNames: ["weapon 1","weapon 2","weapon 3","weapon 4","weapon 5","weapon 6","weapon 7","weapon 8","weapon 9","weapon 10","weapon 11", "weapon 12"],
      traitWeights: [200,200,200,200,200,500,500,1000,1000,1000,2000,3000]
    },
    {
      index: 8,
      traitNames: ["marking 1","marking 2","marking 3","marking 4","marking 5","marking 6","marking 7","marking 8","marking 9","marking 10","marking 11", "marking 12"],
      traitWeights: [200,200,200,200,200,500,500,1000,1000,1000,2000,3000]
    },
    {
      index: 9,
      traitNames: ["cc0 1","cc0 2","cc0 3","cc0 4","cc0 5"],
      traitWeights: [9996,1,1,1,1] // cc0 is no cc0 trait, all cc0 traits are set with different logic and are rare
    }
  ]

  // set weights and traits in 2 txns
  let firstTxn = await mirakaiDnaParser.setTraitsAndWeights(traitsAndWeights.slice(0, 4));
  let secondTxn = await mirakaiDnaParser.setTraitsAndWeights(traitsAndWeights.slice(4));

  console.log('firstTxn', firstTxn);
  console.log('secondTxn', secondTxn);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
