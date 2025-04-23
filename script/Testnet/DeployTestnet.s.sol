// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DeployApp} from "../Deploy/DeployApp.sol";
import {WETH} from "test/mock/WETH.sol";
import {Market} from "src/platforms/perps/Market.sol";

contract DeployTestnet is DeployApp {
    constructor() DeployApp(getSettings()) {}

    function getSettings() internal returns (Settings memory) {
        PoolSettings memory _poolSettings = PoolSettings({
            collateralRatio: 37500, // 375%
            liquidationRatio: 15000, // 150%
            liquidationPenaltyPercentagePoint: 1500, // 15%
            liquidationBonusPercentagePoint: 500, // 5%
            loanFee: 150, // 1.5%
            stabilityFee: 500, // 5%
            cooldownPeriod: 2 minutes
        });

        ExchangerSettings memory _exchangerSettings = ExchangerSettings({
            swapFee: 100, // 1%
            rewarderFee: 0,
            burntAtSwap: 100, // 1%
            settlementDelay: 2 minutes
        });

        Asset[] memory _assets = new Asset[](6);

        _assets[0] = Asset(address(0), "AMZN", "Amazon", 178e8); // $178.00
        _assets[1] = Asset(address(0), "NFLX", "Netflix", 625e8); // $625.00
        _assets[2] = Asset(address(0), "MSFT", "Microsoft", 425e8); // $425.00
        _assets[3] = Asset(address(0), "NVDA", "NVIDIA", 880e8); // $880.00
        _assets[4] = Asset(address(0), "AAPL", "Apple", 175e8); // $175.00
        _assets[5] = Asset(address(0), "XAU", "Gold", 2070e8); // $2,070.00

        Asset[] memory _collaterals = new Asset[](0);

        return Settings({
            chainId: 4157,
            owner: 0x12e048D4f26F54C0625ef34faBd365E4f925f2fF,
            wxfi: address(0),
            diaOracle: address(0),
            poolSettings: _poolSettings,
            exchangerSettings: _exchangerSettings,
            assets: _assets,
            collaterals: _collaterals
        });
    }

    function _afterSetup() internal override {
        _broadcastDeployMulticall3();

        wxfi = address(_broadcastDeployWxfi());
        address usdt = address(_broadcastDeployMockToken("Tether USD", "USDT"));

        collaterals.push(Asset(wxfi, "XFI", "CrossFi", 0.18e8));
        collaterals.push(Asset(usdt, "USDT", "Tether USD", 1e8));
    }
}
