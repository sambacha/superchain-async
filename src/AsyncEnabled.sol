// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AsyncUtils} from "./AsyncUtils.sol";
import {console} from "forge-std/console.sol";
import {LocalAsyncProxy} from "./LocalAsyncProxy.sol";
import {AsyncCall, AsyncCallback} from "./AsyncUtils.sol";
import {SuperchainEnabled} from "./SuperchainEnabled.sol";
import {AsyncPromise} from "./AsyncPromise.sol";
import {IL2ToL2CrossDomainMessenger} from "@contracts-bedrock/L2/interfaces/IL2ToL2CrossDomainMessenger.sol";
import {Predeploys} from "@contracts-bedrock/libraries/Predeploys.sol";

contract AsyncEnabled is SuperchainEnabled {
    mapping(address => mapping(uint256 => LocalAsyncProxy)) public remoteAsyncProxies;

    constructor() {
        console.log("an asyncEnabled contract was just deployed!");
    }

    function getAsyncProxy(address _remoteAddress, uint256 _remoteChainId) internal returns (address) {
        if (isProxyNotCreated(_remoteAddress, _remoteChainId)) {
            createLocalAsyncProxy(_remoteAddress, _remoteChainId);
        }
        return address(remoteAsyncProxies[_remoteAddress][_remoteChainId]);
    }

    function isProxyNotCreated(address _remoteAddress, uint256 _remoteChainId) internal view returns (bool) {
        return address(remoteAsyncProxies[_remoteAddress][_remoteChainId]) == address(0);
    }

    function createLocalAsyncProxy(address _remoteAddress, uint256 _remoteChainId) internal {
        remoteAsyncProxies[_remoteAddress][_remoteChainId] = new LocalAsyncProxy{salt: bytes32(0)}(_remoteAddress, _remoteChainId);
    }

    function relayAsyncCall(AsyncCall calldata _asyncCall) external {
        require(isValidCrossDomainSender(_asyncCall), "Invalid cross-domain sender");
        console.log("valid CDM, relaying async call");

        (bool success, bytes memory returndata) = executeAsyncCall(_asyncCall);

        console.log("AsyncCallRelayer relayed, success: %s, returndata: ", success);
        console.logBytes(returndata);

        require(success, "Relaying async call failed");

        relayCallback(_asyncCall, success, returndata);
    }

    function isValidCrossDomainSender(AsyncCall calldata _asyncCall) internal view returns (bool) {
        LocalAsyncProxy expectedCrossDomainSender = AsyncUtils.calculateLocalAsyncProxyAddress(
            _asyncCall.from.addr,
            address(this),
            block.chainid
        );
        return _isValidCrossDomainSender(address(expectedCrossDomainSender));
    }

    function executeAsyncCall(AsyncCall calldata _asyncCall) internal returns (bool, bytes memory) {
        return address(this).call(_asyncCall.data);
    }

    function relayCallback(AsyncCall calldata _asyncCall, bool success, bytes memory returndata) internal {
        bytes32 asyncCallId = AsyncUtils.getAsyncCallId(_asyncCall);
        AsyncCallback memory callback = AsyncCallback({
            asyncCallId: asyncCallId,
            success: success,
            returnData: returndata
        });

        bytes memory relayCallbackPayload = abi.encodeWithSelector(
            this.relayAsyncCallback.selector,
            callback
        );

        _xMessageContract(
            _asyncCall.from.chainId,
            _asyncCall.from.addr,
            relayCallbackPayload
        );
    }

    function relayAsyncCallback(AsyncCallback calldata _callback) external {
        console.log("in relayAsyncCallback");

        require(isValidPromiseCallbackSender(_callback), "Invalid promise callback sender");

        executeCallback(_callback);
    }

    function isValidPromiseCallbackSender(AsyncCallback calldata _callback) internal view returns (bool) {
        address crossDomainCallbackSender = IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER).crossDomainMessageSender();
        uint256 crossDomainCallbackSource = IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER).crossDomainMessageSource();
        // TODO

        LocalAsyncProxy remoteProxy = AsyncUtils.calculateLocalAsyncProxyAddress(
            address(this),
            crossDomainCallbackSender,
            crossDomainCallbackSource
        );

        AsyncPromise promiseContract = remoteProxy.promisesById(_callback.asyncCallId);

        return promiseContract.remoteTarget() == crossDomainCallbackSender;
    }

    function executeCallback(AsyncCallback calldata _callback) internal {
        AsyncPromise promiseContract = getPromiseContract(_callback);

        bytes4 callbackSelector = promiseContract.callbackSelector();
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(callbackSelector, _callback.returnData)
        );

        require(success, "Callback execution failed");

        console.log("Callback executed, success: %s, returnData: ", success);
        console.logBytes(returnData);

        promiseContract.markResolved();
    }

    function getPromiseContract(AsyncCallback calldata _callback) internal view returns (AsyncPromise) {
        address crossDomainCallbackSender = IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER).crossDomainMessageSender();
        uint256 crossDomainCallbackSource = IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER).crossDomainMessageSource();

        LocalAsyncProxy remoteProxy = AsyncUtils.calculateLocalAsyncProxyAddress(
            address(this),
            crossDomainCallbackSender,
            crossDomainCallbackSource
        );

        return remoteProxy.promisesById(_callback.asyncCallId);
    }

    modifier async() {
        // only callable by self via relayAsyncCall
        require(msg.sender == address(this));
        _;
    }

    modifier asyncCallback() {
        // only callable by self via relayAsyncCallback
        require(msg.sender == address(this));
        _;
    }
}
