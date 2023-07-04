// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ISynth.sol";

interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);
}

/**
 * @notice ISynthAdapter implemenation. Should be used as synth for synthesis in case when
 * token synth already exists and our synth can not be used.
 */
contract XdaoSynthAdapter is ISynthAdapter, AccessControl {
    bytes32 public constant TOKEN_OWNER_ROLE = keccak256("TOKEN_OWNER_ROLE");
    bytes32 public constant SYNTHESIS_ROLE = keccak256("SYNTHESIS_ROLE");

    /// @dev original token address (from origin chain)
    address public originalToken;
    /// @dev origin chain id
    uint64 public chainIdFrom;
    /// @dev origin chain symbol
    string public chainSymbolFrom;
    /// @dev synth type (SynthType.ThirdPartySynth in this case)
    uint8 public synthType;
    /// @dev synth token address (in current chain)
    address public synthToken;
    /// @dev synthezation cap (controlled from synthesis)
    uint256 public cap;
    /// @dev original token decimals
    uint8 public decimals;

    constructor(
        address synthesis_,
        address originalToken_,
        address synthToken_,
        uint64 chainIdFrom_,
        string memory chainSymbolFrom_,
        uint8 decimals_
    ) {
        require(
            decimals_ == IERC20Extented(synthToken_).decimals(),
            "XdaoSynthAdapter: wrong decimals"
        );

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TOKEN_OWNER_ROLE, msg.sender);
        _grantRole(SYNTHESIS_ROLE, synthesis_);

        originalToken = originalToken_;
        synthToken = synthToken_;
        chainIdFrom = chainIdFrom_;
        chainSymbolFrom = chainSymbolFrom_;
        synthType = uint8(SynthType.ThirdPartySynth);
        decimals = decimals_;
        cap = 2 ** 256 - 1;
    }

    function setCap(uint256 cap_) external onlyRole(SYNTHESIS_ROLE) {
        cap = cap_;
        emit CapSet(cap);
    }

    function mint(
        address account,
        uint256 amount
    ) external onlyRole(SYNTHESIS_ROLE) {
        SafeERC20.safeTransfer(IERC20(synthToken), account, amount);
    }

    function burn(
        address account,
        uint256 amount
    ) external onlyRole(SYNTHESIS_ROLE) {
        SafeERC20.safeTransferFrom(
            IERC20(synthToken),
            account,
            address(this),
            amount
        );
    }

    function extract(uint256 amount) external onlyRole(TOKEN_OWNER_ROLE) {
        SafeERC20.safeTransfer(IERC20(synthToken), msg.sender, amount);
    }
}
