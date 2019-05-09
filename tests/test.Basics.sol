pragma solidity ^0.5.3;

import "testeth/Log.sol";
import "testeth/Assert.sol";

contract Factory {
  event Deployed(address addr, uint256 salt);

  function deploy1SignerWallet(uint256 threshold, address signatory) public returns (address payable addr) {
    assembly {
      // Multisig Wallet Code Below
      mstore(1000, 0x38610137600039600051305560605b60405160200260600181101561002f5780)
      mstore(1032, 0x518151555b60208101905061000e565b5060f780610040600039806000f350fe)
      mstore(1064, 0x361560f65760003681610424376104a8516103e87f4a0a6d86122c7bd7083e83)
      mstore(1096, 0x912c312adabf207e986f1ac10a35dfeb610d28d0b68152600180300180546104)
      mstore(1128, 0x088181526104c8915085822061046852601987538384537fb0609d81c5f719d8)
      mstore(1160, 0xa516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f260025260a0852060)
      mstore(1192, 0x225260428720945086875b305481101560d05761042860608202610488510101)
      mstore(1224, 0x87815261012c6020816080848e8c610bb8f1508381515411151560c0578a8bfd)
      mstore(1256, 0x5b8051935050505b8581019050608a565b505080518401835550858686836104)
      mstore(1288, 0x285161044851f4151560ef578586fd5b5050505050505b000000000000000000) // only 23 bytes -- 9 bytes shifted

      mstore(1311, 0x0000000000000000000000000000000000000000000000000000000000000001) // start where code leaves off
      mstore(1343, 0x0000000000000000000000000000000000000000000000000000000000000040)
      mstore(1375, 0x0000000000000000000000000000000000000000000000000000000000000001) // 1 arr element
      mstore(1407, 0x0000000000000000000000009cc37dd33527697fb1c18a4c2e19ef0652f13538)

      addr := create(0, 1000, 439)
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }

    return addr;
  }
}

contract MultisigWallet {
    function execute(address destination, uint256 gasLimit, bytes calldata data, bytes32[] calldata signatures) external;
    function () payable external;
}

// test interest mechanism
contract test_Basics {
  Factory factory = new Factory();
  MultisigWallet wallet;

  function check_a1_construction_useAccount1() public {
    wallet = MultisigWallet(factory.deploy1SignerWallet(1, msg.sender));
    Log.data(address(wallet));
  }

  function check_a2_canAcceptEther_method_useValue4500() public payable {
    address payable addr = address(wallet);

    Assert.equal(addr.balance, 0);

    (bool y,bytes memory x) = addr.call.value(4500)("");

    Assert.equal(y, true);

    Assert.equal(addr.balance, 4500);
  }

  function check_a3_signatures_useAccount1() public {

  }
}
