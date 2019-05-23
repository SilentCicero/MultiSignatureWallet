/**
  * @title MultiSignatureWallet
  * @author Nick Dodson <thenickdodson@gmail.com>
  * @notice 279 byte Weighted EIP712 Signing Compliant Delegate-Call Enabled MultiSignature Wallet for the Ethereum Virtual Machine
  */
object "MultiSignatureWallet" {
  code {
    // constructor: uint256(signatures required) + address[] signatories (bytes32 sep|chunks|data...)
    codecopy(0, 312, codesize()) // setup constructor args: mem positon 0 | code size 280 (before args)

    for { let i := 96 } gt(mload(i), 0) { i := add(i, 32) } { // iterate through signatory addresses, address > 0
        sstore(mload(i), 1) // address => 1 (weight map
    }

    sstore(1, mload(0)) // map contract address => signatures required (moved ahead of user initiated address => weight setting)

    datacopy(0, dataoffset("Runtime"), datasize("Runtime")) // now switch over to runtime code from constructor
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    code {
        if eq(calldatasize(), 0) {
            mstore(0, callvalue())
            log1(0, 32, caller()) // log caller / value
            stop()
        } // fallback log zero

        // call data: bytes4(sig) bytes32(dest) bytes32(gasLimit) bytes(data) bytes32[](signatures) | supports fallback
        calldatacopy(188, 0, calldatasize()) // copy calldata to memory, 4 behind 188 (remove 4 byte signature)

        let dataSize := mload(320) // size of the bytes data
        let nonce := sload(0)

        // build EIP712 release hash
        mstore(32, 0x1901)
        mstore(64, 0xb0609d81c5f719d8a516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f2) // EIP712 Domain Seperator: EIP712Domain(string name,string version,uint256 chainId)
        mstore(96, 0x1) // chain ID
        mstore(128, address()) // use the contract address as salt for replay protection
        mstore(160, nonce) // map wallet nonce to memory (nonce: storage(address + 1)) */
        mstore(256, keccak256(352, dataSize)) // we have to hash the bytes data due to EIP712... why....
        mstore(64, keccak256(64, 224)) // domain seporator hash

        let eip712Hash := keccak256(62, 34) // EIP712 final signing hash
        let signatureMemoryPosition := add(192, mload(288)) // new memory position -32 bytes from sig start
        let previousAddress := 1 // comparison variable, used to check for duplicate signer accounts

        for { let i := sload(caller()) } lt(i, sload(1)) { } { // signature validation: loop through signatures (i < required signatures)
            mstore(signatureMemoryPosition, eip712Hash) // place hash before each sig in memory: hash + v + r + s | hash + vN + rN + sN

            let ecrecoverResult := call(3000, 1, 0, signatureMemoryPosition, 128, 0, 32) // call ecrecover precompile with ecrecover(hash,v,r,s) | failing is okay here
            let recoveredAddress := mload(0)

            if or(iszero(ecrecoverResult), or(eq(caller(), recoveredAddress), iszero(gt(recoveredAddress, previousAddress)))) {
                revert(0, 0)
            }
            // ecrecover must be success | recoveredAddress cannot be caller
            // | recovered address must be unique / grater than previous | recovered address must be greater than 1

            previousAddress := recoveredAddress // set previous address for future comparison
            signatureMemoryPosition := add(signatureMemoryPosition, 96)
            i := add(i, sload(recoveredAddress))
        }

        sstore(0, add(1, nonce)) // increase nonce: nonce = nonce + 1

        if iszero(delegatecall(mload(224), mload(192), 352, dataSize, 0, 0)) { revert(0, 0) }
    }
  }
}

/*
==============================
Contract Storage Layout
==============================

0            | Nonce
1            | Required Signatures
[signatory address] => signatory weight

==============================
Constructor Memory Layout
==============================

0     | Signatory Threshold -- uint256 weightedThreshold
32    | Signatory Array Length -- address[] signatories
64    | Number of Signatories -- uint256
96    | First Signatory -- address
+32   | .. N Signatory -- address

==============================
Runtime Memory Layout
==============================

0       | ECRecovered Address    | ecrecover address
32      | EIP712 Prefix          | 0x1901
64      | Domain Seperator Hash  | keccak256("EIP712Domain(string name,string version,uint256 chainId)")
96      | Chain ID               | 0x1 for mainnet
128     | Contract Address       | address() // used for replay attack prevention
160     | Nonce                  | sload(add(address(), 1)) // used for double spend prevention
192     | Destination            | delegate call target (specified in calldata)
224     | Gas Limit              | delegate call gas limit (specified in calldata)
256     | Hash of Data           | keccak256(of data)
288     | End of Bytes Data      | End of bytes data (specified in calldata)
320     | Data size              | bytes data raw size (specified in calldata)
352     | Bytes Data             | raw bytes data (specified in calldata)
*/
