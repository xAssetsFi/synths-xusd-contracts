// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Settings {
    address public owner = 0x12e048D4f26F54C0625ef34faBd365E4f925f2fF;

    address public wxfi = 0x28cC5eDd54B1E4565317C3e0Cfab551926A4CD2a;
    address public wbtc = 0x914938e817bd0b5f7984007dA6D27ca2EfB9f8f4;
    address public weth = 0x74f4B6c7F7F518202231b58CE6e8736DF6B50A81;
    address public usdc = 0x83E9A41c38D71f7a06632dE275877FcA48827870;

    struct Asset {
        address tokenAddress;
        string symbol;
        string name;
        uint256 price;
    }

    Asset[] assets;
    Asset[] collaterals;

    function _setupCollateralAndAssets() internal {
        assets.push(Asset(address(0), "VIC", "Vincom Retail", 163_000_000));
        assets.push(Asset(address(0), "HPG", "Hoang Phuc Gia", 105_000_000));
        assets.push(Asset(address(0), "FPT", "FPT", 530_000_000));
        assets.push(Asset(address(0), "VFS", "VinFast", 396_000_000));
        assets.push(Asset(address(0), "XAU", "Gold", 273_600_000_000));

        collaterals.push(Asset(wxfi, "XFI", "XFI", 83_000_000));
        collaterals.push(Asset(wbtc, "BTC", "Bitcoin", 6_836_700_000_000));
        collaterals.push(Asset(weth, "ETH", "Ethereum", 251_000_000_000));
        collaterals.push(Asset(usdc, "USDC", "USD Coin", 100_000_000));
    }
}
