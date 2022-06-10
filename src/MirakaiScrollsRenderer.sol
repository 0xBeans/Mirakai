// ███╗░░░███╗██╗██████╗░░█████╗░██╗░░██╗░█████╗░██╗
// ████╗░████║██║██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██║
// ██╔████╔██║██║██████╔╝███████║█████═╝░███████║██║
// ██║╚██╔╝██║██║██╔══██╗██╔══██║██╔═██╗░██╔══██║██║
// ██║░╚═╝░██║██║██║░░██║██║░░██║██║░╚██╗██║░░██║██║
// ╚═╝░░░░░╚═╝╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝
//
// This contains all logic needed for rendering on-chain scrolls and formatting
// metadata.
//
// This is essentially just constructing raw SVGs pixel by pixel and writing
// jsonify in solidity, kill me.
//
// Shout out Blitmap, Chain Runners, and Anonymice for this inspo/impl.

///@author BigBen and 0xBeans

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "sstore2/SSTORE2.sol";

import "./interfaces/IMirakaiDnaParser.sol";

// import {console} from "forge-std/console.sol";

contract MirakaiScrollsRenderer is Ownable {
    address public mirakaDnaParser;

    // storing scroll font in contract storage using sstore2 because
    // marketplaces dont allow 3rd party fonts to be loaded via url
    // kill  me
    mapping(uint256 => address) public font;

    // scroll pixel coordinates on a 24x24 grid
    string private pixelScroll =
        "000111111111111111110000001222222222222222221000001233333333333333321000000111111111111111110000000433333333333333340000000422222222222222340000000422222222222222340000000122222222222222340000000422222222222222340000000122222222222222340000000122222222222222340000000012222222222222340000000122222222222222340000000122222222222222310000000422222222222222340000000122222222222222310000000422222222222222100000000422222222222222310000000422222222222222310000000422222222222223340000000111111111111111110000001222222222222222221000001233333333333333321000000111111111111111110000";

    struct Cursor {
        uint8 x;
        uint8 y;
        string colorOne;
        string colorTwo;
        string colorThree;
        string colorFour;
    }

    uint256 public constant NUM_TRAITS = 10;

    uint256[][NUM_TRAITS] public WEIGHTS;
    string[][NUM_TRAITS] public TRAITS;
    string[NUM_TRAITS] public categories;

    constructor() {}

    /**
     * @dev essentially creating jsonify by constructing the metadata json + SVG image. Pain.
     */
    function tokenURI(uint256 tokenId, uint256 dna)
        external
        view
        returns (string memory)
    {
        uint256[NUM_TRAITS] memory traitIndexes = IMirakaiDnaParser(
            mirakaDnaParser
        ).getTraitIndexes(dna);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "Scroll',
                                toString(tokenId),
                                '", "description": "description x", "image": "data:image/svg+xml;base64,',
                                render(tokenId, dna),
                                '", "attributes":',
                                formatTraits(traitIndexes),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /*==============================================================
    ==                    Only Owner Functions                    ==
    ==============================================================*/

    // saving scroll font on-chain. pain.
    function saveFile(uint256 index, string calldata fileContent)
        public
        onlyOwner
    {
        font[index] = SSTORE2.write(bytes(fileContent));
    }

    function setmirakaiDnaParser(address _mirakaDnaParser) external onlyOwner {
        mirakaDnaParser = _mirakaDnaParser;
    }

    /*==============================================================
    ==             On-chain Rendering Functions. Pain             ==
    ==============================================================*/

    function pixelFour(string[24] memory lookup, Cursor memory cursor)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<rect class='c",
                    cursor.colorOne,
                    "' x='",
                    lookup[cursor.x],
                    "' y='",
                    lookup[cursor.y],
                    "' width='1' height='1' />",
                    "<rect class='c",
                    cursor.colorTwo,
                    "' x='",
                    lookup[cursor.x + 1],
                    "' y='",
                    lookup[cursor.y],
                    "' width='1' height='1' />",
                    string(
                        abi.encodePacked(
                            "<rect class='c",
                            cursor.colorThree,
                            "' x='",
                            lookup[cursor.x + 2],
                            "' y='",
                            lookup[cursor.y],
                            "' width='1' height='1' />",
                            "<rect class='c",
                            cursor.colorFour,
                            "' x='",
                            lookup[cursor.x + 3],
                            "' y='",
                            lookup[cursor.y],
                            "' width='1' height='1' />"
                        )
                    )
                )
            );
    }

    function setCursorColors(
        Cursor memory cursor,
        uint16 i,
        uint16 offset
    ) internal view {
        cursor.colorOne = substring(
            pixelScroll,
            4 * i + offset,
            (4 * i) + 1 + offset
        );
        cursor.colorTwo = substring(
            pixelScroll,
            4 * i + 1 + offset,
            (4 * i) + 2 + offset
        );
        cursor.colorThree = substring(
            pixelScroll,
            4 * i + 2 + offset,
            (4 * i) + 3 + offset
        );
        cursor.colorFour = substring(
            pixelScroll,
            4 * i + 3 + offset,
            (4 * i) + 4 + offset
        );
    }

    /**
     * @dev essentially creating jsonify by constructing the metadata json
     */
    function formatTraits(uint256[NUM_TRAITS] memory traitIndexes)
        internal
        view
        returns (string memory)
    {
        string memory attributes;
        string[NUM_TRAITS] memory traitNames = IMirakaiDnaParser(
            mirakaDnaParser
        ).getTraitNames(traitIndexes);

        for (uint256 i = 0; i < traitIndexes.length; i++) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    '{"trait_type":"',
                    IMirakaiDnaParser(mirakaDnaParser).categories(i),
                    '","value":"',
                    traitNames[i],
                    '"}'
                )
            );

            if (i != 9) attributes = string(abi.encodePacked(attributes, ","));
        }

        return string(abi.encodePacked("[", attributes, "]"));
    }

    /**
     * @dev construct scroll svg - all scrolls are essentially the same shape and bg
     */
    function drawScroll(string[24] memory lookup)
        internal
        view
        returns (string memory)
    {
        string memory svgScrollString;
        string[6] memory p;

        Cursor memory cursor;
        cursor.y = 0;

        for (uint16 i = 0; i < 144; i += 6) {
            cursor.x = 0;

            // 0-3
            setCursorColors(cursor, i, 0);
            p[0] = pixelFour(lookup, cursor); // 0 - 3
            cursor.x += 4;

            // 4-7
            setCursorColors(cursor, i, 4);
            p[1] = pixelFour(lookup, cursor); // 4 - 7
            cursor.x += 4;

            // 8-11
            setCursorColors(cursor, i, 8);
            p[2] = pixelFour(lookup, cursor); // 8 - 11
            cursor.x += 4;

            // 12-15
            setCursorColors(cursor, i, 12);
            p[3] = pixelFour(lookup, cursor); // 12 - 15
            cursor.x += 4;

            // 16-19
            setCursorColors(cursor, i, 16);
            p[4] = pixelFour(lookup, cursor); // 16 - 19
            cursor.x += 4;

            // 20-23
            setCursorColors(cursor, i, 20);
            p[5] = pixelFour(lookup, cursor); // 20 - 23

            svgScrollString = string(
                abi.encodePacked(
                    svgScrollString,
                    p[0],
                    p[1],
                    p[2],
                    p[3],
                    p[4],
                    p[5]
                )
            );

            cursor.y++;
        }
        return svgScrollString;
    }

    /**
     * @dev draw the actual traits onto the scroll
     */
    function drawItems(string[24] memory lookup, uint256 dna)
        internal
        view
        returns (string memory, uint256)
    {
        string memory extraTag;
        uint256 numRareTraits;

        uint256[NUM_TRAITS] memory traitIndexes = IMirakaiDnaParser(
            mirakaDnaParser
        ).getTraitIndexes(dna);

        string[NUM_TRAITS] memory traitNames = IMirakaiDnaParser(
            mirakaDnaParser
        ).getTraitNames(traitIndexes);

        uint256[NUM_TRAITS] memory traitWeights = IMirakaiDnaParser(
            mirakaDnaParser
        ).getTraitWeights(traitIndexes);

        string memory svgItemsScroll;
        for (uint8 i = 0; i < NUM_TRAITS; i++) {
            // clear tag
            extraTag = "";

            // traits with weight < 100 are deemed rare
            if (traitWeights[i] < 100) {
                extraTag = "fill='#87E8FC'";
                ++numRareTraits;
            }

            svgItemsScroll = string(
                abi.encodePacked(
                    svgItemsScroll,
                    "<text font-family='Silkscreen' class='t",
                    lookup[i],
                    "' ",
                    extraTag,
                    " x='5.5' y='",
                    lookup[7 + ((i % 5) * 2)],
                    "'>",
                    traitNames[i],
                    "</text>"
                )
            );
        }
        return (svgItemsScroll, numRareTraits);
    }

    /**
     * @dev combines scroll SVG + traits
     */
    function render(uint256 tokenId, uint256 dna)
        public
        view
        returns (string memory)
    {
        // 0. Init
        string[24] memory lookup = [
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "10",
            "11",
            "12",
            "13",
            "14",
            "15",
            "16",
            "17",
            "18",
            "19",
            "20",
            "21",
            "22",
            "23"
        ];

        string
            memory svgString = "<rect height='100%' width='100%' fill='#050A24' /><g class='floating'>";

        // 1. Draw the scroll.
        svgString = string(abi.encodePacked(svgString, drawScroll(lookup)));

        string memory drawnItems;
        uint256 rareItems;

        (drawnItems, rareItems) = drawItems(lookup, dna);

        // 2. Draw the letters.
        svgString = string(abi.encodePacked(svgString, drawnItems));
        svgString = string(abi.encodePacked(svgString, "</g>"));

        // 3. Draw the title.
        svgString = string(
            abi.encodePacked(
                svgString,
                "<text x='50%' y='33' dominant-baseline='middle' text-anchor='middle' class='title'>SCROLL #",
                toString(tokenId),
                "</text>"
            )
        );

        // extra style to for differing scroll glows depending on # rare items
        string memory extraStyle;

        if (rareItems >= 2) {
            extraStyle = "<style>@keyframes floating{from{transform: translate(6.5px,3.5px); filter: drop-shadow(0px 0px 1.25px rgba(120, 120, 180, .85));}50%{transform: translate(6.5px,5px); filter: drop-shadow(0px 0px 2.5px rgba(120, 120, 190, 1));}to{transform: translate(6.5px,3.5px); filter: drop-shadow(0px 0px 1.25px rgba(120, 120, 180,.85));}}</style>";
        }

        if (rareItems >= 3) {
            extraStyle = "<style>@keyframes floating{from{transform: translate(6.5px,3.5px); filter: drop-shadow(0px 0px 1.75px rgba(135,232,252,0.8));}50%{transform: translate(6.5px,5px); filter: drop-shadow(0px 0px 3.5px rgba(135,232,252,1));}to{transform: translate(6.5px,3.5px); filter: drop-shadow(0px 0px 1.75px rgba(135,232,252,0.8));}}</style>";
        }

        // 4. Close the SVG.
        svgString = string(
            abi.encodePacked(
                "<svg version='1.1' width='550' height='550' viewBox='0 0 36 36' xmlns='http://www.w3.org/2000/svg' shape-rendering='crispEdges'>",
                svgString,
                "<style>@font-face{font-family:Silkscreen;font-style:normal;src:url(",
                // read the font from contract storage
                string(SSTORE2.read(font[0])),
                ") format('truetype')}.title{font-family:Silkscreen;font-size:2px;fill:white}.floating{animation:floating 4s ease-in-out infinite alternate}@keyframes floating{from{transform:translate(6.5px,3.5px);filter:drop-shadow(0px 0px 1.25px rgba(239, 91, 91, .65))}50%{transform:translate(6.5px,5px);filter:drop-shadow(0px 0px 2.5px rgba(239, 91, 91, 1))}to{transform:translate(6.5px,3.5px);filter:drop-shadow(0px 0px 1.25px rgba(239, 91, 91, .65))}}.t0,.t1,.t2,.t3,.t4,.t5,.t6,.t7,.t8,.t9{font-family:Silkscreen;font-size:1.15px;color:#000;animation:textOneAnim 10.5s ease-in-out infinite forwards;opacity:0;animation-delay:.25s}.t5,.t6,.t7,.t8,.t9{animation-name:textTwoAnim}.t1{animation-delay:1.5s}.t2{animation-delay:2.5s}.t3{animation-delay:3.5s}.t4{animation-delay:4.5s}.t5{animation-delay:5.5s}.t6{animation-delay:6.5s}.t7{animation-delay:7.5s}.t8{animation-delay:8.5s}.t9{animation-delay:9.5s}@keyframes textOneAnim{from{opacity:0}10%{opacity:1}42.5%{opacity:1}50%{opacity:0}to{opacity:0}}@keyframes textTwoAnim{from{opacity:0}22.5%{opacity:1}30%{opacity:1}40%{opacity:1}50%{opacity:0}to{opacity:0}}.c0{fill:transparent}.c1{fill:#8b3615}.c2{fill:#d49443}.c3{fill:#c57032}.c4{fill:#76290c}</style>",
                extraStyle,
                "</svg>"
            )
        );

        return Base64.encode(bytes(svgString));
    }

    /*==============================================================
    ==              Utils - copied from other libs                ==
    ==============================================================*/

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
