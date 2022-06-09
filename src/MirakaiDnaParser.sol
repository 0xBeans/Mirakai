// ███╗░░░███╗██╗██████╗░░█████╗░██╗░░██╗░█████╗░██╗
// ████╗░████║██║██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██║
// ██╔████╔██║██║██████╔╝███████║█████═╝░███████║██║
// ██║╚██╔╝██║██║██╔══██╗██╔══██║██╔═██╗░██╔══██║██║
// ██║░╚═╝░██║██║██║░░██║██║░░██║██║░╚██╗██║░░██║██║
// ╚═╝░░░░░╚═╝╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝
//
// This is the main contract that parses scroll/hero DNA into traits.
// We define weights which is a 2D array that looks something like this:
// weights = [
//     [100, 200, 400, 100, ...], -> clan trait category
//     [500, 100, 410, 100, ...], -> head trait category
//     [290, 400, 400, 100, ...], -> eyes trait category
//     [150, 300, 400, 100, ...], -> mouth trait category
//     etc
// ]
//
// Each sub-array is a trait category where the indexes represent the probability for each trait.
// Each sub-array sums to 10k.
//
// For example, in the clan trait category, index 0 is the first clan trait (clan 1)
// and the probability to roll it is 100 / 10k .
//
// How DNA is parsed:
// DNA is 256 random bits. We take the first 14 bits (size of a trait 'slot') and mod 10 to get an integer k < 10k.
// k determines the trait index in the first trait category (clan). We step through the sub-array and sum
// up the numbers until we reach an sum(0 to index) > k.
//
// For example, if k = 600, we step through the array summing each index (100 + 200 + 400) until
// we get to an index where sum(indexes) > 600 - which would be index 2. So our clan trait is
// index 2 (clan 2).
//
// We proceed to do this for every trait we have by shifting 14 bits at a time.
//
// More thorough explanation can be found at
// https://mirror.xyz/0x88a0371fc2BefDfC6F675F9293DE32ef79D6f6c7/6BT2CYyZjqKJ2FKIohLt9cNb_TYJHjFBn_0sTKU5vOc
//
// Shoutouts to chain runners for this inspo.

///@author 0xBeans
///@dev This contract contains all functions needed to parse DNA, retrieve traits/weights.

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console} from "forge-std/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract MirakaiDnaParser is Ownable {
    // this is 14 bits of 1s - the size of a trait 'slot' in the dna
    uint256 public constant BIT_MASK = 2**14 - 1;
    uint256 public constant NUM_TRAITS = 10;

    uint256[][NUM_TRAITS] public weights;
    string[][NUM_TRAITS] public traits;
    string[NUM_TRAITS] public categories;

    // used to initialize weights and traits
    struct TraitWeights {
        uint256 index;
        string[] traitNames;
        uint256[] traitWeights;
    }

    constructor() {
        categories = [
            "clan",
            "genus",
            "head",
            "eyes",
            "mouth",
            "upper",
            "lower",
            "weapon",
            "markings",
            "cc0s"
        ];
    }

    /*==============================================================
    ==                 Initializing Traits/Weights                ==
    ==============================================================*/

    function setTraitsAndWeights(TraitWeights[] calldata input)
        external
        onlyOwner
    {
        unchecked {
            for (uint256 i = 0; i < input.length; ++i) {
                // clear our previous traits and weights if set
                delete traits[input[i].index];
                delete weights[input[i].index];

                for (uint256 j = 0; j < input[i].traitNames.length; ++j) {
                    traits[input[i].index].push(input[i].traitNames[j]);
                    weights[input[i].index].push(input[i].traitWeights[j]);
                }
            }
        }
    }

    /*==============================================================
    ==                        DNA Parsing                         ==
    ==============================================================*/

    /**
     * @dev splits dna into its 14 bit trait slots, then mods it to get a number < 10k
     */
    function splitDna(uint256 dna)
        public
        pure
        returns (uint256[NUM_TRAITS] memory traitDnas)
    {
        unchecked {
            for (uint256 i = 0; i < NUM_TRAITS; ++i) {
                traitDnas[i] = (dna & BIT_MASK) % 10000;
                dna >>= 14;
            }
        }
    }

    /**
     * @dev returns cc0 trait (0 means no cc0 trait)
     */
    function cc0Traits(uint256 scrollDna) public pure returns (uint256) {
        return ((scrollDna >> (14 * 10)) & BIT_MASK) % 10;
    }

    /**
     * @dev returns the trait index given the trait slot (the number < 10k)
     */
    function getTraitIndex(uint256 traitDna, uint256 index)
        public
        view
        returns (uint256)
    {
        uint256 lowerBound;
        uint256 percentage;
        for (uint8 i; i < weights[index].length; i++) {
            percentage = weights[index][i];
            if (traitDna >= lowerBound && traitDna < lowerBound + percentage) {
                return i;
            }
            unchecked {
                lowerBound += percentage;
            }
        }
        // If not found, return index higher than available layers.  Will get filtered out.
        return weights[index].length;
    }

    /**
     * @dev given dna, split it into its slots and return the indexes in the weights array
     */
    function getTraitIndexes(uint256 dna)
        external
        view
        returns (uint256[NUM_TRAITS] memory traitIndexes)
    {
        uint256[NUM_TRAITS] memory traitDnas = splitDna(dna);

        for (uint256 i = 0; i < NUM_TRAITS - 1; i++) {
            uint256 traitIndex = getTraitIndex(traitDnas[i], i);
            traitIndexes[i] = traitIndex;
        }

        // cc0 trait has different logic
        traitIndexes[NUM_TRAITS - 1] = cc0Traits(dna);
    }

    /**
     * @dev return an array of trait weights given an array of trait indexes
     */
    function getTraitWeights(uint256[NUM_TRAITS] memory traitIndexes)
        external
        view
        returns (uint256[NUM_TRAITS] memory traitWeights)
    {
        for (uint8 i = 0; i < NUM_TRAITS; i++) {
            traitWeights[i] = weights[i][traitIndexes[i]];
        }
    }

    /**
     * @dev return the trait name string given the trait index
     */
    function getTraitName(uint256 categoryIndex, uint256 traitIndex)
        external
        view
        returns (string memory)
    {
        return traits[categoryIndex][traitIndex];
    }

    /**
     * @dev return an array of trait name strings given an array of trait indexes
     */
    function getTraitNames(uint256[NUM_TRAITS] memory traitIndexes)
        external
        view
        returns (string[NUM_TRAITS] memory traitNames)
    {
        for (uint8 i = 0; i < NUM_TRAITS; i++) {
            traitNames[i] = traits[i][traitIndexes[i]];
        }
    }
}
