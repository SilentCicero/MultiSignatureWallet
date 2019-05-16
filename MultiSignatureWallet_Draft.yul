/**
  * @title MultiSignatureWallet
  * @author Nick Dodson <thenickdodson@gmail.com>
  * @notice 313 byte Weighted EIP712 Signing Compliant Delegate-Call Enabled MultiSignature Wallet for the Ethereum Virtual Machine
  */
object "MultiSignatureWallet" {
  code {
    // constructor: uint256(signatures required) + address[] signatories (bytes32 sep|chunks|data...)
    codecopy(0, 313, codesize()) // setup constructor args: mem positon 0 | code size 280 (before args)
    sstore(1, mload(0)) // map contract address => signatures required

    for { let i := 96 } lt(i, add(96, mul(32, mload(64)))) { i := add(i, 32) } { // iterate through signatory addresses
        sstore(mload(i), 1) // map signer address => signer address
    }

    datacopy(0, dataoffset("Runtime"), datasize("Runtime")) // now switch over to runtime code from constructor
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    code {
        if eq(calldatasize(), 0) {
            log2(0, 0, caller(), callvalue()) // log caller / value
            stop()
        } // fallback log zero

        // call data: bytes4(sig) bytes32(dest) bytes32(gasLimit) bytes(data) bytes32[](signatures) | supports fallback
        calldatacopy(220, 0, calldatasize()) // copy calldata to memory

        let dataSize := mload(348) // size of the bytes data
        let nonce := sload(2)

        // build EIP712 release hash
        mstore(128, 0x4a0a6d86122c7bd7083e83912c312adabf207e986f1ac10a35dfeb610d28d0b6) // EIP712 Execute TypeHash: Execute(address verifyingContract,uint256 nonce,address destination,uint256 gasLimit,bytes data)
        mstore(160, address()) // use the contract address as salt for replay protection
        mstore(192, nonce) // map wallet nonce to memory (nonce: storage(address + 1))
        mstore(284, keccak256(380, dataSize)) // we have to hash the bytes data due to EIP712... why....

        mstore(0, 0x1901)
        mstore(32, 0xb0609d81c5f719d8a516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f2) // EIP712 Domain Seperator: EIP712Domain(string name,string version,uint256 chainId)
        mstore(64, keccak256(128, 192)) // EIP712 Execute() Hash

        let eip712Hash := keccak256(30, 66) // EIP712 final signing hash
        let signatureMemoryPosition := add(224, mload(316)) // new memory position -32 bytes from sig start
        let previousAddress := 0 // comparison variable, used to check for duplicate signer accounts

        for { let i := sload(caller()) } lt(i, sload(1)) { } { // signature validation: loop through signatures (i < required signatures)
            mstore(signatureMemoryPosition, eip712Hash) // place hash before each sig in memory: hash + v + r + s | hash + vN + rN + sN

            let ecrecoverResult := call(3000, 1, 0, signatureMemoryPosition, 128, 96, 32) // call ecrecover precompile with ecrecover(hash,v,r,s) | failing is okay here
            let recoveredAddress := mload(96)

            if or(eq(caller(), recoveredAddress), iszero(gt(recoveredAddress, previousAddress))) { revert(0, 0) } // sload(current address) > prev address OR revert

            previousAddress := recoveredAddress // set previous address for future comparison
            signatureMemoryPosition := add(signatureMemoryPosition, 96)
            i := add(i, sload(recoveredAddress))
        }

        sstore(2, add(1, nonce)) // increase nonce: nonce = nonce + 1

        if iszero(delegatecall(mload(252), mload(224), 380, dataSize, 0, 0)) { revert(0, 0) }
    }
  }
}

/*
==============================
Contract Storage Layout
==============================

0            | left empty
1            | Weighted Signatory Threshold
2            | Nonce
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

0       | EIP712 Prefix          | 0x1901
32      | Domain Seperator Hash  | keccak256("EIP712Domain(string name,string version,uint256 chainId)")
64      | Execute Hash           |
96      | ECRecovered Address    | ecrecover address
128     | Execute Typehash       | keccak256("Execute(address verifyingContract,uint256 nonce,address destination,uint256 gasLimit,bytes data)")
160     | Contract Address       | address() // used for replay attack prevention
192     | Nonce                  | sload(add(address(), 1)) // used for double spend prevention
224     | Destination            | delegate call target (specified in calldata)
252     | Gas Limit              | delegate call gas limit (specified in calldata)
284     | Hash of Data           | keccak256(of data)
316     | End of Bytes Data      | End of bytes data (specified in calldata)
348     | Data size              | bytes data raw size (specified in calldata)
380     | Actual Bytes Data      | raw bytes data (specified in calldata)
*/
