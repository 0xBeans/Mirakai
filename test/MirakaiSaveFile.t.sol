// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import {console} from "forge-std/console.sol";
import {MirakaiScrollsRenderer} from "../src/MirakaiScrollsRenderer.sol";
import {MirakaiDnaParser} from "../src/MirakaiDnaParser.sol";
import {TestVm} from "./TestVm.sol";

contract MirakaiSaveFileTest is DSTest, TestVm {
    MirakaiScrollsRenderer private mirakaiScrollsRenderer;
    MirakaiDnaParser private mirakaiDnaParser;

    function setUp() public {
        mirakaiScrollsRenderer = new MirakaiScrollsRenderer();
        mirakaiDnaParser = new MirakaiDnaParser();

        mirakaiScrollsRenderer.setmirakaiDnaParser(address(mirakaiDnaParser));
    }

    function testSaveFileOriginalFont() public {
        uint256 gasBefore = gasleft();
        string memory path = "initialize-scripts/slkscreen.txt";
        string memory fontData = vm.readFile(path);

        mirakaiScrollsRenderer.saveFile(0, fontData);

        console.log(gasBefore - gasleft());
    }

    function testSaveFileOptimizedFont() public {
        uint256 gasBefore = gasleft();
        string memory path = "initialize-scripts/silkscreen-op.txt";
        string memory fontData = vm.readFile(path);

        mirakaiScrollsRenderer.saveFile(0, fontData);

        console.log(gasBefore - gasleft());
    }

    function testSaveFileOptimized2Font() public {
        uint256 gasBefore = gasleft();
        string memory path = "initialize-scripts/silkscreen-op2.txt";
        string memory fontData = vm.readFile(path);

        mirakaiScrollsRenderer.saveFile(0, fontData);

        console.log(gasBefore - gasleft());
    }
}
