pragma solidity ^0.5.3;

import "testeth/Log.sol";
import "testeth/Assert.sol";
import "testeth/Account.sol";

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
      mstore(1407, signatory)

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
    function invalidMethod() external;
}

contract Recorder {
  bytes data;

  function () external {
    data = msg.data;
  }

  function dataLen() external view returns (uint256) {
    return data.length;
  }
}

contract Teller {
  function callit(address target, bytes calldata data) external {
    target.call(data);
  }
}

// test interest mechanism
contract test_Basics {
  Factory factory = new Factory();
  MultisigWallet wallet;
  Recorder recorder = new Recorder();
  Teller teller = new Teller();

  function check_a1_construction_useAccount1() public {
    wallet = MultisigWallet(factory.deploy1SignerWallet(1, msg.sender));
    Log.data(address(wallet));
  }

  function check_a2_canAcceptEther_method_useValue4500() public payable {
    address payable addr = address(wallet);

    Assert.equal(addr.balance, 0);

    addr.transfer(4500);

    Assert.equal(addr.balance, 4500);
  }

  bytes recordData = "\x19\x01";
  bytes data = abi.encodeWithSelector(bytes4(0x7214ae99), address(recorder), recordData);
  uint256 gasLimit = 600000;
  uint256 nonce = 0;
  address destination = address(teller);
  bytes32 hash;

  function check_a3_buildHash_useAccount1() public {
    // EIP712 Transaction Hash
    hash = keccak256(abi.encodePacked(
      "\x19\x01",
      bytes32(0xb0609d81c5f719d8a516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f2),
      keccak256(abi.encode(
          bytes32(0x4a0a6d86122c7bd7083e83912c312adabf207e986f1ac10a35dfeb610d28d0b6),
          nonce,
          destination,
          gasLimit,
          keccak256(data)
      ))
    ));

    Account.sign(1, hash);
  }

  bytes32[] arr;

  function check_a4_signature_useAccount1(uint8 v, bytes32 r, bytes32 s) public {
    arr.push(bytes32(uint256(v)));
    arr.push(r);
    arr.push(s);

    Assert.equal(recorder.dataLen(), 0);

    wallet.execute(destination, gasLimit, data, arr);

    Assert.equal(recorder.dataLen(), 2);
  }

  function check_a5_buildHash_inceaseNonce_useAccount1() public {
    // EIP712 Transaction Hash
    nonce += 1;
    recordData = "\x19\x01\x01";
    data = abi.encodeWithSelector(bytes4(0x7214ae99), address(recorder), recordData);
    hash = keccak256(abi.encodePacked(
      "\x19\x01",
      bytes32(0xb0609d81c5f719d8a516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f2),
      keccak256(abi.encode(
          bytes32(0x4a0a6d86122c7bd7083e83912c312adabf207e986f1ac10a35dfeb610d28d0b6),
          nonce,
          destination,
          gasLimit,
          keccak256(data)
      ))
    ));

    Account.sign(1, hash);
  }

  bytes32[] arr2;

  function check_a6_inceaseNonce_useAccount1(uint8 v, bytes32 r, bytes32 s) public {
    arr2.push(bytes32(uint256(v)));
    arr2.push(r);
    arr2.push(s);

    Assert.equal(recorder.dataLen(), 2);

    wallet.execute(destination, gasLimit, data, arr2);

    Assert.equal(recorder.dataLen(), 3);
  }

  function check_a7_buildHash_testInvalidNonce_useAccount1() public {
    // EIP712 Transaction Hash
    nonce = 1; // THIS IS AN INVALID NONCE
    recordData = "\x19\x01\x01";
    data = abi.encodeWithSelector(bytes4(0x7214ae99), address(recorder), recordData);
    hash = keccak256(abi.encodePacked(
      "\x19\x01",
      bytes32(0xb0609d81c5f719d8a516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f2),
      keccak256(abi.encode(
          bytes32(0x4a0a6d86122c7bd7083e83912c312adabf207e986f1ac10a35dfeb610d28d0b6),
          nonce,
          destination,
          gasLimit,
          keccak256(data)
      ))
    ));

    Account.sign(1, hash);
  }

  bytes32[] sig3;

  function check_a8_testInvalidNonce_useAccount1_shouldThrow(uint8 v, bytes32 r, bytes32 s) public {
    sig3.push(bytes32(uint256(v)));
    sig3.push(r);
    sig3.push(s);

    wallet.execute(destination, gasLimit, data, sig3);
  }

  function check_b1_buildHash_testSameWithValidNonce_useAccount1() public {
    // EIP712 Transaction Hash
    nonce = 2; // THIS IS AN INVALID NONCE
    recordData = "\x19\x01\x01";
    data = abi.encodeWithSelector(bytes4(0x7214ae99), address(recorder), recordData);
    hash = keccak256(abi.encodePacked(
      "\x19\x01",
      bytes32(0xb0609d81c5f719d8a516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f2),
      keccak256(abi.encode(
          bytes32(0x4a0a6d86122c7bd7083e83912c312adabf207e986f1ac10a35dfeb610d28d0b6),
          nonce,
          destination,
          gasLimit,
          keccak256(data)
      ))
    ));

    Account.sign(1, hash);
  }

  bytes32[] sig4;

  function check_b2_testSameWithValidNonce_useAccount1(uint8 v, bytes32 r, bytes32 s) public {
    sig4.push(bytes32(uint256(v)));
    sig4.push(r);
    sig4.push(s);

    wallet.execute(destination, gasLimit, data, sig4);

    Assert.equal(recorder.dataLen(), 3);
  }

  function check_b3_buildHash_testInvalidSigningAccount_useAccount1() public {
    // EIP712 Transaction Hash
    nonce = 3; // THIS IS AN INVALID NONCE
    recordData = "\x19\x01\x01";
    data = abi.encodeWithSelector(bytes4(0x7214ae99), address(recorder), recordData);
    hash = keccak256(abi.encodePacked(
      "\x19\x01",
      bytes32(0xb0609d81c5f719d8a516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f2),
      keccak256(abi.encode(
          bytes32(0x4a0a6d86122c7bd7083e83912c312adabf207e986f1ac10a35dfeb610d28d0b6),
          nonce,
          destination,
          gasLimit,
          keccak256(data)
      ))
    ));

    Account.sign(2, hash);
  }

  bytes32[] sig5;

  function check_b4_testSameWithValidNonce_useAccount1_shouldThrow(uint8 v, bytes32 r, bytes32 s) public {
    sig5.push(bytes32(uint256(v)));
    sig5.push(r);
    sig5.push(s);

    wallet.execute(destination, gasLimit, data, sig5);
  }

  function check_b5_randomCall() public {
    address(wallet).call("0x1234");
  }

  function check_b6_invalidMethod_shouldThrow() public {
    wallet.invalidMethod();
  }
}
