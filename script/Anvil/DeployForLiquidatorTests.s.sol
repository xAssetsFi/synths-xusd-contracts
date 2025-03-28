// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
// pragma solidity ^0.8.23;

// import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

// import {DeployAppTestnet} from "../Testnet/DeployAppTestnet.s.sol";

// import {WETH} from "test/mock/WETH.sol";
// import {ERC20Token, USDC} from "test/mock/ERC20Token.sol";
// import {console} from "forge-std/console.sol";

// contract DeployForLiquidatorTests is DeployAppTestnet {
//     function setUp() public virtual override {
//         chainId = 31337;

//         owner = vm.addr(privateKey);

//         vm.startBroadcast(privateKey);

//         wxfi = address(new WETH());
//         wbtc = address(new ERC20Token("Bitcoin", "BTC"));
//         weth = address(new ERC20Token("Ethereum", "ETH"));
//         usdc = address(new USDC());

//         vm.stopBroadcast();

//         _setupCollateralAndAssets();
//     }

//     function _afterDeploy() internal virtual override {
//         vm.startBroadcast(privateKey);

//         uint256 tokenPrecision = 10 ** IERC20Metadata(usdc).decimals();

//         USDC(usdc).mint(owner, 10000 * tokenPrecision);
//         USDC(usdc).approve(address(pool), type(uint256).max);

//         pool.supplyAndBorrow(
//             address(usdc), 3000 * tokenPrecision, 1000 ether, type(uint256).max, owner
//         );

//         IERC20Metadata(xusd).approve(address(marketGold), type(uint256).max);
//         IERC20Metadata(xusd).approve(address(marketBtc), type(uint256).max);

//         marketGold.transferMarginAndModifyPosition(100e18, 1.05e17);
//         marketBtc.transferMarginAndModifyPosition(100e18, -1.1e16);

//         (uint128 xauPrice,) = diaOracle.getValue("XAU/USD");
//         (uint128 btcPrice,) = diaOracle.getValue("BTC/USD");

//         diaOracle.setValue("XAU/USD", xauPrice / 1000 * 663);
//         diaOracle.setValue("BTC/USD", btcPrice / 1000 * 1110);

//         vm.stopBroadcast();

//         uint256 anvil1Pk = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
//         address anvil1 = vm.addr(anvil1Pk);

//         vm.startBroadcast(anvil1Pk);

//         USDC(usdc).mint(anvil1, 100000 * tokenPrecision);
//         USDC(usdc).approve(address(pool), type(uint256).max);

//         pool.supplyAndBorrow(
//             address(usdc), 30000 * tokenPrecision, 1000 ether, type(uint256).max, owner
//         );
//         vm.stopBroadcast();

//         vm.startBroadcast(privateKey);

//         diaOracle.setValue("USDC/USD", 4e7);

//         require(marketBtc.baseAsset() != marketGold.baseAsset(), "Base assets are the same");

//         require(marketBtc.assetPrice() != marketGold.assetPrice(), "Prices are the same");

//         uint256 healthFactor = pool.getHealthFactor(owner);

//         require(healthFactor < 1e18, "Position is healthy");

//         require(healthFactor >= 0.9e18, "Health factor is not met");

//         address[] memory users = new address[](1);
//         users[0] = owner;

//         (address[] memory tokens, uint256[] memory shares) =
//             poolDataProvider.findLiquidationOpportunity(users);

//         require(shares[0] > 0, "No liquidation opportunity");

//         require(
//             marketGold.canLiquidate(owner, marketGold.assetPrice()), "MarketGold cannot liquidate"
//         );

//         require(marketBtc.canLiquidate(owner, marketBtc.assetPrice()), "MarketBtc cannot liquidate");
//     }
// }
