// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.23;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import {DeployAppTestnet} from "../Testnet/DeployAppTestnet.s.sol";

import {WETH} from "test/_Mock/WETH.sol";
import {ERC20Token, USDC} from "test/_Mock/ERC20Token.sol";

contract DeployForLiquidatorTests is DeployAppTestnet {
    function setUp() public virtual override {
        chainId = 31337;

        owner = vm.addr(privateKey);

        vm.startBroadcast(privateKey);

        wxfi = address(new WETH());
        wbtc = address(new ERC20Token("Bitcoin", "BTC"));
        weth = address(new ERC20Token("Ethereum", "ETH"));
        usdc = address(new USDC());

        vm.stopBroadcast();

        _setupCollateralAndAssets();
    }

    function _afterDeploy() internal virtual override {
        vm.startBroadcast(privateKey);

        uint256 tokenPrecision = 10 ** IERC20Metadata(usdc).decimals();

        USDC(usdc).mint(owner, 300 * tokenPrecision);
        USDC(usdc).approve(address(pool), 300 * tokenPrecision);

        pool.supplyAndBorrow(
            address(usdc), 300 * tokenPrecision, 100 ether, type(uint256).max, owner
        );

        diaOracle.setValue("USDC/USD", 6e7);

        uint256 healthFactor = pool.getHealthFactor(owner);

        require(healthFactor < 1e18, "Position is healthy");

        require(healthFactor >= 0.9e18, "Health factor is not met");

        vm.stopBroadcast();
    }
}
