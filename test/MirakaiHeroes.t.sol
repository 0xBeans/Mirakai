// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/stdlib.sol";
import {MirakaiHeroes} from "../src/MirakaiHeroes.sol";
import {MirakaiHeroesRenderer} from "../src/MirakaiHeroesRenderer.sol";
import {MirakaiScrolls} from "../src/MirakaiScrolls.sol";
import {MirakaiScrollsRenderer} from "../src/MirakaiScrollsRenderer.sol";
import {MirakaiDnaParser} from "../src/MirakaiDnaParser.sol";
import {OrbsToken} from "../src/OrbsToken/OrbsToken.sol";
import {TestVm} from "./TestVm.sol";

contract MirakaiHeroesTest is DSTest, TestVm {
    MirakaiHeroes private mirakaiHeroes;
    MirakaiHeroesRenderer private mirakaiHeroesRenderer;
    MirakaiScrolls private mirakaiScrolls;
    MirakaiScrollsRenderer private mirakaiScrollsRenderer;
    MirakaiDnaParser private mirakaiDnaParser;
    OrbsToken private orbs;
    // public/private key for sigs
    address signer = 0x4A455783fC9022800FC6C03A73399d5bEB4065e8;
    uint256 signerPk =
        0x3532c806834d0a952c89f8954e2f3c417e3d6a5ad0d985c4a87a545da0ca722a;

    address user1 = 0x2Af416FDA8d86fAabDe21758aEea6c1BA5Da1f38;
    address user2 = 0x4b3d0D71A31F1f5e28B79bc0222bFEef4449B479;
    address user3 = 0xdb3f55B9559566c57987e523Be1aFb09Dd5df59c;

    function setUp() public {
        mirakaiHeroes = new MirakaiHeroes();
        mirakaiHeroesRenderer = new MirakaiHeroesRenderer("mock.com/");
        mirakaiScrollsRenderer = new MirakaiScrollsRenderer();
        mirakaiDnaParser = new MirakaiDnaParser();
        mirakaiScrolls = new MirakaiScrolls();
        orbs = new OrbsToken("mock", "mock", 18, 10);

        mirakaiHeroes.initialize(
            address(mirakaiHeroesRenderer),
            address(orbs),
            address(mirakaiScrolls),
            0 // sumomCost
        );

        mirakaiScrolls.initialize(
            address(mirakaiScrollsRenderer),
            address(orbs),
            signer,
            0, // basePrice
            0, // cc0TraitsProbability
            0, // rerollTraitCost
            0 // seed
        );

        mirakaiScrollsRenderer.setmirakaiDnaParser(address(mirakaiDnaParser));
        orbs.setmirakaiScrolls(address(mirakaiScrolls));
        setDnaParserTraitsAndWeights();
    }

    // should burn scroll and summon hero
    function testSummon() public {
        // need to start block num > 0
        vm.roll(1);

        // flip all flags
        mirakaiScrolls.flipCC0Mint();
        mirakaiScrolls.flipMint();
        mirakaiScrolls.setCc0TraitsProbability(10000);

        mirakaiHeroes.setSummonCost(50e18); // 50 $ORBS

        // mint $ORBS to user
        orbs.mint(user1, 50e18);
        assertEq(orbs.balanceOf(user1), 50e18);

        vm.startPrank(user1, user1);
        orbs.approve(address(mirakaiHeroes), type(uint256).max);

        // mint 6 tokens total
        (uint8 v, bytes32 r, bytes32 s) = signMessage(user1, 1, 1);
        mirakaiScrolls.cc0Mint(1, v, r, s);
        mirakaiScrolls.publicMint(5);

        // dna
        uint256 scrollDna = mirakaiScrolls.dna(0);

        assertEq(mirakaiScrolls.balanceOf(user1), 6);
        // check that cc0Index was properly set for token
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 1);
        assertEq(mirakaiScrolls.totalSupply(), 6);

        mirakaiScrolls.setApprovalForAll(address(mirakaiHeroes), true);
        mirakaiHeroes.summon(0);

        assertEq(mirakaiScrolls.balanceOf(user1), 5);
        // check that dna was zeroed
        assertEq(mirakaiScrolls.dna(0), 0);
        assertEq(mirakaiScrolls.totalSupply(), 5);

        assertEq(mirakaiHeroes.totalSupply(), 1);
        assertEq(mirakaiHeroes.balanceOf(user1), 1);
        assertEq(mirakaiHeroes.ownerOf(0), user1);
        // check cc0 and dna were properly set for heroes
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiHeroes.dna(0)), 1);
        assertEq(mirakaiHeroes.dna(0), scrollDna);
        assertEq(orbs.balanceOf(user1), 0);

        // should revert since no more $ORBS
        vm.expectRevert(stdError.arithmeticError);
        mirakaiHeroes.summon(4);
    }

    // should mint tokens
    function testBatchSummon() public {
        // need to start block num > 0
        vm.roll(1);

        // flip all flags
        mirakaiScrolls.flipCC0Mint();
        mirakaiScrolls.flipMint();
        mirakaiScrolls.setCc0TraitsProbability(10000);

        mirakaiHeroes.setSummonCost(50e18); // 50 $ORBS

        // mint enoug $ORBS for 3 summons
        orbs.mint(user1, 150e18);
        assertEq(orbs.balanceOf(user1), 150e18);

        vm.startPrank(user1, user1);
        orbs.approve(address(mirakaiHeroes), type(uint256).max);

        // mint 6 tokens total
        (uint8 v, bytes32 r, bytes32 s) = signMessage(user1, 1, 1);
        mirakaiScrolls.cc0Mint(1, v, r, s);
        mirakaiScrolls.publicMint(5);

        // dna
        uint256 scrollDna = mirakaiScrolls.dna(0);

        assertEq(mirakaiScrolls.balanceOf(user1), 6);
        // check that cc0Index was properly set for scroll 0
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 1);
        assertEq(mirakaiScrolls.totalSupply(), 6);

        mirakaiScrolls.setApprovalForAll(address(mirakaiHeroes), true);

        uint256[] memory tokensTosummon = new uint256[](3);
        tokensTosummon[0] = 0;
        tokensTosummon[1] = 1;
        tokensTosummon[2] = 2;
        mirakaiHeroes.batchSummon(tokensTosummon);

        assertEq(mirakaiScrolls.balanceOf(user1), 3);
        // check cc0 and dna were zeroed out for scroll 0
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 0);
        assertEq(mirakaiScrolls.dna(0), 0);
        assertEq(mirakaiScrolls.totalSupply(), 3);

        assertEq(mirakaiHeroes.totalSupply(), 3);
        assertEq(mirakaiHeroes.balanceOf(user1), 3);
        // check dna was zeroed
        assertEq(mirakaiHeroes.dna(0), scrollDna);
        assertEq(orbs.balanceOf(user1), 0);
        // check that proper tokenIDs got summoned
        assertEq(mirakaiHeroes.ownerOf(0), user1);
        assertEq(mirakaiHeroes.ownerOf(1), user1);
        assertEq(mirakaiHeroes.ownerOf(2), user1);

        // should revert since no more $ORBS
        vm.expectRevert(stdError.arithmeticError);
        mirakaiHeroes.summon(4);
    }

    // should burn
    function testBurn() public {
        // cant start at block 0 or else it messes up $ORBS dripping
        vm.roll(1);
        // flip all flags
        mirakaiScrolls.flipCC0Mint();
        mirakaiScrolls.flipMint();
        mirakaiScrolls.setCc0TraitsProbability(10000);

        mirakaiHeroes.setSummonCost(50e18); // 50 $ORBS

        // mint $ORBS to user
        orbs.mint(user1, 50e18);
        assertEq(orbs.balanceOf(user1), 50e18);

        vm.startPrank(user1, user1);
        orbs.approve(address(mirakaiHeroes), type(uint256).max);

        (uint8 v, bytes32 r, bytes32 s) = signMessage(user1, 1, 1);
        mirakaiScrolls.cc0Mint(1, v, r, s);

        assertEq(orbs.balanceOf(user1), 50e18);

        mirakaiScrolls.setApprovalForAll(address(mirakaiHeroes), true);
        mirakaiHeroes.summon(0);
        mirakaiHeroes.burn(0);

        assertEq(mirakaiHeroes.totalSupply(), 0);
        assertEq(mirakaiHeroes.balanceOf(user1), 0);
        // check dna is zero
        assertEq(mirakaiHeroes.dna(0), 0);
        assertEq(orbs.balanceOf(user1), 0);

        // should stop dripping after burn
        vm.roll(10);
        assertEq(orbs.balanceOf(user1), 0);
    }

    // --- utils ---
    function signMessage(
        address minter,
        uint256 quantity,
        uint256 cc0Index
    ) internal returns (uint8, bytes32, bytes32) {
        bytes32 messageHash = mirakaiScrolls.getMessageHash(
            minter,
            quantity,
            cc0Index
        );
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            signerPk,
            ethSignedMessageHash
        );
        return (v, r, s);
    }

    function setDnaParserTraitsAndWeights() internal {
        MirakaiDnaParser.TraitWeights[]
            memory tw = new MirakaiDnaParser.TraitWeights[](10);

        uint256[] memory weights = new uint256[](6);
        weights[0] = 1000;
        weights[1] = 1000;
        weights[2] = 1000;
        weights[3] = 1000;
        weights[4] = 1000;
        weights[5] = 5000;

        string[] memory clans = new string[](6);
        clans[0] = "clan 1";
        clans[1] = "clan 2";
        clans[2] = "clan 3";
        clans[3] = "clan 4";
        clans[4] = "clan 5";
        clans[5] = "clan 6";

        string[] memory genus = new string[](6);
        genus[0] = "genus 1";
        genus[1] = "genus 2";
        genus[2] = "genus 3";
        genus[3] = "genus 4";
        genus[4] = "genus 5";
        genus[5] = "genus 6";

        string[] memory heads = new string[](6);
        heads[0] = "head 1";
        heads[1] = "head 2";
        heads[2] = "head 3";
        heads[3] = "head 4";
        heads[4] = "head 5";
        heads[5] = "head 6";

        string[] memory eyes = new string[](6);
        eyes[0] = "eye 1";
        eyes[1] = "eye 2";
        eyes[2] = "eye 3";
        eyes[3] = "eye 4";
        eyes[4] = "eye 5";
        eyes[5] = "eye 6";

        string[] memory mouths = new string[](6);
        mouths[0] = "mouth 1";
        mouths[1] = "mouth 2";
        mouths[2] = "mouth 3";
        mouths[3] = "mouth 4";
        mouths[4] = "mouth 5";
        mouths[5] = "mouth 6";

        string[] memory tops = new string[](6);
        tops[0] = "top 1";
        tops[1] = "top 2";
        tops[2] = "top 3";
        tops[3] = "top 4";
        tops[4] = "top 5";
        tops[5] = "top 6";

        string[] memory bottoms = new string[](6);
        bottoms[0] = "bottom 1";
        bottoms[1] = "bottom 2";
        bottoms[2] = "bottom 3";
        bottoms[3] = "bottom 4";
        bottoms[4] = "bottom 5";
        bottoms[5] = "bottom 6";

        string[] memory weapons = new string[](6);
        weapons[0] = "weapons 1";
        weapons[1] = "weapons 2";
        weapons[2] = "weapons 3";
        weapons[3] = "weapons 4";
        weapons[4] = "weapons 5";
        weapons[5] = "weapons 6";

        string[] memory markings = new string[](6);
        markings[0] = "markings 1";
        markings[1] = "markings 2";
        markings[2] = "markings 3";
        markings[3] = "markings 4";
        markings[4] = "markings 5";
        markings[5] = "markings 6";

        string[] memory cc0s = new string[](6);
        cc0s[0] = "cc0 1";
        cc0s[1] = "cc0 2";
        cc0s[2] = "cc0 3";
        cc0s[3] = "cc0 4";
        cc0s[4] = "cc0 5";
        cc0s[5] = "No cc0";

        tw[0] = MirakaiDnaParser.TraitWeights(0, clans, weights);
        tw[1] = MirakaiDnaParser.TraitWeights(1, genus, weights);
        tw[2] = MirakaiDnaParser.TraitWeights(2, heads, weights);
        tw[3] = MirakaiDnaParser.TraitWeights(3, eyes, weights);
        tw[4] = MirakaiDnaParser.TraitWeights(4, mouths, weights);
        tw[5] = MirakaiDnaParser.TraitWeights(5, tops, weights);
        tw[6] = MirakaiDnaParser.TraitWeights(6, bottoms, weights);
        tw[7] = MirakaiDnaParser.TraitWeights(7, weapons, weights);
        tw[8] = MirakaiDnaParser.TraitWeights(8, markings, weights);
        tw[9] = MirakaiDnaParser.TraitWeights(9, cc0s, weights);

        mirakaiDnaParser.setTraitsAndWeights(tw);
    }
}
