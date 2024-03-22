// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

contract NFTMarketplaceScript is Script {
    NFTMarketplace nftMarketplace;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        nftMarketplace = new NFTMarketplace();
        vm.stopBroadcast();
    }
}
