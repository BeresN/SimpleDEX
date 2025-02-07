// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("BersensToken", "BTKN") {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }
}
