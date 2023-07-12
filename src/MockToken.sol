// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/extensions/draft-ERC20Permit.sol";

contract MockToken is ERC20, Ownable, ERC20Permit {
    constructor() ERC20("MockToken", "MTK") ERC20Permit("MockToken") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
