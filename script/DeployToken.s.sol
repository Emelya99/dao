// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AYEMToken} from "../src/AYEMToken.sol";
import {Script} from "forge-std/Script.sol";

contract DeployTokenScript is Script {
    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("TOKEN_OWNER");
        vm.startBroadcast(pk);

        new AYEMToken(owner, owner);

        vm.stopBroadcast();
    }
}
