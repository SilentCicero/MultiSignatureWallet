pragma solidity >0.4.99 <0.6.0;

contract MultiSignatureWalletHelpers {
    function changeRequiredSignatures(uint256 requiredSignatures) public {
        assembly {
            sstore(address, requiredSignatures)
        }
    }

    function addSignatory(bytes32 signatory) public {
        assembly {
            sstore(signatory, signatory)
        }
    }

    function addSignatory(uint256 requiredSignatures, bytes32 signatory) public {
        assembly {
            sstore(address, requiredSignatures)
            sstore(signatory, signatory)
        }
    }

    function removeSignatory(bytes32 signatory) public {
        assembly {
            sstore(signatory, 0)
        }
    }

    function removeSignatory(uint256 requiredSignatures, bytes32 signatory) public {
        assembly {
            sstore(address, requiredSignatures)
            sstore(signatory, 0)
        }
    }
}
