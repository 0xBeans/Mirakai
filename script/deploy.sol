// ███╗░░░███╗██╗██████╗░░█████╗░██╗░░██╗░█████╗░██╗
// ████╗░████║██║██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██║
// ██╔████╔██║██║██████╔╝███████║█████═╝░███████║██║
// ██║╚██╔╝██║██║██╔══██╗██╔══██║██╔═██╗░██╔══██║██║
// ██║░╚═╝░██║██║██║░░██║██║░░██║██║░╚██╗██║░░██║██║
// ╚═╝░░░░░╚═╝╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝
//
// Quick forge script to deploy and initialize all contracts.
// Still need to run initialize-scripts/initialize.js to
// properly set the font + traits on chain. This is easier to
// do in JS as there is no stack too deep errors to
// think about and reading the base64 font file is easy.

///@author 0xBeans

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/stdlib.sol";
import {TestVm} from "../test/TestVm.sol";

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

        OrbsToken orbsToken = new OrbsToken("ORBS", "ORBS", 18, 1.67e15);

        MirakaiHeroesRenderer mirakaiHeroesRenderer = new MirakaiHeroesRenderer(
            "https://www.api.officialmirakai.com/hero/"
        );

        MirakaiScrolls mirakaiScrolls = new MirakaiScrolls();
        mirakaiScrolls.initialize(
            address(mirakaiScrollsRenderer),
            address(orbsToken),
            0x1DbCFFe2Fd645454Ae77f13Fbbb8Aaea5369F1E9, // cc0 signer
            0x289Cd1b72b4E647481A4b2AA19172e9796507fB6, // allowlist signer
            0.05e18, // base price
            3333, // cc0 probability in bps
            10e18, // reroll cost
            832848293923984293849238432 // seed
        );

        orbsToken.setmirakaiScrolls(address(mirakaiScrolls));

        MirakaiHeroes mirakaiHeroes = new MirakaiHeroes();
        mirakaiHeroes.initialize(
            address(mirakaiHeroesRenderer),
            address(orbsToken),
            address(mirakaiScrolls),
            50e18 // summon cost
        );

        // todo: remove this when deploying, change to team mint
        // mirakaiScrolls.flipMint();
        // mirakaiScrolls.publicMint(5);
        orbsToken.mint(0x16A0cE1b17b7267e569CaA2ddd77140C93721Ab4, 1000000e18);

        console.log("mirakaiDnaParser", address(mirakaiDnaParser));
        console.log("mirakaiScrollsRenderer", address(mirakaiScrollsRenderer));
        console.log("orbsToken", address(orbsToken));
        console.log("mirakaiHeroesRenderer", address(mirakaiHeroesRenderer));
        console.log("mirakaiScrolls", address(mirakaiScrolls));
        console.log("mirakaiHeroes", address(mirakaiHeroes));
    }
}
