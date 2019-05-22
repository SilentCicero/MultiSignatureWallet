pragma solidity ^0.5.1;

contract MultiSignatureWalletHelpers {
    function changeRequiredSignatures(uint256 requiredSignatures) external {
        assembly {
            sstore(1, requiredSignatures) // change number of required signatures
        }
    }

    function addSignatory(uint256 requiredSignatures, address signatory, uint256 weight) external {
        assembly {
            switch iszero(gt(signatory, 1)) // ensure signatory is not reserved slots
            case 1 { revert(0, 0) }

            sstore(1, requiredSignatures)
            sstore(signatory, weight)
        }
    }

    function changeSignatoryWeight(address signatory, uint256 weight) external {
        assembly {
            switch iszero(gt(signatory, 1)) // ensure signatory is not reserved slots
            case 1 { revert(0, 0) }

            sstore(signatory, weight)
        }
    }

    function removeSignatory(uint256 requiredSignatures, address signatory) external {
        assembly {
            switch iszero(gt(signatory, 1)) // ensure signatory is not reserved slots
            case 1 { revert(0, 0) }

            sstore(1, requiredSignatures) // change required signatures
            sstore(signatory, 0) // set signatory weight to zero
        }
    }
}
