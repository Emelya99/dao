// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AYEMToken is ERC20 {
    constructor() ERC20("AYEM", "AYEM") {
        uint256 supply = 64_000_000 * 10 ** uint256(decimals());
        _mint(msg.sender, supply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}
