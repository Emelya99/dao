// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {DAOContract} from "../src/DAOContract.sol";

contract DeployDAOScript is Script {
    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address token = vm.envAddress("TOKEN_ADDRESS");

        vm.startBroadcast(pk);

        new DAOContract(
            token,
            1000, // min tokens to create proposal
            5 minutes // <--- VOTING PERIOD = 5 minutes
        );

        vm.stopBroadcast();
    }
}
