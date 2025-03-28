// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./TestUtils.sol";

import {Pool} from "src/Pool.sol";
import {Provider} from "src/Provider.sol";
import {DebtShares} from "src/DebtShares.sol";
import {DiaOracleAdapter} from "src/DiaOracleAdapter.sol";

import {Exchanger} from "src/platforms/synths/Exchanger.sol";
import {Synth} from "src/platforms/synths/Synth.sol";

import {PoolDataProvider} from "src/misc/PoolDataProvider.sol";
import {SynthDataProvider} from "src/misc/SynthDataProvider.sol";
import {PerpDataProvider} from "src/misc/PerpDataProvider.sol";

import {CalculationsInitParams} from "src/modules/pool/_Calculations.sol";

import {Market} from "src/platforms/perps/Market.sol";
import {MarketManager} from "src/platforms/perps/MarketManager.sol";

import {Deploy} from "../script/Deploy/Deploy.sol";

import {WETH} from "./mock/WETH.sol";
import {DiaOracleMock} from "./mock/DiaOracleMock.sol";
import {ERC20Token, USDC} from "./mock/ERC20Token.sol";

import {MarketLib} from "src/modules/market/_State.sol";

contract Setup is TestUtils, Deploy {
    Pool public pool;
    DebtShares public debtShares;
    Provider public provider;
    DiaOracleAdapter public oracleAdapter;
    PoolDataProvider public poolDataProvider;

    Exchanger public exchanger;
    SynthDataProvider public synthDataProvider;

    MarketManager public marketManager;
    Market public marketGold;
    PerpDataProvider public perpDataProvider;
    Synth public xusd;
    Synth public gold;
    Synth public tesla;

    ERC20Token public wbtc;
    WETH public wxfi;
    USDC public usdc;

    DiaOracleMock public diaOracle;
    Synth private _synthImplementation;
    Market public _marketImplementation;

    address user;

    function _setUp() internal override {
        diaOracle = new DiaOracleMock();
        _updateOraclePrice();

        wxfi = new WETH("Wrapped Ether", "WETH");

        CalculationsInitParams memory params = CalculationsInitParams({
            collateralRatio: 30000, // 300%
            liquidationRatio: 12000, // 120%
            liquidationPenaltyPercentagePoint: 500, // 5%
            liquidationBonusPercentagePoint: 500, // 5%
            loanFee: 100, // 1%
            stabilityFee: 100, // 1%
            cooldownPeriod: 3 minutes
        });

        provider = _deployProvider(address(this));

        _synthImplementation = new Synth();
        xusd = _deployXUSD(address(_synthImplementation), address(provider), "XUSD", "XUSD");

        exchanger = _deployExchanger(address(provider), 50, 50, 100, 3 minutes);
        debtShares = _deployDebtShares(address(provider), "xAssets debt shares", "xDS");
        pool = _deployPool(address(provider), address(wxfi), address(debtShares), params);
        oracleAdapter = _deployDiaOracleAdapter(address(provider), address(diaOracle));
        marketManager = _deployMarketManager(address(provider));

        poolDataProvider = _deployPoolDataProvider(address(provider));
        synthDataProvider = _deploySynthDataProvider(address(provider));
        perpDataProvider = _deployPerpDataProvider(address(provider));

        provider.setExchanger(address(exchanger));
        provider.setPool(address(pool));
        provider.setOracle(address(oracleAdapter));
        provider.setMarketManager(address(marketManager));

        provider.setXUSD(address(xusd));

        gold = _createSynth(address(_synthImplementation), address(provider), "Gold", "XAU");
        tesla = _createSynth(address(_synthImplementation), address(provider), "Tesla", "XLS");

        _setupTokens();
        _setUpOracleAdapter(oracleAdapter);

        _marketImplementation = new Market();

        marketGold = _createMarket(address(_marketImplementation), address(provider), "sXAU", "XAU");

        pool.addCollateralToken(address(wbtc));
        pool.addCollateralToken(address(wxfi));
        pool.addCollateralToken(address(usdc));

        debtShares.addRewardToken(address(xusd));

        pool.setCooldownPeriod(0);

        user = _makeUser("USER");

        _labels();
    }

    function _updateOraclePrice() internal {
        _updateOraclePrice(diaOracle);
    }

    function _updateOraclePrice(DiaOracleMock _diaOracle) internal {
        uint128 p = uint128(1e8);

        _diaOracle.setValue("XFI/USD", (75 * p) / 1e2);
        _diaOracle.setValue("WBTC/USD", 63000 * p);
        _diaOracle.setValue("WETH/USD", 2000 * p);
        _diaOracle.setValue("USDC/USD", 1 * p);

        _diaOracle.setValue("XAU/USD", 2000 * p);
        _diaOracle.setValue("XLS/USD", 1000 * p);
    }

    function _setUpOracleAdapter(DiaOracleAdapter _oracleAdapter) internal {
        _oracleAdapter.setKey(address(gold), "XAU/USD");
        _oracleAdapter.setKey(address(tesla), "XLS/USD");
        _oracleAdapter.setKey(address(usdc), "USDC/USD");
        _oracleAdapter.setKey(address(wxfi), "XFI/USD");
        _oracleAdapter.setKey(address(wbtc), "WBTC/USD");

        _oracleAdapter.setKey(MarketLib.getAddress("XAU"), "XAU/USD");
    }

    function _setupToken(string memory name, string memory symbol, uint256 amount)
        internal
        returns (ERC20Token _token)
    {
        _token = new ERC20Token(name, symbol);
        _token.mint(address(this), amount);
        _token.approve(address(pool), type(uint256).max);
        _token.approve(address(exchanger), type(uint256).max);
    }

    function _setupUSDC(uint256 amount) internal returns (USDC _usdc) {
        _usdc = new USDC();
        _usdc.mint(address(this), amount);
        _usdc.approve(address(pool), type(uint256).max);
        _usdc.approve(address(exchanger), type(uint256).max);
    }

    function _setupWETH(uint256 amount) internal {
        wxfi.deposit{value: amount}();
        wxfi.approve(address(pool), type(uint256).max);
        wxfi.approve(address(exchanger), type(uint256).max);
    }

    function _setupTokens() internal {
        uint256 amount = 1e28;
        wbtc = _setupToken("Wrapped BTC", "WBTC", amount);
        usdc = _setupUSDC(amount);
        _setupWETH(amount);
    }

    function _labels() internal {
        vm.label(address(gold), "XAU");
        vm.label(address(tesla), "XLS");
        vm.label(address(wbtc), "WBTC");
        vm.label(address(wxfi), "WXFI");
        vm.label(address(usdc), "USDC");
        vm.label(address(xusd), "XUSD");
        vm.label(address(pool), "Pool");
        vm.label(address(provider), "Provider");
        vm.label(address(exchanger), "Exchanger");
        vm.label(address(debtShares), "Debt Shares");
        vm.label(address(oracleAdapter), "Oracle Adapter");
        vm.label(address(poolDataProvider), "UI Data Provider");

        vm.label(address(this), "THIS");
    }

    function _parseRay(uint256 value) internal pure returns (uint256) {
        return value / WAD;
    }

    function _makeUser(string memory name) internal returns (address) {
        address _user = makeAddr(name);

        uint256 amount = 1e22;

        vm.deal(_user, amount);
        vm.label(_user, name);

        vm.startPrank(_user);

        usdc.mint(_user, amount);
        wbtc.mint(_user, amount);
        wxfi.deposit{value: amount}();

        vm.stopPrank();

        return _user;
    }

    function _swap(address _tokenIn, address _tokenOut, uint256 _amountIn) internal {
        _swap(_tokenIn, _tokenOut, _amountIn, 0);
    }

    function _swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _minAmountOut)
        internal
    {
        ERC20Token(_tokenIn).approve(address(exchanger), _amountIn);
        exchanger.swap{value: exchanger.getFinishSwapFee()}(
            _tokenIn, _tokenOut, _amountIn, _minAmountOut, address(this)
        );
    }

    function _finishSwap(address _user, address _synthOut) internal {
        skip(exchanger.finishSwapDelay());
        exchanger.finishSwap(_user, _synthOut, address(777));
    }

    function _swapAndFinish(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut
    ) internal {
        _swap(_tokenIn, _tokenOut, _amountIn, _minAmountOut);
        _finishSwap(address(this), _tokenOut);
    }

    function _skipAndUpdateOraclePrice(uint256 period) internal {
        skip(period);
        _updateOraclePrice();
    }

    receive() external payable {}
}
