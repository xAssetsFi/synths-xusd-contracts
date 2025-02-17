// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {UUPSProxy} from "src/common/_UUPSProxy.sol";

import {IExchanger} from "src/interface/platforms/synths/IExchanger.sol";
import {IOracleAdapter} from "src/interface/IOracleAdapter.sol";
import {ISynth} from "src/interface/platforms/synths/ISynth.sol";
import {IDebtShares} from "src/interface/IDebtShares.sol";
import {IPlatform} from "src/interface/platforms/IPlatform.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {ArrayLib} from "src/lib/ArrayLib.sol";

contract Exchanger is IExchanger, UUPSProxy {
    using Clones for address;
    using SafeERC20 for ISynth;
    using ArrayLib for address[];

    address[] private _synths;

    mapping(address user => mapping(address synthOut => Settlement)) private _settlements;

    mapping(address => bool) public isSynth;

    uint256 public swapNonce;
    uint256 public constant MAX_PENDING_SETTLEMENT = 10;

    /**
     * @notice With each swap the user will receive less synthOut,
     * this shortfall is burned and is not considered a commission.
     * This is to decrease the total debt of users who have a debt position in pool contract.
     */
    uint256 public burntAtSwap;

    uint256 public rewarderFee;

    uint256 public swapFee;
    address public feeReceiver;

    uint256 public settlementDelay;

    uint256 public settleFunctionGasCost;

    function initialize(
        address _owner,
        address _provider,
        uint256 _swapFee,
        uint256 _rewarderFee,
        uint256 _burntAtSwap,
        uint256 _settlementDelay
    ) public initializer {
        __UUPSProxy_init(_owner, _provider);
        feeReceiver = _owner;

        swapFee = _swapFee;
        burntAtSwap = _burntAtSwap;
        rewarderFee = _rewarderFee;
        settlementDelay = _settlementDelay;

        settleFunctionGasCost = 200000;

        _afterInitialize();
    }

    /* ======== External Functions ======== */

    function synths() external view returns (address[] memory) {
        return _synths;
    }

    function getSwapFeeForSettle() public view returns (uint256) {
        return settleFunctionGasCost * block.basefee;
    }

    function swap(address synthIn, address synthOut, uint256 amountIn, address receiver)
        external
        payable
        noPaused
        onlySynth(synthIn)
        onlySynth(synthOut)
        noZeroUint(amountIn)
        returns (uint256 amountOut)
    {
        if (msg.value != getSwapFeeForSettle()) revert InsufficientGasFee();

        if (_settlements[receiver][synthOut].swaps.length + 1 == MAX_PENDING_SETTLEMENT) {
            revert MaxPendingSettlementReached();
        }

        amountIn = _chargeFee(synthIn, amountIn, msg.sender);
        amountOut = _previewSwap(synthIn, synthOut, amountIn);

        Settlement storage settlement = _settlements[receiver][synthOut];
        Swap memory swapData = Swap(swapNonce++, synthIn, synthOut, amountIn, amountOut);
        settlement.settleReserve += msg.value;
        settlement.swaps.push(swapData);
        settlement.lastUpdate = block.timestamp;

        _swap(
            swapData.synthIn,
            swapData.synthOut,
            swapData.amountIn,
            swapData.amountOut,
            msg.sender,
            receiver
        );

        emit Swapped(
            swapData.nonce,
            swapData.synthIn,
            swapData.synthOut,
            swapData.amountIn,
            swapData.amountOut,
            msg.sender,
            receiver
        );
    }

    function _swap(
        address synthIn,
        address synthOut,
        uint256 amountIn,
        uint256 amountOut,
        address owner,
        address receiver
    ) internal {
        ISynth(synthIn).burn(owner, amountIn);
        ISynth(synthOut).mint(receiver, amountOut);
    }

    function _chargeFee(address synthIn, uint256 amountIn, address owner)
        internal
        returns (uint256)
    {
        (uint256 _swapFee, uint256 _rewarderFee, uint256 _burned) = _calcFee(amountIn);

        if (_burned > 0) ISynth(synthIn).burn(owner, _burned);

        if (_swapFee > 0) {
            _chargeFeeInXUSD(synthIn, _swapFee, owner, feeReceiver);
        }

        if (_rewarderFee > 0) {
            IDebtShares debtShares = provider().pool().debtShares();

            uint256 amountOut = _chargeFeeInXUSD(synthIn, _rewarderFee, owner, address(this));

            ISynth xusd = provider().xusd();
            xusd.approve(address(debtShares), amountOut);
            debtShares.addReward(address(xusd), amountOut);
        }

        return amountIn - (_swapFee + _rewarderFee + _burned);
    }

    function _chargeFeeInXUSD(address synthIn, uint256 amountIn, address owner, address receiver)
        internal
        returns (uint256 amountOut)
    {
        ISynth xusd = provider().xusd();

        if (synthIn != address(xusd)) {
            amountOut = _previewSwap(synthIn, address(xusd), amountIn);
            _swap(synthIn, address(xusd), amountIn, amountOut, owner, receiver);
        } else {
            amountOut = amountIn;
            xusd.safeTransferFrom(owner, receiver, amountOut);
        }
    }

    function _calcFee(uint256 amountIn)
        internal
        view
        returns (uint256 _swapFee, uint256 _rewarderFee, uint256 _burned)
    {
        _swapFee = (amountIn * swapFee) / PRECISION;
        _rewarderFee = (amountIn * rewarderFee) / PRECISION;
        _burned = (amountIn * burntAtSwap) / PRECISION;
    }

    function settle(address user, address synth, address settlementCompensationReceiver)
        external
        noPaused
        onlySynth(synth)
    {
        Settlement memory settlement = _settlements[user][synth];

        if (settlement.swaps.length == 0) revert NoSwaps();

        if (block.timestamp < settlement.lastUpdate + settlementDelay) {
            revert SettlementDelayNotOver();
        }

        delete _settlements[user][synth];

        for (uint256 i = 0; i < settlement.swaps.length; i++) {
            Swap memory data = settlement.swaps[i];

            uint256 settled = _previewSwap(data.synthIn, data.synthOut, data.amountIn);

            if (settled < data.amountOut) {
                ISynth(data.synthOut).burn(user, data.amountOut - settled);
            } else if (settled > data.amountOut) {
                ISynth(data.synthOut).mint(user, settled - data.amountOut);
            }

            emit SwapSettled(
                user, synth, data.nonce, data.synthIn, data.synthOut, data.amountIn, settled
            );
        }

        (bool success,) =
            payable(settlementCompensationReceiver).call{value: settlement.settleReserve}("");

        if (!success) revert TransferFailed();
    }

    /* ======== View ======== */

    function totalFunds() public view returns (uint256 tf) {
        IOracleAdapter oracle = provider().oracle();

        for (uint256 i = 0; i < _synths.length; i++) {
            IERC20Metadata synth = IERC20Metadata(_synths[i]);

            tf += ((synth.totalSupply() * WAD) * oracle.getPrice(_synths[i]))
                / (10 ** synth.decimals() * oracle.precision());
        }
    }

    function previewSwap(address synthIn, address synthOut, uint256 amountIn)
        public
        view
        onlySynth(synthIn)
        onlySynth(synthOut)
        returns (uint256 amountOut)
    {
        (uint256 _swapFee, uint256 _rewarderFee, uint256 _burned) = _calcFee(amountIn);

        amountIn -= _swapFee + _rewarderFee + _burned;

        amountOut = _previewSwap(synthIn, synthOut, amountIn);
    }

    function _previewSwap(address synthIn, address synthOut, uint256 amountIn)
        internal
        view
        returns (uint256 amountOut)
    {
        IOracleAdapter oracle = provider().oracle();

        amountOut = (amountIn * oracle.getPrice(synthIn)) / oracle.getPrice(synthOut);
    }

    function getSettlement(address user, address synth)
        external
        view
        onlySynth(synth)
        returns (Settlement memory settlement)
    {
        settlement = _settlements[user][synth];
    }

    function isTransferable(address synth, address user) external view returns (bool) {
        return _settlements[user][synth].swaps.length == 0;
    }

    /* ======== Utils ======== */

    modifier onlySynth(address synth) {
        if (!isSynth[synth]) revert InvalidSynth(synth);
        _;
    }

    /* ======== Admin ======== */

    function createSynth(
        address _implementation,
        address _owner,
        string memory _name,
        string memory _symbol
    ) external onlyOwner returns (address) {
        address synth = _implementation.clone();
        ISynth(synth).initialize(_owner, address(provider()), _name, _symbol);
        addNewSynth(synth);
        return synth;
    }

    function addNewSynth(address _synth)
        public
        onlyOwner
        noZeroAddress(_synth)
        validInterface(_synth, type(ISynth).interfaceId)
    {
        isSynth[_synth] = true;
        _synths.push(_synth);
        emit SynthAdded(_synth);
    }

    function removeSynth(address _synth) external onlyOwner onlySynth(_synth) {
        isSynth[_synth] = false;
        _synths.remove(_synth);
        emit SynthRemoved(_synth);
    }

    function setSettlementDelay(uint256 _settlementDelay) external onlyOwner {
        settlementDelay = _settlementDelay;
        emit SettlementDelayChanged(_settlementDelay);
    }

    function setSwapFee(uint256 _swapFee) external onlyOwner {
        swapFee = _swapFee;
        emit SwapFeeChanged(_swapFee);
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner noZeroAddress(_feeReceiver) {
        feeReceiver = _feeReceiver;
        emit FeeReceiverChanged(_feeReceiver);
    }

    function setBurntAtSwap(uint256 _burntAtSwap) external onlyOwner {
        burntAtSwap = _burntAtSwap;
        emit BurntAtSwapChanged(_burntAtSwap);
    }

    function setRewarderFee(uint256 _rewarderFee) external onlyOwner {
        rewarderFee = _rewarderFee;
        emit RewarderFeeChanged(_rewarderFee);
    }

    function initialize(address, address) public override initializer {
        revert DeprecatedInitializer();
    }

    function _afterInitialize() internal override {
        _registerInterface(type(IPlatform).interfaceId);
        _registerInterface(type(IExchanger).interfaceId);
    }
}
