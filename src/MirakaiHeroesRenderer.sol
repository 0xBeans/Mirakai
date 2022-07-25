// ███╗░░░███╗██╗██████╗░░█████╗░██╗░░██╗░█████╗░██╗
// ████╗░████║██║██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██║
// ██╔████╔██║██║██████╔╝███████║█████═╝░███████║██║
// ██║╚██╔╝██║██║██╔══██╗██╔══██║██╔═██╗░██╔══██║██║
// ██║░╚═╝░██║██║██║░░██║██║░░██║██║░╚██╗██║░░██║██║
// ╚═╝░░░░░╚═╝╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝

///@author 0xBeans
///@dev This contract is a simple renderer that points to
/// our off-chain layering endpoint.

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MirakaiHeroesRenderer is Ownable {
    using Strings for uint256;

    string public baseTokenUri;

    constructor(string memory _baseTokenUri) {
        baseTokenUri = _baseTokenUri;
    }

    /*==============================================================
    ==                     Basic Renderering                      ==
    ==============================================================*/

    function setBaseTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    // we have dna as a param in the interface incase we want to do update our
    // renderer to use it (ie potential onchain layering)
    function tokenURI(uint256 _tokenId, uint256 dna)
        external
        view
        returns (string memory)
    {
        return string(abi.encodePacked(baseTokenUri, _tokenId.toString()));
    }
}
