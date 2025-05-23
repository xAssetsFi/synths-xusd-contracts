// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DeployApp} from "../Deploy/DeployApp.sol";

contract DeployCrossfi is DeployApp {
    constructor() DeployApp(getSettings()) {}

    function getSettings() internal pure returns (Settings memory) {
        PoolSettings memory _poolSettings = PoolSettings({
            collateralRatio: 37500, // 375%
            liquidationRatio: 15000, // 150%
            liquidationPenaltyPercentagePoint: 1500, // 15%
            liquidationBonusPercentagePoint: 500, // 5%
            loanFee: 150, // 1.5%
            stabilityFee: 100, // 1%
            cooldownPeriod: 12 hours
        });

        ExchangerSettings memory _exchangerSettings = ExchangerSettings({
            swapFee: 100, // 1%
            rewarderFee: 0,
            burntAtSwap: 100, // 1%
            settlementDelay: 2 minutes
        });

        Asset[] memory _assets = new Asset[](6);

        // XFI/USD

        // AMZN/USD
        // NFLX/USD
        // MSFT/USD
        // NVDA/USD
        // AAPL/USD
        // XAU/USD

        _assets[0] = Asset(address(0), "AMZN", "Amazon", 0);
        _assets[1] = Asset(address(0), "NFLX", "Netflix", 0);
        _assets[2] = Asset(address(0), "MSFT", "Microsoft", 0);
        _assets[3] = Asset(address(0), "NVDA", "NVIDIA", 0);
        _assets[4] = Asset(address(0), "AAPL", "Apple", 0);
        _assets[5] = Asset(address(0), "XAU", "Gold", 0);

        address _wxfi = 0xC537D12bd626B135B251cCa43283EFF69eC109c4;

        Asset[] memory _collaterals = new Asset[](1);
        _collaterals[0] = Asset(_wxfi, "XFI", "CrossFi", 0);

        return Settings({
            chainId: 4158,
            owner: 0x12e048D4f26F54C0625ef34faBd365E4f925f2fF,
            wxfi: _wxfi,
            diaOracle: 0x859e221ada7CEBDF5D4040bf6a2B8959C05a4233,
            poolSettings: _poolSettings,
            exchangerSettings: _exchangerSettings,
            assets: _assets,
            collaterals: _collaterals
        });
    }
}
