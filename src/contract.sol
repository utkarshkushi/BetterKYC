//spdx-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.0/contracts/utils/structs/EnumerableSet.sol";

interface IDagNode {
    function add(bytes memory) external returns (bytes32);
    function get(bytes32) external view returns (bytes memory);
}

contract UserContract {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    struct User {
        string name;
        string panNumber;
        string birthDate;
        address accountAddress;
        string aadhaarNumber;
    }
    
    mapping(address => bytes32) private userHashes;
    EnumerableSet.AddressSet private users;
    
    function addUser(string memory _name, string memory _panNumber, string memory _birthDate, string memory _aadhaarNumber) public {
        User memory newUser = User(_name, _panNumber, _birthDate, msg.sender, _aadhaarNumber);
        bytes32 userHash = keccak256(abi.encode(newUser));
        storeOnIPFS(userHash);
        userHashes[msg.sender] = userHash;
        users.add(msg.sender);
    }
    
    function storeOnIPFS(bytes32 _ipfsHash) private {
        IDagNode dagNode = IDagNode(address(0x5f5b...)); // replace with actual IPFS dag node contract address
        dagNode.add(abi.encodePacked(_ipfsHash));
    }
    
    function retrieveUser() public view returns (User memory) {
        bytes32 userHash = userHashes[msg.sender];
        bytes32 hash = retrieveFromIPFS(userHash);
        User memory user = abi.decode(retrieveFromIPFS(hash), (User));
        return user;
    }
    
    function retrieveFromIPFS(bytes32 _ipfsHash) private view returns (bytes32) {
        IDagNode dagNode = IDagNode(address(0x5f5b...)); // replace with actual IPFS dag node contract address
        bytes memory hashBytes = dagNode.get(_ipfsHash);
        bytes32 hash;
        assembly {
            hash := mload(add(hashBytes, 32))
        }
        return hash;
    }
    
    function verifyAadhaar(string memory _aadhaarNumber) public view returns (bool) {
        User memory user = retrieveUser();
        return keccak256(abi.encode(user.aadhaarNumber)) == keccak256(abi.encode(_aadhaarNumber));
    }
    
    function verifyPanNumber(string memory _panNumber) public view returns (bool) {
        User memory user = retrieveUser();
        return keccak256(abi.encode(user.panNumber)) == keccak256(abi.encode(_panNumber));
    }
    
    function verifyAge(uint256 _age) public view returns (bool) {
        User memory user = retrieveUser();
        uint256 birthYear = parseInt(getField(user.birthDate, "/", 2));
        uint256 age = calculateAge(birthYear);
        return age >= _age;
    }
    
    function calculateAge(uint256 _birthYear) private view returns (uint256) {
        uint256 currentYear = parseInt(getField(getCurrentDate(), "/", 2));
        return currentYear - _birthYear;
    }
    
    function getField(string memory _str, string memory _delimiter, uint256 _fieldNum) private pure returns (string memory) {
        string[] memory parts = split(_str, _delimiter);
        require(_fieldNum <= parts.length, "Invalid field number");
        return parts[_fieldNum - 1];
    }
    
    function getCurrentDate() private view returns (string memory) {
        uint256 timestamp = block.timestamp;
    return timestampToDate(timestamp);
}

function timestampToDate(uint256 _timestamp) private pure returns (string memory) {
    return timestampToString(_timestamp, "DD/MM/YYYY");
}

function timestampToString(uint256 _timestamp, string memory _format) private pure returns (string memory) {
    bytes memory buffer = new bytes(20);
    uint256 index = 0;
    uint256 value;
    for (uint256 i = 0; i < bytes(_format).length; i++) {
        if (bytes(_format)[i] == "D") {
            value = uint256(_timestamp / 86400);
        } else if (bytes(_format)[i] == "M") {
            value = uint256(_timestamp / 2629743);
        } else if (bytes(_format)[i] == "Y") {
            value = uint256(_timestamp / 31556926);
        } else {
            buffer[index++] = bytes(_format)[i];
            continue;
        }
        if (value == 0) {
            buffer[index++] = "0";
        }
        while (value > 0) {
            buffer[index++] = bytes(uint256(value % 10 + 48));
            value /= 10;
        }
    }
    bytes memory res = new bytes(index);
    for (uint256 i = 0; i < index; i++) {
        res[i] = buffer[index - i - 1];
    }
    return string(res);
}

function parseInt(string memory _value) private pure returns (uint256) {
    bytes memory b = bytes(_value);
    uint256 result = 0;
    for (uint256 i = 0; i < b.length; i++) {
        if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
            result = result * 10 + (uint256(uint8(b[i])) - 48);
        }
    }
    return result;
}

function split(string memory _str, string memory _delimiter) private pure returns (string[] memory) {
    bytes memory bStr = bytes(_str);
    bytes memory bDelimiter = bytes(_delimiter);
    uint256 count = 1;
    for (uint256 i = 0; i < bStr.length - bDelimiter.length; i++) {
        if (bStr[i] == bDelimiter[0]) {
            bool found = true;
            for (uint256 j = 1; j < bDelimiter.length; j++) {
                if (bStr[i + j] != bDelimiter[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                count++;
            }
        }
    }
    string[] memory parts = new string[](count);
    uint256 index = 0;
    string memory part;
    for (uint256 i = 0; i < bStr.length; i++) {
        if (bStr[i] == bDelimiter[0]) {
            bool found = true;
            for (uint256 j = 1; j < bDelimiter.length; j++) {
                if (bStr[i + j] != bDelimiter[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                parts[index++] = part;
                part = "";
                i += bDelimiter.length - 1;
            } else {
                part = string(abi.encodePacked(part, bStr[i]));
            }
        } else {
            part = string(abi.encodePacked(part, bStr[i]));
        }
    }
    parts[index++] = part;
    return parts
}
}


