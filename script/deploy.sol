// ███╗░░░███╗██╗██████╗░░█████╗░██╗░░██╗░█████╗░██╗
// ████╗░████║██║██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██║
// ██╔████╔██║██║██████╔╝███████║█████═╝░███████║██║
// ██║╚██╔╝██║██║██╔══██╗██╔══██║██╔═██╗░██╔══██║██║
// ██║░╚═╝░██║██║██║░░██║██║░░██║██║░╚██╗██║░░██║██║
// ╚═╝░░░░░╚═╝╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝
//
// Quick script to deploy and initialize all contracts.
// Still need to run initialize-scripts/initialize.js
// to properly set the font + traits. This is easier to
// do in JS as there is no stack too deep errors to
// think about and reading the font file is easy.

///@author 0xBeans

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/stdlib.sol";
import {TestVm} from "../src/test/TestVm.sol";

import {MirakaiHeroes} from "../src/MirakaiHeroes.sol";
import {MirakaiHeroesRenderer} from "../src/MirakaiHeroesRenderer.sol";
import {MirakaiScrolls} from "../src/MirakaiScrolls.sol";
import {MirakaiScrollsRenderer} from "../src/MirakaiScrollsRenderer.sol";
import {MirakaiDnaParser} from "../src/MirakaiDnaParser.sol";
import {OrbsToken} from "../src/OrbsToken/OrbsToken.sol";

contract Deploy is TestVm {
    function run() external {
        vm.startBroadcast();

        MirakaiDnaParser mirakaiDnaParser = new MirakaiDnaParser();

        MirakaiScrollsRenderer mirakaiScrollsRenderer = new MirakaiScrollsRenderer();
        mirakaiScrollsRenderer.setmirakaiDnaParser(address(mirakaiDnaParser));

        OrbsToken orbsToken = new OrbsToken("test", "test", 18, 2500);

        MirakaiHeroesRenderer mirakaiHeroesRenderer = new MirakaiHeroesRenderer(
            "mock.com/"
        );

        MirakaiScrolls mirakaiScrolls = new MirakaiScrolls();
        mirakaiScrolls.initialize(
            address(mirakaiScrollsRenderer),
            address(orbsToken),
            0x4A455783fC9022800FC6C03A73399d5bEB4065e8,
            0,
            0,
            0,
            928374
        );

        orbsToken.setmirakaiScrolls(address(mirakaiScrolls));

        MirakaiHeroes mirakaiHeroes = new MirakaiHeroes();
        mirakaiHeroes.initialize(
            address(mirakaiHeroesRenderer),
            address(mirakaiDnaParser),
            address(orbsToken),
            address(mirakaiScrolls),
            0
        );

        // todo: remove this
        mirakaiScrolls.flipMint();
        mirakaiScrolls.publicMint(5);

        console.log("mirakaiDnaParser", address(mirakaiDnaParser));
        console.log("mirakaiScrollsRenderer", address(mirakaiScrollsRenderer));
        console.log("orbsToken", address(orbsToken));
        console.log("mirakaiHeroesRenderer", address(mirakaiHeroesRenderer));
        console.log("mirakaiScrolls", address(mirakaiScrolls));
        console.log("mirakaiHeroes", address(mirakaiHeroes));
    }
}
