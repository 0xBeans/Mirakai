//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMirakaiDnaParser {
    function splitDna(uint256 dna) external pure returns (uint256[10] memory);

    function getTraitIndexes(uint256 dna)
        external
        view
        returns (uint256[10] memory);

    function getTraitName(uint256 categoryIndex, uint256 traitIndex)
        external
        view
        returns (string memory);

    function getTraitNames(uint256[10] memory traitIndexes)
        external
        view
        returns (string[10] memory);

    function getTraitWeights(uint256[10] memory traitIndexes)
        external
        view
        returns (uint256[10] memory);

    function cc0Traits(uint256 scrollDna) external pure returns (uint256);

    function getCategory(uint8 index) external pure returns (string memory);
}
