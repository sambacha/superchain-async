pragma solidity ^0.8.13;
import {console} from "forge-std/console.sol";
import {AsyncPromise} from "./AsyncPromise.sol";
import {AsyncUtils, AsyncCall, XAddress} from "./AsyncUtils.sol";
import {SuperchainEnabled} from "./SuperchainEnabled.sol";
import {AsyncEnabled} from "./AsyncEnabled.sol";

// An LocalAsyncProxy is a local representation of a contract on a remote chain.
// Calling an LocalAsyncProxy triggers an authenticated call to an async function,
//  on the remote chain and returns a local Promise contract,
//  which will eventually trigger a local callback with the return value of the remote async call.
contract LocalAsyncProxy is SuperchainEnabled {
    // address and chainId of the remote contract triggered by calling this local proxy
    XAddress internal remoteXAddress;
    // address of local contract which can call this remote proxy to send async calls
    address public localAddress;
    // nonce for promises made by this remote proxy
    uint256 public nonce = 0;
    // mapping of nonce to promise
    mapping(uint256 => AsyncPromise) public promisesByNonce;
    // mapping of callId to promise
    mapping(bytes32 => AsyncPromise) public promisesById;

    constructor(address _remoteAddress, uint256 _chainId) {
        remoteXAddress = XAddress(_remoteAddress, _chainId);
        localAddress = msg.sender;
    }

    function getRemoteXAddress() external view returns (XAddress memory) {
        return remoteXAddress;
    }

    fallback(bytes calldata data) external returns (bytes memory) {
        XAddress memory fromContract = XAddress(msg.sender, block.chainid);

        AsyncCall memory asyncCall = AsyncCall(
            fromContract,
            remoteXAddress,
            nonce,
            data
        );

        bytes32 callId = AsyncUtils.getAsyncCallId(asyncCall);

        AsyncPromise promiseContract = new AsyncPromise(msg.sender, remoteXAddress.addr, callId);
        promisesByNonce[nonce] = promiseContract;
        promisesById[callId] = promiseContract;
        nonce++;
        console.log("made promise", address(promiseContract));

        bytes memory relayCallPayload = abi.encodeWithSelector(
            AsyncEnabled.relayAsyncCall.selector,
            asyncCall
        );

        AsyncUtils.encodeAsyncCall(asyncCall);
        _xMessageContract(
            remoteXAddress.chainId,
            remoteXAddress.addr,
            relayCallPayload
        );

        return abi.encodePacked(bytes32(uint256(uint160(address(promiseContract)))));
    }
}
