// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC20Permit} from "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import {EIP712} from "openzeppelin/utils/cryptography/EIP712.sol";
import {SignatureChecker} from "openzeppelin/utils/cryptography/SignatureChecker.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";
import {Address} from "openzeppelin/utils/Address.sol";

contract ReqCash is EIP712 {
    using Address for address payable;

    bytes32 private constant _REQUEST_TYPEHASH =
        keccak256("Request(uint256 requestId,uint256 value,address payee,string memo)");

    event Payment(
        uint256 indexed requestId,
        address token,
        uint256 value,
        address indexed payee,
        address indexed payer,
        string memo
    );

    event Request(
        uint256 indexed requestId,
        address token,
        uint256 value,
        address indexed payee,
        address indexed payer,
        string memo,
        bytes signature
    );

    constructor() EIP712("ReqCash", "1") {}

    // Pay Native token with a memo
    function pay(address payable payee, string calldata memo) public payable {
        emit Payment(0, address(0), msg.value, payee, msg.sender, memo);
        payee.sendValue(msg.value);
    }

    // Pay ERC-20 token with a memo (requires allowance)
    function pay(address token, uint256 value, address payee, string calldata memo) public {
        emit Payment(0, token, value, payee, msg.sender, memo);
        IERC20 erc20 = IERC20(token);
        erc20.transferFrom(msg.sender, payee, value);
    }

    // Pay ERC-20 token with a memo using permit
    function pay(address token, uint256 value, address payee, string calldata memo, bytes memory permit) public {
        require(permit.length == 65, "ReqCash: invalid permit");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        /// @solidity memory-safe-assembly
        assembly {
            r := mload(add(permit, 0x20))
            s := mload(add(permit, 0x40))
            v := byte(0, mload(add(permit, 0x60)))
        }

        emit Payment(0, token, value, payee, msg.sender, memo);

        // type(uint256).max is in effect no deadline. Should we allow the user/dev to limit this?
        IERC20Permit(token).permit(msg.sender, address(this), value, type(uint256).max, v, r, s);
        IERC20(token).transferFrom(msg.sender, payee, value);
    }

    // Pay a Native token request
    function pay(uint256 requestId, address payable payee, string calldata memo, bytes calldata signature)
        public
        payable
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(_REQUEST_TYPEHASH, requestId, msg.value, payee, keccak256(bytes(memo))))
        );

        require(SignatureChecker.isValidSignatureNow(payee, digest, signature), "ReqCash: invalid signature");

        emit Payment(requestId, address(0), msg.value, payee, msg.sender, memo);
        payee.sendValue(msg.value);
    }

    // Pay an ERC-20 token request
    function pay(
        uint256 requestId,
        address token,
        uint256 value,
        address payable requestor,
        string calldata memo,
        bytes calldata signature
    ) public payable {
        IERC20 erc20 = IERC20(token);
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("Request(uint256 requestId,address token,uint256 value,address requestor,string memo)"),
                    requestId,
                    token,
                    value,
                    requestor,
                    keccak256(bytes(memo))
                )
            )
        );

        require(SignatureChecker.isValidSignatureNow(requestor, digest, signature), "ReqCash: invalid signature");

        emit Payment(requestId, token, value, requestor, msg.sender, memo);
        erc20.transferFrom(msg.sender, requestor, value);
    }

    // Log a Request as an event on the blockchain
    function request(
        uint256 requestId,
        address token,
        uint256 value,
        address requestor,
        address payer,
        string calldata memo,
        bytes calldata signature
    ) public {
        emit Request(requestId, token, value, requestor, payer, memo, signature);
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }
}
