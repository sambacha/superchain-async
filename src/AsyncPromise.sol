// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {console} from "forge-std/console.sol";

enum AsyncPromiseState {
    WAITING_FOR_SET_CALLBACK_SELECTOR,
    WAITING_FOR_CALLBACK_EXECUTION,
    RESOLVED
}

contract AsyncPromise {
    // The local contract which initiated the async call
    address public immutable localInvoker;
    address public immutable remoteTarget;
    bool public resolved = false;
    bytes4 public callbackSelector;
    bytes32 public messageId;
    AsyncPromiseState public state = AsyncPromiseState.WAITING_FOR_SET_CALLBACK_SELECTOR;

    error OnlyInvokerAllowed();
    error PromiseAlreadySetup();
    
    modifier onlyInvoker() {
        if (msg.sender != localInvoker) revert OnlyInvokerAllowed();
        _;
    }

    constructor(address _invoker, address _remoteTarget, bytes32 _messageId) {
        localInvoker = _invoker;
        remoteTarget = _remoteTarget;
        messageId = _messageId;
    }

    function markResolved() external onlyInvoker {
        _setResolved();
    }

    function _setResolved() internal {
        resolved = true;
        state = AsyncPromiseState.RESOLVED;
    }

    function _isWaitingForCallback() internal view returns (bool) {
        return state == AsyncPromiseState.WAITING_FOR_CALLBACK_EXECUTION;
    }

    function _isWaitingForSelector() internal view returns (bool) {
        return state == AsyncPromiseState.WAITING_FOR_SET_CALLBACK_SELECTOR;
    }

    function _setCallbackSelector(bytes calldata data) internal {
        callbackSelector = bytes4(data[24:28]);
        state = AsyncPromiseState.WAITING_FOR_CALLBACK_EXECUTION;
    }

    function _handleCallbackSetup(bytes calldata data) internal {
        if (_isWaitingForCallback()) {
            revert PromiseAlreadySetup();
        }
        
        if (_isWaitingForSelector()) {
            _setCallbackSelector(data);
        }
    }

    fallback() external onlyInvoker {
        _handleCallbackSetup(msg.data);
    }
}