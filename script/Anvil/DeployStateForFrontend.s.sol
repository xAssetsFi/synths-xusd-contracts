// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DeployApp} from "../Deploy/DeployApp.sol";
import {WETH} from "test/mock/WETH.sol";
import {Market} from "src/platforms/perps/Market.sol";

contract DeployStateForFrontend is DeployApp {
    uint256 alicePk = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    uint256 bobPk = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    constructor() DeployApp(getSettings()) {}

    function _afterDeploy() internal override {
        _mintXusd(alicePk);
        _mintXusd(bobPk);

        _openPosition(alicePk, 300e18);
        _openPosition(bobPk, -200e18);
    }

    function _openPosition(uint256 pk, int256 sizeInXusd) internal {
        address[] memory markets = marketManager.getAllMarkets();

        address market = markets[0];

        uint256 price = Market(market).assetPrice();

        (int256 margin, int256 size, uint256 desiredFillPrice) =
            _getOpenPositionArgs(sizeInXusd, price);

        vm.startBroadcast(pk);

        Market(market).transferMarginAndModifyPosition(margin, size, desiredFillPrice);

        vm.stopBroadcast();
    }

    function _getOpenPositionArgs(int256 sizeInXusd, uint256 price)
        internal
        returns (int256, int256, uint256)
    {
        int256 leverage = 2;

        int256 margin = sizeInXusd > 0 ? sizeInXusd / leverage : -sizeInXusd / leverage;

        int256 size = sizeInXusd * 1e18 / int256(price);

        uint256 desiredFillPrice = sizeInXusd > 0 ? type(uint256).max : 0;

        return (margin, size, desiredFillPrice);
    }

    function _mintXusd(uint256 pk) internal {
        vm.startBroadcast(pk);

        WETH(wxfi).approve(address(pool), type(uint256).max);
        pool.supplyETHAndBorrow{value: 1000e18}(100000e18, type(uint256).max, vm.addr(pk));

        vm.stopBroadcast();
    }

    function getSettings() internal returns (Settings memory) {
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

        _assets[0] = Asset(address(0), "AMZN", "Amazon", 178e8); // $178.00
        _assets[1] = Asset(address(0), "NFLX", "Netflix", 625e8); // $625.00
        _assets[2] = Asset(address(0), "MSFT", "Microsoft", 425e8); // $425.00
        _assets[3] = Asset(address(0), "NVDA", "NVIDIA", 880e8); // $880.00
        _assets[4] = Asset(address(0), "AAPL", "Apple", 175e8); // $175.00
        _assets[5] = Asset(address(0), "XAU", "Gold", 2070e8); // $2,070.00

        Asset[] memory _collaterals = new Asset[](0);

        return Settings({
            chainId: 4157,
            owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            wxfi: address(0),
            diaOracle: address(0),
            poolSettings: _poolSettings,
            exchangerSettings: _exchangerSettings,
            assets: _assets,
            collaterals: _collaterals
        });
    }

    function _afterSetup() internal override {
        wxfi = address(_broadcastDeployWxfi());

        collaterals.push(Asset(wxfi, "XFI", "CrossFi", 1500e8));

        _broadcastDeployMulticall3();
    }
}
