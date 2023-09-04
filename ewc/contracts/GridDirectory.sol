// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

// #if _DEBUG
//import "hardhat/console.sol";
// #endif

//import "./Addresses.sol";

contract GridDirectory {
    struct Entry {
        uint index; // index in the keylist + 1
        // Info of the node
    }

    struct KeyList {
        address[] keys;
        uint size;
    }

    struct itmapNodes {
        mapping(address => Entry) nodesInfo;
        KeyList nodes;
    }

    //Mapping that allows you to search for a user with their Ethereum address and retrieve their data.
    itmapNodes internal _directory;
    address internal immutable _marketer;

    modifier onlyMarketer() {
        require(
            msg.sender == _marketer,
            "!mkterAddr"
        );
        _;
    }

    constructor() {
        _marketer = msg.sender;
    }

    function addNode(address addr_) external onlyMarketer {
        Entry storage entry = _directory.nodesInfo[addr_]; 
        if (entry.index == 0) {     
            // Add a new entry in the keylist at the end
            _directory.nodes.keys.push(addr_);
            _directory.nodes.size++;
            // new entry
            entry.index = _directory.nodes.size;
        }
    }

    function removeNode(address addr_) external onlyMarketer {
        Entry storage entry = _directory.nodesInfo[addr_]; 
        require(entry.index != 0); // entry not exist
        require(entry.index <= _directory.nodes.size); // invalid index value
        
        // Move the last element of the directory into the vacated key slot
        uint keyListIndex = entry.index - 1;
        uint keyListLastIndex = _directory.nodes.size - 1;
        _directory.nodesInfo[_directory.nodes.keys[keyListLastIndex]].index = keyListIndex + 1;
        _directory.nodes.keys[keyListIndex] = _directory.nodes.keys[keyListLastIndex];
        _directory.nodes.size--;

        delete _directory.nodesInfo[addr_];
    }

    function isMember( address addr_ )external view returns (bool) {
        return _directory.nodesInfo[addr_].index > 0;
     }
}