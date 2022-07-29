// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import {console} from "forge-std/console.sol";
import {MirakaiScrollsRenderer} from "../src/MirakaiScrollsRenderer.sol";
import {MirakaiDnaParser} from "../src/MirakaiDnaParser.sol";
import {TestVm} from "./TestVm.sol";

contract MirakaiScrollsRendererTest is DSTest, TestVm {
    MirakaiScrollsRenderer private mirakaiScrollsRenderer;
    MirakaiDnaParser private mirakaiDnaParser;

    function setUp() public {
        mirakaiScrollsRenderer = new MirakaiScrollsRenderer();
        mirakaiDnaParser = new MirakaiDnaParser();

        mirakaiScrollsRenderer.setmirakaiDnaParser(address(mirakaiDnaParser));

        string memory path = "initialize-scripts/silkscreen-op2.txt";
        string memory fontData = vm.readFile(path);

        mirakaiScrollsRenderer.saveFile(0, fontData);

        setDnaParserTraitsAndWeights();
    }

    function testMirakaiScrollsRendererTokenURI() public view {
        string memory dataURI = mirakaiScrollsRenderer.tokenURI(0, 0);

        console.log(dataURI);
    }

    // --- utils ---

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
