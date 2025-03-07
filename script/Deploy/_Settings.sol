// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract DeploymentSettings {
    struct PoolSettings {
        uint32 collateralRatio;
        uint32 liquidationRatio;
        uint32 liquidationPenaltyPercentagePoint;
        uint32 liquidationBonusPercentagePoint;
        uint32 loanFee;
        uint32 stabilityFee;
        uint32 cooldownPeriod;
    }

    struct ExchangerSettings {
        uint256 swapFee;
        uint256 rewarderFee;
        uint256 burntAtSwap;
        uint256 settlementDelay;
    }

    struct Settings {
        uint32 chainId;
        address owner;
        address wxfi;
        address diaOracle;
        PoolSettings poolSettings;
        ExchangerSettings exchangerSettings;
        Asset[] assets;
        Asset[] collaterals;
    }

    struct Asset {
        address tokenAddress;
        string symbol;
        string name;
        uint256 price;
    }

    uint32 public chainId;
    address public owner;
    address public wxfi;
    address public diaOracle;

    Asset[] assets;
    Asset[] collaterals;

    PoolSettings public poolSettings;
    ExchangerSettings public exchangerSettings;

    constructor(Settings memory settings) {
        wxfi = settings.wxfi;
        chainId = settings.chainId;
        owner = settings.owner;

        diaOracle = settings.diaOracle;

        poolSettings = settings.poolSettings;
        exchangerSettings = settings.exchangerSettings;

        for (uint256 i = 0; i < settings.assets.length; i++) {
            assets.push(settings.assets[i]);
        }

        for (uint256 i = 0; i < settings.collaterals.length; i++) {
            collaterals.push(settings.collaterals[i]);
        }
    }

    // function _setupCollateralAndAssets() internal {
    //     assets.push(Asset(address(0), "VIC", "Vincom Retail", 163_000_000));
    //     assets.push(Asset(address(0), "HPG", "Hoang Phuc Gia", 105_000_000));
    //     assets.push(Asset(address(0), "FPT", "FPT", 530_000_000));
    //     assets.push(Asset(address(0), "VFS", "VinFast", 396_000_000));
    //     assets.push(Asset(address(0), "XAU", "Gold", 273_600_000_000));

    //     collaterals.push(Asset(wxfi, "XFI", "XFI", 83_000_000));
    //     collaterals.push(Asset(wbtc, "BTC", "Bitcoin", 6_836_700_000_000));
    //     collaterals.push(Asset(weth, "ETH", "Ethereum", 251_000_000_000));
    //     collaterals.push(Asset(usdc, "USDC", "USD Coin", 100_000_000));
    // }
}
