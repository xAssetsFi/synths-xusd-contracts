// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {SynthDataProvider} from "../src/platforms/Synths/SynthDataProvider.sol";
import {Exchanger} from "../src/platforms/Synths/Exchanger.sol";
import {Pool} from "../src/core/pool/Pool.sol";
import {PoolDataProvider} from "../src/periphery/PoolDataProvider.sol";
import {Fork} from "../utils/Fork.sol";
import {FileUtils} from "../utils/FileHelpers.sol";

contract Upgrade is Script, Fork {
    FileUtils fileUtils;
    uint32 chainId = 4158;

    function run() public {
        fileUtils = new FileUtils();

        fork(chainId);

        // vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        upgradePoolDataProvider();

        vm.stopBroadcast();
    }

    function upgradeSynthDataProvider() public {
        address synthDataProvider = 0xC95DE30cf98D9e8b46D24ac2dCD6d6C62A02c84A;
        address newSynthImpl = address(new SynthDataProvider());

        SynthDataProvider(synthDataProvider).upgradeToAndCall(newSynthImpl, "");

        SynthDataProvider.SynthData[] memory data =
            SynthDataProvider(synthDataProvider).synthsData(address(0x0));

        console.log(data[0].name);
    }

    function upgradeExchanger() public {
        address exchanger = 0xbEC6c0F95BB2A76409Cf83693a4c47fE3E133959;
        address newExchangerImpl = address(new Exchanger());

        Exchanger(exchanger).upgradeToAndCall(newExchangerImpl, "");
    }

    function upgradePool() public {
        address pool = 0x0e1BBf79BFC00bdFd41E64c10824De149D717Ccc;
        address newPoolImpl = address(new Pool());

        Pool(payable(pool)).upgradeToAndCall(newPoolImpl, "");
    }

    function upgradePoolDataProvider() public {
        address poolDataProvider = fileUtils.readContractAddress(chainId, "poolDataProvider");

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        console.log(poolDataProvider);

        address newPoolDataProviderImpl = address(new PoolDataProvider());

        PoolDataProvider(poolDataProvider).upgradeToAndCall(newPoolDataProviderImpl, "");
    }
}
