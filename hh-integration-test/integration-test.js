const { expect } = require("chai");
const { ethers } = require("hardhat");
const Web3 = require('web3');
const fs = require("fs");

// not used but in case we want to write more tests
let web3 = new Web3(Web3.givenProvider | 'ws://some.local-or-remote.node:8546');

describe("Mirakai Full integration tests", function () {
  let mirakaiScrollsFactory;
  let mirakaiScrollsRendererFactory;
  let mirakaiHeroesFactory;
  let mirakaiHeroesRendererFactory;
  let mirakaiDnaParserFactory;
  let orbsFactory;

  let mirakaiScrolls;
  let mirakaiScrollsRenderer;
  let mirakaiHeroes;
  let mirakaiHeroesRenderer;
  let mirakaiDnaParser;
  let orbs;

  let owner;
  let addr1;
  let addr2;
  let addrs;

  // for signing
  let signer = "0x4A455783fC9022800FC6C03A73399d5bEB4065e8";
  let signerPk =
      "0x3532c806834d0a952c89f8954e2f3c417e3d6a5ad0d985c4a87a545da0ca722a";

  beforeEach(async function() {
    mirakaiScrollsFactory = await ethers.getContractFactory("MirakaiScrolls");
    mirakaiScrollsRendererFactory = await ethers.getContractFactory("MirakaiScrollsRenderer");
    mirakaiHeroesFactory = await ethers.getContractFactory("MirakaiHeroes");
    mirakaiHeroesRendererFactory = await ethers.getContractFactory("MirakaiHeroesRenderer");
    mirakaiDnaParserFactory = await ethers.getContractFactory("MirakaiDnaParser");
    orbsFactory = await ethers.getContractFactory("OrbsToken");

    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    mirakaiScrolls = await mirakaiScrollsFactory.deploy();
    mirakaiScrollsRenderer = await mirakaiScrollsRendererFactory.deploy();
    mirakaiHeroes = await mirakaiHeroesFactory.deploy();
    mirakaiHeroesRenderer = await mirakaiHeroesRendererFactory.deploy("mock.com/");
    mirakaiDnaParser = await mirakaiDnaParserFactory.deploy();
    orbs = await orbsFactory.deploy("mock", "mock", 18, 10);
    
    await mirakaiScrolls.initialize(
        mirakaiScrollsRenderer.address,
        orbs.address,
        signer,
        0,
        0,
        0,
        0
    );

    await mirakaiHeroes.initialize(
        mirakaiHeroesRenderer.address,
        mirakaiDnaParser.address,
        orbs.address,
        mirakaiScrolls.address,
        0
    );

    await mirakaiScrollsRenderer.setmirakaiDnaParser(mirakaiDnaParser.address);
    await orbs.setmirakaiScrolls(mirakaiScrolls.address);

    const files = [];

    const file = await fs.readFileSync(
        __dirname + '/../initialize-scripts/slkscreen.txt'
    );

    const content = file.toString();

    await mirakaiScrollsRenderer.saveFile(0, content);

    const traitsAndWeights = [
      {
        index: 0,
        traitNames: ["clan 1","clan 2","clan 3","clan 4","clan 5","clan 6",],
        traitWeights: [1000,1000,1000,1000,1000,5000]
      },
      {
        index: 1,
        traitNames: ["genus 1","genus 2","genus 3","genus 4","genus 5","genus 6",],
        traitWeights: [1000,1000,1000,1000,1000,5000]
      },
      {
        index: 2,
        traitNames: ["head 1","head 2","head 3","head 4","head 5","head 6",],
        traitWeights: [1000,1000,1000,1000,1000,5000]
      },
      {
        index: 3,
        traitNames: ["eye 1","eye 2","eye 3","eye 4","eye 5","eye 6",],
        traitWeights: [1000,1000,1000,1000,1000,5000]
      },
      {
        index: 4,
        traitNames: ["mouth 1","mouth 2","mouth 3","mouth 4","mouth 5","mouth 6",],
        traitWeights: [1000,1000,1000,1000,1000,5000]
      },
      {
        index: 5,
        traitNames: ["top 1","top 2","top 3","top 4","top 5","top 6",],
        traitWeights: [1000,1000,1000,1000,1000,5000]
      },
      {
        index: 6,
        traitNames: ["bottom 1","bottom 2","bottom 3","bottom 4","bottom 5","bottom 6",],
        traitWeights: [1000,1000,1000,1000,1000,5000]
      },
      {
        index: 7,
        traitNames: ["weapon 1","weapon 2","weapon 3","weapon 4","weapon 5","weapon 6",],
        traitWeights: [1000,1000,1000,1000,1000,5000]
      },
      {
        index: 8,
        traitNames: ["marking 1","marking 2","marking 3","marking 4","marking 5","marking 6",],
        traitWeights: [1000,1000,1000,1000,1000,5000]
      },
      {
        index: 9,
        traitNames: ["cc0 1","cc0 2","cc0 3","cc0 4","cc0 5","cc0 6",],
        traitWeights: [1000,1000,1000,1000,1000,5000]
      }
    ]

    await mirakaiDnaParser.setTraitsAndWeights(traitsAndWeights);

  })

  it("should mint-drip-reroll-summon", async function () {
      await mirakaiScrolls.flipMint();
      await mirakaiScrolls.publicMint(5);
      
      // get the block when tokens start dripping  
      let startBlock = await hre.ethers.provider.getBlock("latest")

      expect(await mirakaiScrolls.totalSupply()).to.equal('5');
      expect(await mirakaiScrolls.balanceOf(owner.address)).to.equal('5');

      // roll forward 5 blocks
      await ethers.provider.send('evm_mine')
      await ethers.provider.send('evm_mine')
      await ethers.provider.send('evm_mine')
      await ethers.provider.send('evm_mine')
      await ethers.provider.send('evm_mine')

      // token uri before trait reroll
      let scrollsTokenUri = await mirakaiScrolls.tokenURI(0);

      let oldDna = await mirakaiScrolls.dna(0);
      let oldIndexes = await mirakaiDnaParser.getTraitIndexes(oldDna);

      // reroll token 0 at trait 2
      await mirakaiScrolls.rerollTrait(0, 2);

      // token uri after trait reroll
      let scrollsTokenUriRerolled = await mirakaiScrolls.tokenURI(0);

      let newDna = await mirakaiScrolls.dna(0);
      let newIndexes = await mirakaiDnaParser.getTraitIndexes(newDna);

      // check the trait was rerolled
      expect(newIndexes[0]).to.equal(oldIndexes[0]);
      expect(newIndexes[1]).to.equal(oldIndexes[1]);
      // if this fails, rerun test a few times. Sometimes randomness still lands on the same trait
      expect(newIndexes[2]).to.not.equal(oldIndexes[2]);
      expect(newIndexes[3]).to.equal(oldIndexes[3]);
      expect(newIndexes[4]).to.equal(oldIndexes[4]);
      expect(newIndexes[5]).to.equal(oldIndexes[5]);
      expect(newIndexes[6]).to.equal(oldIndexes[6]);
      expect(newIndexes[7]).to.equal(oldIndexes[7]);
      expect(newIndexes[8]).to.equal(oldIndexes[8]);
      
      // curr block number
      let currBlock = await hre.ethers.provider.getBlock("latest")

      // 5 scrolls * (currBlock - startBlock) * 10 $ORBS per block
      expect(await orbs.balanceOf(owner.address)).to.equal((currBlock.number - startBlock.number) * 5 * 10);

      // set approval and summon
      await mirakaiScrolls.setApprovalForAll(mirakaiHeroes.address, true);
      await mirakaiHeroes.summon(0);

      expect(await mirakaiScrolls.totalSupply()).to.equal('4');
      expect(await mirakaiScrolls.balanceOf(owner.address)).to.equal('4');
      expect(await mirakaiHeroes.totalSupply()).to.equal('1');
      expect(await mirakaiHeroes.balanceOf(owner.address)).to.equal('1');

      let heroesTokenUri = await mirakaiHeroes.tokenURI(0);

      // didnt feel like decoding base64 and checking the raw SVG 
      // so no tests here, just console.log and verify everything is correct
      console.log("scrolls URI", scrollsTokenUri);
      console.log("scrolls URI Rerolled", scrollsTokenUriRerolled);
      console.log("heroes URI", heroesTokenUri);
  });
});
