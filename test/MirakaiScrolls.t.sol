// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/stdlib.sol";
import {MirakaiScrolls} from "../src/MirakaiScrolls.sol";
import {MirakaiScrollsRenderer} from "../src/MirakaiScrollsRenderer.sol";
import {MirakaiDnaParser} from "../src/MirakaiDnaParser.sol";
import {OrbsToken} from "../src/OrbsToken/OrbsToken.sol";
import {TestVm} from "./TestVm.sol";

contract MirakaiScrollsTest is DSTest, TestVm {
    MirakaiScrolls private mirakaiScrolls;
    MirakaiScrollsRenderer private mirakaiScrollsRenderer;
    MirakaiDnaParser private mirakaiDnaParser;
    OrbsToken private orbs;

    // public/private key for signatures
    address signer = 0x4A455783fC9022800FC6C03A73399d5bEB4065e8;
    uint256 signerPk =
        0x3532c806834d0a952c89f8954e2f3c417e3d6a5ad0d985c4a87a545da0ca722a;

    address user1 = 0x2Af416FDA8d86fAabDe21758aEea6c1BA5Da1f38;
    address user2 = 0x4b3d0D71A31F1f5e28B79bc0222bFEef4449B479;
    address user3 = 0xdb3f55B9559566c57987e523Be1aFb09Dd5df59c;

    function setUp() public {
        mirakaiScrollsRenderer = new MirakaiScrollsRenderer();
        mirakaiDnaParser = new MirakaiDnaParser();
        mirakaiScrolls = new MirakaiScrolls();
        orbs = new OrbsToken("mock", "mock", 18, 10);

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

    // should mint tokens
    function testPublicMint() public {
        mirakaiScrolls.flipMint();

        vm.startPrank(user1, user1);
        mirakaiScrolls.publicMint(5);

        assertEq(mirakaiScrolls.balanceOf(user1), 5);
        assertEq(mirakaiScrolls.totalSupply(), 5);
    }

    function testTeamMint() public {
        mirakaiScrolls.teamMint(25);
        mirakaiScrolls.teamMint(25);

        assertEq(mirakaiScrolls.balanceOf(address(this)), 50);
        assertEq(mirakaiScrolls.totalSupply(), 50);

        vm.expectRevert(MirakaiScrolls.TeamMintOver.selector);
        mirakaiScrolls.teamMint(1);
    }

    // should revert if mint is not active
    function testPublicMintRevert() public {
        vm.startPrank(user1, user1);
        vm.expectRevert(MirakaiScrolls.MintNotActive.selector);
        mirakaiScrolls.publicMint(5);
    }

    // should mint tokens for valid sigs
    function testAllowListMint() public {
        mirakaiScrolls.flipAllowListMint();

        vm.startPrank(user1, user1);
        mirakaiScrolls.allowListMint(signMessage(user1, 1, 0));

        assertEq(mirakaiScrolls.balanceOf(user1), 1);
        assertEq(mirakaiScrolls.totalSupply(), 1);
    }

    // should revert for invalid sigs
    function testAllowListMintRevertInvalidSig() public {
        mirakaiScrolls.flipAllowListMint();

        vm.startPrank(user1, user1);
        bytes memory signature = signMessage(user2, 1, 0);
        vm.expectRevert(MirakaiScrolls.InvalidSignature.selector);
        mirakaiScrolls.allowListMint(signature);
    }

    // wallet cannot mint multiple times
    function testAllowListMultipleMintRevert() public {
        mirakaiScrolls.flipAllowListMint();

        vm.startPrank(user1, user1);
        bytes memory signature = signMessage(user1, 1, 0);
        mirakaiScrolls.allowListMint(signature);

        assertEq(mirakaiScrolls.balanceOf(user1), 1);
        assertEq(mirakaiScrolls.totalSupply(), 1);

        vm.expectRevert(MirakaiScrolls.WalletAlreadyMinted.selector);
        mirakaiScrolls.allowListMint(signature);
    }

    // should revert if mint is not active
    function testAllowListMintRevertNotActive() public {
        // flip incorrect flag
        mirakaiScrolls.flipCC0Mint();

        vm.startPrank(user1, user1);
        bytes memory signature = signMessage(user1, 1, 0);
        vm.expectRevert(MirakaiScrolls.MintNotActive.selector);
        mirakaiScrolls.allowListMint(signature);
    }

    // should mint token with cc0 trait
    function testCC0Mint() public {
        mirakaiScrolls.flipCC0Mint();

        // set cc0TraitProbability to 100%
        mirakaiScrolls.setCc0TraitsProbability(10000);

        vm.startPrank(user1, user1);

        // mint token with cc0Trait 1
        mirakaiScrolls.cc0Mint(1, (signMessage(user1, 1, 1)));

        assertEq(mirakaiScrolls.balanceOf(user1), 1);
        // check that cc0Index was properly set for token
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 1);
        assertEq(mirakaiScrolls.totalSupply(), 1);

        // logic below is to make sure we can reroll a trait, but the cc0Trait remain unaffected
        uint256[10] memory oldDnaIndexes = mirakaiDnaParser.getTraitIndexes(
            mirakaiScrolls.dna(0)
        );

        // reroll trait 3 for token 0
        mirakaiScrolls.rerollTrait(0, 3);

        uint256[10] memory newDnaIndexes = mirakaiDnaParser.getTraitIndexes(
            mirakaiScrolls.dna(0)
        );

        assertEq(oldDnaIndexes[0], newDnaIndexes[0]);
        assertEq(oldDnaIndexes[1], newDnaIndexes[1]);
        assertEq(oldDnaIndexes[2], newDnaIndexes[2]);
        // the correct trait got rerolled
        require(oldDnaIndexes[3] != newDnaIndexes[3]);
        assertEq(oldDnaIndexes[4], newDnaIndexes[4]);
        assertEq(oldDnaIndexes[5], newDnaIndexes[5]);
        assertEq(oldDnaIndexes[6], newDnaIndexes[6]);
        assertEq(oldDnaIndexes[7], newDnaIndexes[7]);
        assertEq(oldDnaIndexes[8], newDnaIndexes[8]);

        // ensure cc0 trait stayed the same
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 1);
    }

    // should revert for valid sigs
    function testCc0MintRevertInvalidSig() public {
        mirakaiScrolls.flipCC0Mint();

        vm.startPrank(user1, user1);
        bytes memory signature = signMessage(user2, 1, 0);
        vm.expectRevert(MirakaiScrolls.InvalidSignature.selector);
        mirakaiScrolls.cc0Mint(1, signature);
    }

    // wallet cannot mint multiple times
    function testCc0ListMultipleMintRevert() public {
        mirakaiScrolls.flipCC0Mint();

        vm.startPrank(user1, user1);
        bytes memory signature = signMessage(user1, 1, 1);
        mirakaiScrolls.cc0Mint(1, signature);

        assertEq(mirakaiScrolls.balanceOf(user1), 1);
        assertEq(mirakaiScrolls.totalSupply(), 1);

        vm.expectRevert(MirakaiScrolls.WalletAlreadyMinted.selector);
        mirakaiScrolls.cc0Mint(1, signature);
    }

    // should revert if mint is not active
    function testCc0MintRevertNotActive() public {
        // flip incorrect flag
        mirakaiScrolls.flipAllowListMint();

        vm.startPrank(user1, user1);
        bytes memory signature = signMessage(user1, 1, 0);
        vm.expectRevert(MirakaiScrolls.MintNotActive.selector);
        mirakaiScrolls.cc0Mint(1, signature);
    }

    // set base price for cc0 mint
    function testBasePrice() public {
        vm.deal(user1, 10 ether);

        mirakaiScrolls.setBasePrice(0.05 ether);
        mirakaiScrolls.flipCC0Mint();

        vm.startPrank(user1, user1);
        mirakaiScrolls.cc0Mint{value: 0.05 ether}(
            1,
            (signMessage(user1, 1, 1))
        );

        assertEq(mirakaiScrolls.balanceOf(user1), 1);
        assertEq(mirakaiScrolls.totalSupply(), 1);
        assertEq(user1.balance, 9.95 ether);

        vm.stopPrank();

        // revert if not enough ether sent
        vm.deal(user2, 10 ether);
        vm.startPrank(user2, user2);
        bytes memory signature = (signMessage(user2, 1, 1));
        vm.expectRevert(MirakaiScrolls.IncorrectEtherValue.selector);
        mirakaiScrolls.cc0Mint{value: 0.03 ether}(1, signature);
    }

    // set mint price for AL and public mint
    function testMintPrice() public {
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        mirakaiScrolls.setMintPrice(0.1 ether);
        mirakaiScrolls.flipAllowListMint();
        mirakaiScrolls.flipMint();

        vm.startPrank(user1, user1);
        mirakaiScrolls.allowListMint{value: 0.1 ether}(
            (signMessage(user1, 1, 0))
        );

        mirakaiScrolls.publicMint{value: 0.5 ether}(5);

        assertEq(mirakaiScrolls.balanceOf(user1), 6);
        assertEq(mirakaiScrolls.totalSupply(), 6);

        vm.stopPrank();

        // revert if not enough ether sent
        vm.startPrank(user2, user2);
        bytes memory signature = (signMessage(user2, 1, 0));
        vm.expectRevert(MirakaiScrolls.IncorrectEtherValue.selector);
        mirakaiScrolls.allowListMint{value: 0.03 ether}(signature);

        vm.expectRevert(MirakaiScrolls.IncorrectEtherValue.selector);
        mirakaiScrolls.publicMint{value: 0.03 ether}(5);
    }

    // should reroll trait 2
    function testRerollTrait() public {
        mirakaiScrolls.flipMint();
        vm.startPrank(user1, user1);
        mirakaiScrolls.publicMint(5);

        uint256 tokenid = 0;
        uint256 traitBitshift = 2;

        uint256[10] memory oldDnaIndexes = mirakaiDnaParser.getTraitIndexes(
            mirakaiScrolls.dna(tokenid)
        );

        // warp timestamp since its used as value in the pseudo-rand number
        vm.warp(3);

        mirakaiScrolls.rerollTrait(tokenid, traitBitshift);

        uint256[10] memory newDnaIndexes = mirakaiDnaParser.getTraitIndexes(
            mirakaiScrolls.dna(tokenid)
        );

        assertEq(oldDnaIndexes[0], newDnaIndexes[0]);
        assertEq(oldDnaIndexes[1], newDnaIndexes[1]);
        // require correc trait rerolled
        require(oldDnaIndexes[2] != newDnaIndexes[2]);
        assertEq(oldDnaIndexes[3], newDnaIndexes[3]);
        assertEq(oldDnaIndexes[4], newDnaIndexes[4]);
        assertEq(oldDnaIndexes[5], newDnaIndexes[5]);
        assertEq(oldDnaIndexes[6], newDnaIndexes[6]);
        assertEq(oldDnaIndexes[7], newDnaIndexes[7]);
        assertEq(oldDnaIndexes[8], newDnaIndexes[8]);
    }

    // should burn $ORBS for re-roll
    function testRerollTraitCost() public {
        mirakaiScrolls.flipMint();
        mirakaiScrolls.setRerollCost(10e18); // 10 $ORBS cost per re-roll
        orbs.mint(user1, 20e18); // mint 20 $ORBS

        assertEq(orbs.balanceOf(user1), 20e18);

        vm.startPrank(user1, user1);

        // approve $ORBS spending
        orbs.approve(address(mirakaiScrolls), type(uint256).max);

        mirakaiScrolls.publicMint(5);

        uint256 tokenid = 0;
        uint256 traitBitshift = 1;

        uint256[10] memory oldDnaIndexes = mirakaiDnaParser.getTraitIndexes(
            mirakaiScrolls.dna(tokenid)
        );

        // warp timestamp since its used as value in the pseudo-rand number
        vm.warp(3);

        // should burn 10 $ORBS
        mirakaiScrolls.rerollTrait(tokenid, traitBitshift);
        assertEq(orbs.balanceOf(user1), 10e18);

        // new trait to roll
        traitBitshift = 8;

        // warp to diff timestamp
        vm.warp(10);

        // should burn 10 $ORBS
        mirakaiScrolls.rerollTrait(tokenid, traitBitshift);
        assertEq(orbs.balanceOf(user1), 0);

        uint256[10] memory newDnaIndexes = mirakaiDnaParser.getTraitIndexes(
            mirakaiScrolls.dna(tokenid)
        );

        assertEq(oldDnaIndexes[0], newDnaIndexes[0]);
        require(oldDnaIndexes[1] != newDnaIndexes[1]);
        assertEq(oldDnaIndexes[2], newDnaIndexes[2]);
        assertEq(oldDnaIndexes[3], newDnaIndexes[3]);
        assertEq(oldDnaIndexes[4], newDnaIndexes[4]);
        assertEq(oldDnaIndexes[5], newDnaIndexes[5]);
        assertEq(oldDnaIndexes[6], newDnaIndexes[6]);
        assertEq(oldDnaIndexes[7], newDnaIndexes[7]);
        require(oldDnaIndexes[8] != newDnaIndexes[8]);

        // should revert since no more $ORBS
        vm.expectRevert(stdError.arithmeticError);
        mirakaiScrolls.rerollTrait(tokenid, traitBitshift);
    }

    // should revert, cant reroll trait 0
    function testRerollTraitRevert() public {
        mirakaiScrolls.flipMint();

        vm.startPrank(user1, user1);
        mirakaiScrolls.publicMint(5);

        uint256 tokenid = 0;
        uint256 traitBitshift = 0; //clan index

        vm.expectRevert(MirakaiScrolls.UnrollableTrait.selector);
        mirakaiScrolls.rerollTrait(tokenid, traitBitshift);
    }

    // test the $ORBS are dripping properly to wallets
    function testOrbsDripping() public {
        mirakaiScrolls.flipMint();

        // need to start from block num > 0
        vm.roll(1);

        vm.startPrank(user1, user1);
        mirakaiScrolls.publicMint(5);

        // roll forward 4 blocks
        vm.roll(5);

        // $ORBS drip 10 per scroll per block, 4 blocks have passed
        assertEq(orbs.balanceOf(user1), 10 * 5 * 4);
        assertEq(orbs.totalSupply(), 10 * 5 * 4);

        // transfer scroll to user2
        mirakaiScrolls.transferFrom(user1, user2, 0);

        // balances should not change since no blocks have progressed
        assertEq(orbs.balanceOf(user1), 10 * 5 * 4);
        assertEq(orbs.balanceOf(user2), 0);
        assertEq(orbs.totalSupply(), 10 * 5 * 4);

        // roll forward 5 blocks
        vm.roll(10);

        // user1 should have accumuated original tokens + 10 $ORBS * 4 scrolls * 5 blocks
        // user2 accumulated 10 $ORBS * 1 scroll * 5 blocks
        assertEq(orbs.balanceOf(user1), (10 * 5 * 4) + (10 * 4 * 5));
        assertEq(orbs.balanceOf(user2), 10 * 1 * 5);
        assertEq(
            orbs.totalSupply(),
            ((10 * 5 * 4) + (10 * 4 * 5)) + (10 * 1 * 5)
        );
    }

    function testBurn() public {
        // need to start from block num > 0
        vm.roll(1);

        mirakaiScrolls.flipCC0Mint();

        // set cc0TraitProbability to 100%
        mirakaiScrolls.setCc0TraitsProbability(10000);

        vm.startPrank(user1, user1);
        mirakaiScrolls.cc0Mint(1, (signMessage(user1, 1, 1)));

        assertEq(mirakaiScrolls.balanceOf(user1), 1);
        // check that cc0Index was properly set for token
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 1);
        assertEq(mirakaiScrolls.totalSupply(), 1);

        mirakaiScrolls.burn(0);

        assertEq(mirakaiScrolls.balanceOf(user1), 0);
        // check that cc0 index is zeroed out
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 0);
        // check dna is zeroed out
        assertEq(mirakaiScrolls.dna(0), 0);
        assertEq(mirakaiScrolls.totalSupply(), 0);
    }

    // --- utils ---
    function signMessage(
        address minter,
        uint256 quantity,
        uint256 cc0Index
    ) internal returns (bytes memory) {
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
        return abi.encodePacked(r, s, v);
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
