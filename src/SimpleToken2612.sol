// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract SimpleToken2612 is ERC20Permit {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply
    )
        ERC20Permit(name_)
        ERC20(name_, symbol_)
    {
        _mint(msg.sender, initialSupply);
    }
}
