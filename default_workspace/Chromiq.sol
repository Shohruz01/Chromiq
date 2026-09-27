// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@4.9.6/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.9.6/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.6/utils/Base64.sol";
import "@openzeppelin/contracts@4.9.6/utils/Strings.sol";

contract Chromiq is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public mintPrice = 0.001 ether;
    uint256 public totalMinted;
    bool public mintOpen;

    struct Traits {
        uint8 bg;
        uint8 body;
        uint8 eyes;
        uint8 mouth;
        uint8 hat;
        uint8 pattern;
        uint8 accent;
    }

    constructor() ERC721("Chromiq", "CHRQ") {}

    // =============================================================
    // MINT
    // =============================================================

    function mint(uint256 quantity) external payable {
        require(mintOpen, "Mint is closed");
        require(quantity > 0, "Quantity is zero");
        require(
            totalMinted + quantity <= MAX_SUPPLY,
            "Max supply reached"
        );
        require(
            msg.value >= mintPrice * quantity,
            "Insufficient ETH"
        );

        for (uint256 i = 0; i < quantity; i++) {
            totalMinted++;
            _safeMint(msg.sender, totalMinted);
        }
    }

    function ownerMint(
        address to,
        uint256 quantity
    ) external onlyOwner {
        require(to != address(0), "Zero address");
        require(quantity > 0, "Quantity is zero");
        require(
            totalMinted + quantity <= MAX_SUPPLY,
            "Max supply reached"
        );

        for (uint256 i = 0; i < quantity; i++) {
            totalMinted++;
            _safeMint(to, totalMinted);
        }
    }

    // =============================================================
    // OWNER
    // =============================================================

    function setMintOpen(bool open) external onlyOwner {
        mintOpen = open;
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        (bool success, ) = payable(owner()).call{
            value: balance
        }("");

        require(success, "Withdraw failed");
    }

    receive() external payable {}

    // =============================================================
    // TOKEN URI
    // =============================================================

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return _createTokenURI(tokenId);
    }

    function previewTokenURI(
        uint256 tokenId
    ) external pure returns (string memory) {
        require(
            tokenId >= 1 && tokenId <= MAX_SUPPLY,
            "Invalid token ID"
        );

        return _createTokenURI(tokenId);
    }

    // =============================================================
    // METADATA
    // =============================================================

    function _createTokenURI(
        uint256 tokenId
    ) internal pure returns (string memory) {
        Traits memory t = _getTraits(tokenId);

        string memory image = _imageURI(t, tokenId);

        string memory json = string(
            abi.encodePacked(
                "{",
                '"name":"Chromiq #',
                tokenId.toString(),
                '",',
                '"description":"Chromiq is a 10,000-piece fully on-chain animated generative NFT collection. Every artwork and metadata is generated directly by the smart contract.",',
                '"image":"',
                image,
                '",',
                '"attributes":[',
                _attributes(t),
                "]",
                "}"
            )
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            )
        );
    }

    // =============================================================
    // TRAITS
    // =============================================================

    function _getTraits(
        uint256 tokenId
    ) internal pure returns (Traits memory t) {
        bytes32 seed = keccak256(
            abi.encodePacked("CHROMIQ-ANIMATED-V3", tokenId)
        );

        t.bg = uint8(uint256(seed) % 8);
        t.body = uint8(uint256(seed >> 8) % 10);
        t.eyes = uint8(uint256(seed >> 16) % 8);
        t.mouth = uint8(uint256(seed >> 24) % 8);
        t.hat = uint8(uint256(seed >> 32) % 8);
        t.pattern = uint8(uint256(seed >> 40) % 8);
        t.accent = uint8(uint256(seed >> 48) % 10);
    }

    // =============================================================
    // IMAGE
    // =============================================================

    function _imageURI(
        Traits memory t,
        uint256 tokenId
    ) internal pure returns (string memory) {
        string memory svg = _svg(t, tokenId);

        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(svg))
            )
        );
    }

    // =============================================================
    // SVG
    // =============================================================

    function _svg(
        Traits memory t,
        uint256 tokenId
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" ',
                'viewBox="0 0 1000 1000">',
                
                "<defs>",

                // Body floating animation
                '<animateTransform id="float" attributeName="transform" ',
                'type="translate" values="0 0;0 -10;0 0" ',
                'dur="3.2s" repeatCount="indefinite"/>',

                // Pattern animation
                '<style>',
                '.move{animation:move 8s linear infinite;}',
                '.pulse{animation:pulse 2.5s ease-in-out infinite;}',
                '.blink{animation:blink 4s infinite;}',
                '@keyframes move{from{transform:translateX(0)}to{transform:translateX(80px)}}',
                '@keyframes pulse{0%,100%{opacity:.45}50%{opacity:1}}',
                '@keyframes blink{0%,45%,55%,100%{transform:scaleY(1)}50%{transform:scaleY(.08)}}',
                '</style>',

                "</defs>",

                // Background
                '<rect width="1000" height="1000" fill="',
                _backgroundColor(t.bg),
                '"/>',

                // Decorative animated circles
                '<g class="pulse" opacity=".5">',
                '<circle cx="120" cy="150" r="42" fill="',
                _accentColor(t.accent),
                '"/>',
                '<circle cx="860" cy="180" r="28" fill="',
                _accentColor(t.accent),
                '"/>',
                '<circle cx="820" cy="800" r="55" fill="',
                _accentColor(t.accent),
                '"/>',
                "</g>",

                // Moving pattern
                '<g class="move" opacity=".18">',
                _patternSVG(t.pattern, t.accent),
                "</g>",

                // Main character
                '<g transform="translate(0 0)">',

                '<animateTransform ',
                'attributeName="transform" ',
                'type="translate" ',
                'values="0 0;0 -8;0 0;0 6;0 0" ',
                'dur="4s" ',
                'repeatCount="indefinite"/>',

                // Shadow
                '<ellipse cx="500" cy="820" rx="260" ry="45" ',
                'fill="#000000" opacity=".12"/>',

                // Body
                _bodySVG(t.body),

                // Pattern on body
                _bodyPattern(t.pattern, t.accent),

                // Eyes
                _eyesSVG(t.eyes),

                // Mouth
                _mouthSVG(t.mouth),

                // Hat
                _hatSVG(t.hat, t.accent),

                // Accent
                '<circle class="pulse" cx="735" cy="470" r="28" fill="',
                _accentColor(t.accent),
                '"/>',

                "</g>",

                // Frame
                '<rect x="28" y="28" width="944" height="944" rx="55" ',
                'fill="none" stroke="#111111" stroke-width="12"/>',

                // Collection name
                '<text x="500" y="925" text-anchor="middle" ',
                'font-family="Arial,sans-serif" font-size="34" ',
                'font-weight="700" fill="#111111">',
                "CHROMIQ #",
                tokenId.toString(),
                "</text>",

                "</svg>"
            )
        );
    }

    // =============================================================
    // BODY
    // =============================================================

    function _bodySVG(
        uint8 id
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<path d="M245 610 ',
                'C245 470 350 360 500 360 ',
                'C650 360 755 470 755 610 ',
                'C755 735 650 800 500 800 ',
                'C350 800 245 735 245 610Z" ',
                'fill="',
                _bodyColor(id),
                '" stroke="#111" stroke-width="14"/>'
            )
        );
    }

    // =============================================================
    // EYES
    // =============================================================

    function _eyesSVG(
        uint8 id
    ) internal pure returns (string memory) {
        if (id == 0) {
            return string(
                abi.encodePacked(
                    '<g class="blink">',
                    '<ellipse cx="410" cy="540" rx="30" ry="42" fill="#111"/>',
                    '<ellipse cx="590" cy="540" rx="30" ry="42" fill="#111"/>',
                    "</g>"
                )
            );
        }

        if (id == 1) {
            return string(
                abi.encodePacked(
                    '<g class="blink">',
                    '<circle cx="410" cy="540" r="38" fill="#111"/>',
                    '<circle cx="590" cy="540" r="38" fill="#111"/>',
                    '<circle cx="398" cy="525" r="10" fill="#fff"/>',
                    '<circle cx="578" cy="525" r="10" fill="#fff"/>',
                    "</g>"
                )
            );
        }

        if (id == 2) {
            return string(
                abi.encodePacked(
                    '<g class="blink">',
                    '<rect x="375" y="510" width="70" height="60" rx="15" fill="#111"/>',
                    '<rect x="555" y="510" width="70" height="60" rx="15" fill="#111"/>',
                    "</g>"
                )
            );
        }

        if (id == 3) {
            return string(
                abi.encodePacked(
                    '<path d="M375 545 Q410 505 445 545" ',
                    'fill="none" stroke="#111" stroke-width="16" ',
                    'stroke-linecap="round"/>',
                    '<path d="M555 545 Q590 505 625 545" ',
                    'fill="none" stroke="#111" stroke-width="16" ',
                    'stroke-linecap="round"/>'
                )
            );
        }

        if (id == 4) {
            return string(
                abi.encodePacked(
                    '<g class="blink">',
                    '<circle cx="410" cy="540" r="34" fill="#7C3AED"/>',
                    '<circle cx="590" cy="540" r="34" fill="#7C3AED"/>',
                    "</g>"
                )
            );
        }

        if (id == 5) {
            return string(
                abi.encodePacked(
                    '<path d="M380 515 L440 575 M440 515 L380 575" ',
                    'stroke="#111" stroke-width="18" stroke-linecap="round"/>',
                    '<path d="M560 515 L620 575 M620 515 L560 575" ',
                    'stroke="#111" stroke-width="18" stroke-linecap="round"/>'
                )
            );
        }

        if (id == 6) {
            return string(
                abi.encodePacked(
                    '<g class="blink">',
                    '<ellipse cx="410" cy="540" rx="42" ry="28" fill="#111"/>',
                    '<ellipse cx="590" cy="540" rx="42" ry="28" fill="#111"/>',
                    "</g>"
                )
            );
        }

        return string(
            abi.encodePacked(
                '<g class="blink">',
                '<circle cx="410" cy="540" r="35" fill="#222"/>',
                '<circle cx="590" cy="540" r="35" fill="#222"/>',
                '<circle cx="400" cy="528" r="9" fill="#fff"/>',
                '<circle cx="580" cy="528" r="9" fill="#fff"/>',
                "</g>"
            )
        );
    }

    // =============================================================
    // MOUTH
    // =============================================================

    function _mouthSVG(
        uint8 id
    ) internal pure returns (string memory) {
        if (id == 0) {
            return '<path d="M420 640 Q500 710 580 640" fill="none" stroke="#111" stroke-width="18" stroke-linecap="round"/>';
        }

        if (id == 1) {
            return '<path d="M420 675 Q500 615 580 675" fill="none" stroke="#111" stroke-width="18" stroke-linecap="round"/>';
        }

        if (id == 2) {
            return '<ellipse cx="500" cy="660" rx="55" ry="42" fill="#111"/>';
        }

        if (id == 3) {
            return '<path d="M445 650 Q500 705 555 650 L555 680 Q500 720 445 680Z" fill="#fff" stroke="#111" stroke-width="8"/>';
        }

        if (id == 4) {
            return '<circle cx="500" cy="665" r="20" fill="#111"/>';
        }

        if (id == 5) {
            return '<path d="M445 665 L555 665" stroke="#111" stroke-width="18" stroke-linecap="round"/>';
        }

        if (id == 6) {
            return '<path d="M445 655 Q500 690 555 655" fill="none" stroke="#111" stroke-width="14" stroke-linecap="round"/>';
        }

        return '<path d="M440 650 Q500 680 560 650" fill="none" stroke="#111" stroke-width="12" stroke-linecap="round"/>';
    }

    // =============================================================
    // HAT
    // =============================================================

    function _hatSVG(
        uint8 id,
        uint8 accent
    ) internal pure returns (string memory) {
        if (id == 0) {
            return "";
        }

        if (id == 1) {
            return string(
                abi.encodePacked(
                    '<path d="M380 390 L410 285 L455 335 ',
                    'L500 260 L545 335 L590 285 L620 390Z" ',
                    'fill="',
                    _accentColor(accent),
                    '" stroke="#111" stroke-width="14"/>'
                )
            );
        }

        if (id == 2) {
            return string(
                abi.encodePacked(
                    '<path d="M350 410 Q500 330 650 410 ',
                    'L630 455 L370 455Z" fill="',
                    _accentColor(accent),
                    '" stroke="#111" stroke-width="14"/>'
                )
            );
        }

        if (id == 3) {
            return string(
                abi.encodePacked(
                    '<circle cx="500" cy="325" r="70" fill="none" ',
                    'stroke="',
                    _accentColor(accent),
                    '" stroke-width="18"/>'
                )
            );
        }

        if (id == 4) {
            return string(
                abi.encodePacked(
                    '<path d="M410 390 Q430 285 500 250 ',
                    'Q570 285 590 390Z" fill="#7C3AED" ',
                    'stroke="#111" stroke-width="14"/>'
                )
            );
        }

        if (id == 5) {
            return string(
                abi.encodePacked(
                    '<circle cx="500" cy="315" r="55" fill="',
                    _accentColor(accent),
                    '" stroke="#111" stroke-width="12"/>',
                    '<circle cx="500" cy="315" r="20" fill="#fff"/>'
                )
            );
        }

        if (id == 6) {
            return string(
                abi.encodePacked(
                    '<path d="M500 230 L555 350 L500 385 ',
                    'L445 350Z" fill="',
                    _accentColor(accent),
                    '" stroke="#111" stroke-width="14"/>'
                )
            );
        }

        return string(
            abi.encodePacked(
                '<path d="M360 390 Q430 330 500 390 ',
                'Q570 450 640 390" fill="none" ',
                'stroke="',
                _accentColor(accent),
                '" stroke-width="28" stroke-linecap="round"/>'
            )
        );
    }

    // =============================================================
    // PATTERN
    // =============================================================

    function _patternSVG(
        uint8 id,
        uint8 accent
    ) internal pure returns (string memory) {
        string memory c = _accentColor(accent);

        if (id == 0) {
            return string(
                abi.encodePacked(
                    '<circle cx="150" cy="250" r="35" fill="',
                    c,
                    '"/>',
                    '<circle cx="300" cy="500" r="55" fill="',
                    c,
                    '"/>',
                    '<circle cx="750" cy="300" r="45" fill="',
                    c,
                    '"/>',
                    '<circle cx="900" cy="600" r="60" fill="',
                    c,
                    '"/>'
                )
            );
        }

        if (id == 1) {
            return string(
                abi.encodePacked(
                    '<path d="M0 300 Q100 200 200 300 T400 300 ',
                    'T600 300 T800 300 T1000 300" fill="none" ',
                    'stroke="',
                    c,
                    '" stroke-width="40"/>'
                )
            );
        }

        if (id == 2) {
            return string(
                abi.encodePacked(
                    '<path d="M0 0 L180 180 M180 0 L360 180 ',
                    'M360 0 L540 180 M540 0 L720 180 ',
                    'M720 0 L900 180" stroke="',
                    c,
                    '" stroke-width="45"/>'
                )
            );
        }

        if (id == 3) {
            return string(
                abi.encodePacked(
                    '<rect x="120" y="120" width="760" height="760" ',
                    'rx="100" fill="none" stroke="',
                    c,
                    '" stroke-width="35"/>'
                )
            );
        }

        if (id == 4) {
            return string(
                abi.encodePacked(
                    '<circle cx="500" cy="500" r="170" fill="none" ',
                    'stroke="',
                    c,
                    '" stroke-width="35"/>',
                    '<circle cx="500" cy="500" r="260" fill="none" ',
                    'stroke="',
                    c,
                    '" stroke-width="25"/>'
                )
            );
        }

        if (id == 5) {
            return string(
                abi.encodePacked(
                    '<path d="M100 700 Q300 300 500 700 ',
                    'T900 700" fill="none" stroke="',
                    c,
                    '" stroke-width="40"/>'
                )
            );
        }

        if (id == 6) {
            return string(
                abi.encodePacked(
                    '<path d="M500 120 L580 300 L780 330 ',
                    'L620 470 L670 670 L500 570 L330 670 ',
                    'L380 470 L220 330 L420 300Z" fill="none" ',
                    'stroke="',
                    c,
                    '" stroke-width="28"/>'
                )
            );
        }

        return string(
            abi.encodePacked(
                '<circle cx="180" cy="180" r="18" fill="',
                c,
                '"/>',
                '<circle cx="350" cy="250" r="25" fill="',
                c,
                '"/>',
                '<circle cx="700" cy="180" r="20" fill="',
                c,
                '"/>',
                '<circle cx="850" cy="350" r="30" fill="',
                c,
                '"/>',
                '<circle cx="200" cy="700" r="25" fill="',
                c,
                '"/>',
                '<circle cx="800" cy="720" r="22" fill="',
                c,
                '"/>'
            )
        );
    }

    function _bodyPattern(
        uint8 pattern,
        uint8 accent
    ) internal pure returns (string memory) {
        if (pattern == 0) {
            return string(
                abi.encodePacked(
                    '<g opacity=".25" fill="',
                    _accentColor(accent),
                    '">',
                    '<circle cx="330" cy="620" r="25"/>',
                    '<circle cx="670" cy="620" r="25"/>',
                    '<circle cx="380" cy="700" r="18"/>',
                    '<circle cx="620" cy="700" r="18"/>',
                    "</g>"
                )
            );
        }

        if (pattern == 1) {
            return string(
                abi.encodePacked(
                    '<path d="M300 600 Q500 500 700 600 ',
                    'M300 680 Q500 580 700 680" ',
                    'fill="none" stroke="',
                    _accentColor(accent),
                    '" stroke-width="20" opacity=".3"/>'
                )
            );
        }

        return "";
    }

    // =============================================================
    // COLORS
    // =============================================================

    function _backgroundColor(
        uint8 id
    ) internal pure returns (string memory) {
        if (id == 0) return "#FFF4D6";
        if (id == 1) return "#D9F7E8";
        if (id == 2) return "#DDF3FF";
        if (id == 3) return "#FFE0E8";
        if (id == 4) return "#E9DDFF";
        if (id == 5) return "#FFE8A3";
        if (id == 6) return "#D5FAF4";
        return "#D9F0D0";
    }

    function _bodyColor(
        uint8 id
    ) internal pure returns (string memory) {
        if (id == 0) return "#FF6F61";
        if (id == 1) return "#20B2AA";
        if (id == 2) return "#4A90E2";
        if (id == 3) return "#8FB996";
        if (id == 4) return "#FFD93D";
        if (id == 5) return "#FFB38A";
        if (id == 6) return "#9B59B6";
        if (id == 7) return "#FF7EB6";
        if (id == 8) return "#30D5C8";
        return "#FFF176";
    }

    function _accentColor(
        uint8 id
    ) internal pure returns (string memory) {
        if (id == 0) return "#FF6F61";
        if (id == 1) return "#20B2AA";
        if (id == 2) return "#4A90E2";
        if (id == 3) return "#7C3AED";
        if (id == 4) return "#FF4F9A";
        if (id == 5) return "#00B8A9";
        if (id == 6) return "#F5B700";
        if (id == 7) return "#FFE135";
        if (id == 8) return "#FFFFFF";
        return "#111111";
    }

    // =============================================================
    // ATTRIBUTES
    // =============================================================

    function _attributes(
        Traits memory t
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{"trait_type":"Background","value":"',
                _backgroundName(t.bg),
                '"},',
                '{"trait_type":"Body","value":"',
                _bodyName(t.body),
                '"},',
                '{"trait_type":"Eyes","value":"',
                _eyesName(t.eyes),
                '"},',
                '{"trait_type":"Mouth","value":"',
                _mouthName(t.mouth),
                '"},',
                '{"trait_type":"Hat","value":"',
                _hatName(t.hat),
                '"},',
                '{"trait_type":"Pattern","value":"',
                _patternName(t.pattern),
                '"},',
                '{"trait_type":"Accent","value":"',
                _accentName(t.accent),
                '"},',
                '{"trait_type":"Animated","value":"Yes"}'
            )
        );
    }

    // =============================================================
    // TRAIT NAMES
    // =============================================================

    function _backgroundName(
        uint8 id
    ) internal pure returns (string memory) {
        if (id == 0) return "Cream";
        if (id == 1) return "Mint";
        if (id == 2) return "Sky";
        if (id == 3) return "Rose";
        if (id == 4) return "Lavender";
        if (id == 5) return "Gold";
        if (id == 6) return "Aqua";
        return "Forest";
    }

    function _bodyName(
        uint8 id
    ) internal pure returns (string memory) {
        if (id == 0) return "Coral";
        if (id == 1) return "Teal";
        if (id == 2) return "Blue";
        if (id == 3) return "Sage";
        if (id == 4) return "Yellow";
        if (id == 5) return "Peach";
        if (id == 6) return "Purple";
        if (id == 7) return "Pink";
        if (id == 8) return "Turquoise";
        return "Lemon";
    }

    function _eyesName(
        uint8 id
    ) internal pure returns (string memory) {
        if (id == 0) return "Classic";
        if (id == 1) return "Bold";
        if (id == 2) return "Block";
        if (id == 3) return "Happy";
        if (id == 4) return "Purple";
        if (id == 5) return "Cross";
        if (id == 6) return "Oval";
        return "Dark";
    }

    function _mouthName(
        uint8 id
    ) internal pure returns (string memory) {
        if (id == 0) return "Smile";
        if (id == 1) return "Reverse";
        if (id == 2) return "Open";
        if (id == 3) return "Teeth";
        if (id == 4) return "Dot";
        if (id == 5) return "Line";
        if (id == 6) return "Soft";
        return "Curve";
    }

    function _hatName(
        uint8 id
    ) internal pure returns (string memory) {
        if (id == 0) return "None";
        if (id == 1) return "Crown";
        if (id == 2) return "Cap";
        if (id == 3) return "Halo";
        if (id == 4) return "Purple Hat";
        if (id == 5) return "Flower";
        if (id == 6) return "Crystal";
        return "Wave";
    }

    function _patternName(
        uint8 id
    ) internal pure returns (string memory) {
        if (id == 0) return "Bubbles";
        if (id == 1) return "Waves";
        if (id == 2) return "Diagonal";
        if (id == 3) return "Frame";
        if (id == 4) return "Rings";
        if (id == 5) return "Flow";
        if (id == 6) return "Triangle";
        return "Dots";
    }

    function _accentName(
        uint8 id
    ) internal pure returns (string memory) {
        if (id == 0) return "Coral";
        if (id == 1) return "Teal";
        if (id == 2) return "Blue";
        if (id == 3) return "Purple";
        if (id == 4) return "Pink";
        if (id == 5) return "Turquoise";
        if (id == 6) return "Gold";
        if (id == 7) return "Lemon";
        if (id == 8) return "White";
        return "Black";
    }
}