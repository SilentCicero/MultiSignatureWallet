/**
  * @title MultiSignatureWallet
  * @author Nick Dodson <thenickdodson@gmail.com>
  * @notice 264 byte Weighted eth_sign Compliant Delegate-Call Enabled MultiSignature Wallet for the Ethereum Virtual Machine
  */
object "MultiSignatureWallet" {
  code {
    // constructor: uint256(signatures required) + address[] signatories (bytes32 sep|chunks|data...)
    codecopy(0, 264, codesize()) // setup constructor args: mem positon 0 | code size 280 (before args) | 1000 bytes of address args (30)
    sstore(address(), mload(0)) // map contract address => signatures required

    for { let i := 96 } lt(i, add(96, mul(32, mload(64)))) { i := add(i, 32) } { // iterate through signatory addresses
       sstore(mload(i), 1) // map signer address => signer address
    }

    datacopy(0, dataoffset("Runtime"), datasize("Runtime")) // now switch over to runtime code from constructor
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    code {
        if eq(calldatasize(), 0) {
          mstore(0, caller()) // load caller
          mstore(32, callvalue()) // load value
          log0(0, 64) // log caller / value
          stop()
        } // fallback log zero

        // call data: bytes4(sig) bytes32(dest) bytes32(gasLimit) bytes(data) bytes32[](signatures) | supports fallback
        calldatacopy(160, 0, calldatasize()) // copy calldata to memory

        let dataSize := mload(292)

        mstore(100, address())
        mstore(132, sload(add(address(), 1)))

        mstore(0, 0x19457468657265756d205369676e6564204d6573736167653a0a3332) // "\x19Ethereum Signed Message:\n32" bytes28
        mstore(32, keccak256(100, dataSize)) // 32 byte hash appended to EthSign hash

        let ethSignHash := keccak256(4, 60) // EIP712 final signing hash
        let signatureMemoryPosition := add(164, mload(260)) // new memory position -32 bytes from sig start
        let previousAddress := 0 // comparison variable, used to check for duplicate signer accounts

        for { let i := sload(caller()) } lt(i, sload(address())) { } { // signature validation: loop through signatures (i < required signatures)
            mstore(signatureMemoryPosition, ethSignHash) // place hash before each sig in memory: hash + v + r + s | hash + vN + rN + sN

            let ecrecoverResult := call(3000, 1, 0, signatureMemoryPosition, 128, 64, 32) // call ecrecover precompile with ecrecover(hash,v,r,s) | failing is okay here
            let recoveredAddress := mload(64)

            if or(eq(caller(), recoveredAddress), iszero(gt(recoveredAddress, previousAddress))) { revert(0, 0) } // sload(current address) > prev address OR revert

            previousAddress := recoveredAddress // set previous address for future comparison
            signatureMemoryPosition := add(signatureMemoryPosition, 96)
            i := add(i, sload(recoveredAddress))
        }

        sstore(add(address(), 1), add(1, mload(132))) // increase nonce: nonce = nonce + 1

        if iszero(delegatecall(mload(196), mload(164), 324, dataSize, 0, 0)) { revert(0, 0) }
    }
  }
}

/*
==============================
Contract Storage Layout
==============================

address            | Weighted Signatory Threshold
address + 1        | Nonce
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

0     | eth_sign Prefix (4 byte padded) -- bytes28
32    | Eth Sign Hash -- bytes32
64    | ECRecover Address -- address
100   | Contract Address -- address
132   | Nonce -- uint256
164   | Destination  -- address
196   | gasLimit -- address
228   | data length -- uint256
260   | data end position -- uint256
292   | data size -- uint256
324   | data -- raw bytes...

add(164, mload(260)) | signatures array length -- uint256
add(196, mload(260)) | signature parts.. bytes32(v1), bytes32(r1), bytes32(s1), bytes32(vN), bytes32(rN), bytes32(sN), ...
*/
