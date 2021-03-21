// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/math/SafeMath.sol";
import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/token/ERC20/ERC20.sol";
import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/utils/ReentrancyGuard.sol";
import "https://github.com/Woonkly/MartinHSolUtils/PausabledLMH.sol";
import "https://github.com/Woonkly/MartinHSolUtils/BaseLMH.sol";
import "https://github.com/Woonkly/DEFImultiStablePOOL/StakeManager.sol";
import "https://github.com/Woonkly/DEFImultiStablePOOL/IWStaked.sol";

/**
MIT License

Copyright (c) 2021 Woonkly OU

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED BY WOONKLY OU "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

contract PoolERC20BASE is BaseLMH, Owners, PausabledLMH, ReentrancyGuard {
    using SafeMath for uint256;

    //Section Type declarations
    struct Stake {
        address account;
        uint256 liq;
        uint256 tokena;
        uint256 tokenb;
        uint8 flag;
    }
    struct processRewardInfo {
        uint256 remainder;
        uint256 woopsRewards;
        uint256 dealed;
        address me;
        bool resp;
    }

    //Section State variables
    IERC20 internal _tokenB;
    address internal _operations;
    address internal _beneficiary;
    address internal _crossbeneficiary;
    IWStaked internal _stakes;
    address internal _stakeable;
    uint256 internal _gasRequired;
    uint32 internal _feeReward;
    uint32 internal _feeOperation;
    uint32 internal _feeCross;
    uint32 internal _baseFee;
    bool internal _isBNBenv;
    address internal _erc20B;

    //Section Modifier

    //Section Events
    event BeneficiaryChanged(address oldBn, address newBn);
    event CrossBeneficiaryChanged(address oldBn, address newBn);
    event FeeOperationChanged(uint32 oldFee, uint32 newFee);
    event FeeRewardChanged(uint32 oldFee, uint32 newFee);
    event CROSSRewardChanged(uint32 oldFee, uint32 newFee);
    event BaseFeeChanged(uint32 oldbFee, uint32 newbFee);
    event GasRequiredChanged(uint256 oldg, uint256 newg);
    event OperationsChanged(address oldOp, address newOp);
    event StakeAddrChanged(address old, address news);
    event TokenBChanged(address old, address news);
    event InsuficientRewardFund(address account, bool isTKAorCOIN);
    event NewLeftover(address account, uint256 leftover, bool isTKAorCOIN);

    //Section functions

    constructor(
        address erc20B,
        uint32 feeReward,
        uint32 feeOperation,
        uint32 feeCross,
        address operations,
        address beneficiary,
        address crossbeneficiary,
        address stake,
        bool isBNBenv
    ) public {
        _erc20B = erc20B;
        _feeReward = feeReward;
        _feeOperation = feeOperation;
        _feeCross = feeCross;
        _beneficiary = beneficiary;
        _crossbeneficiary = crossbeneficiary;
        _operations = operations;
        _stakes = IWStaked(stake);
        _stakeable = stake;
        _isBNBenv = isBNBenv;
        _tokenB = IERC20(erc20B);
        _paused = true;
        _baseFee = 10000;
        _gasRequired = 150000;
    }

    function isBNB() public view returns (bool) {
        return _isBNBenv;
    }

    function getBeneficiary() public view returns (address) {
        return _beneficiary;
    }

    function setBeneficiary(address newBn)
        external
        onlyIsInOwners
        returns (bool)
    {
        require(newBn != address(0), "1");
        address old = _beneficiary;
        _beneficiary = newBn;
        emit BeneficiaryChanged(old, _beneficiary);
        return true;
    }

    function getCrossBeneficiary() public view returns (address) {
        return _crossbeneficiary;
    }

    function setCrossBeneficiary(address newBn)
        external
        onlyIsInOwners
        returns (bool)
    {
        require(newBn != address(0), "1");
        address old = _crossbeneficiary;
        _crossbeneficiary = newBn;
        emit CrossBeneficiaryChanged(old, _crossbeneficiary);
        return true;
    }

    function getFeeOperation() public view returns (uint32) {
        return _feeOperation;
    }

    function setFeeOperation(uint32 newFee)
        external
        onlyIsInOwners
        returns (bool)
    {
        require((newFee > 0 && newFee <= 1000000), "1");
        uint32 old = _feeOperation;
        _feeOperation = newFee;
        emit FeeOperationChanged(old, _feeOperation);
        return true;
    }

    function getFeeReward() public view returns (uint32) {
        return _feeReward;
    }

    function setFeeReward(uint32 newFee)
        external
        onlyIsInOwners
        returns (bool)
    {
        require((newFee > 0 && newFee <= 1000000), "1");
        uint32 old = _feeReward;
        _feeReward = newFee;
        emit FeeRewardChanged(old, _feeReward);
        return true;
    }

    function getFeeCROSS() public view returns (uint32) {
        return _feeCross;
    }

    function setFeeCROSS(uint32 newFee) external onlyIsInOwners returns (bool) {
        require((newFee > 0 && newFee <= 1000000), "1");
        uint32 old = _feeCross;
        _feeCross = newFee;
        emit CROSSRewardChanged(old, _feeReward);
        return true;
    }

    function getBaseFee() public view returns (uint32) {
        return _baseFee;
    }

    function setBaseFee(uint32 newbFee) external onlyIsInOwners returns (bool) {
        require((newbFee > 0 && newbFee <= 1000000), "1");
        uint32 old = _baseFee;
        _baseFee = newbFee;
        emit BaseFeeChanged(old, _baseFee);
        return true;
    }

    function getGasRequired() public view returns (uint256) {
        return _gasRequired;
    }

    function setGasRequired(uint256 newg)
        external
        onlyIsInOwners
        returns (bool)
    {
        uint256 old = _gasRequired;
        _gasRequired = newg;
        emit GasRequiredChanged(old, _gasRequired);
        return true;
    }

    function getOperations() public view returns (address) {
        return _operations;
    }

    function setOperations(address newOp)
        external
        onlyIsInOwners
        returns (bool)
    {
        require(newOp != address(0), "1");
        address old = _operations;
        _operations = newOp;
        emit OperationsChanged(old, _operations);
        return true;
    }

    function getStakeAddr() public view returns (address) {
        return _stakeable;
    }

    function setStakeAddr(address news) external onlyIsInOwners returns (bool) {
        require(news != address(0), "1");
        address old = _stakeable;
        _stakeable = news;
        _stakes = IWStaked(news);
        emit StakeAddrChanged(old, news);
        return true;
    }

    function getTokenBAddr() public view returns (address) {
        return _erc20B;
    }

    function setTokenBAddr(address news)
        external
        onlyIsInOwners
        returns (bool)
    {
        require(news != address(0), "1");
        address old = _erc20B;
        _erc20B = news;
        _tokenB = ERC20(news);
        emit TokenBChanged(old, news);
        return true;
    }

    function getFee() internal view returns (uint32) {
        uint32 fee = _feeReward + _feeCross + _feeOperation;
        if (fee > _baseFee) {
            return 0;
        }

        return _baseFee - fee;
    }

    function price(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public view returns (uint256) {
        uint256 input_amount_with_fee = input_amount.mul(uint256(getFee()));
        uint256 numerator = input_amount_with_fee.mul(output_reserve);
        uint256 denominator =
            input_reserve.mul(_baseFee).add(input_amount_with_fee);
        return numerator.div(denominator);
    }

    function planePrice(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public view returns (uint256) {
        uint256 input_amount_with_fee0 = input_amount.mul(uint256(_baseFee));
        uint256 numerator = input_amount_with_fee0.mul(output_reserve);
        uint256 denominator =
            input_reserve.mul(_baseFee).add(input_amount_with_fee0);
        return numerator.div(denominator);
    }

    function calcFees(uint256 amount)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint32 totFee = _feeReward + _feeCross + _feeOperation;

        uint256 reward = amount.mul(_feeReward).div(totFee);
        uint256 oper = amount.mul(_feeOperation).div(totFee);
        uint256 cross = amount.mul(_feeCross).div(totFee);
        uint256 remainder = amount - (reward + oper + cross);

        return (remainder, reward, oper, cross);
    }

    function getCalcRewardAmount(
        address account,
        uint256 amount,
        uint256 totalLiquidity
    ) public view returns (uint256, uint256) {
        if (!_stakes.StakeExist(account)) return (0, 0);

        uint256 liq = 0;

        (liq, , ) = _stakes.getStake(account);

        uint256 part = (liq * amount).div(totalLiquidity);

        return (part,  amount - part );
    }

    function _DealLiquidity(
        uint256 amount,
        uint256 totalLiquidity,
        bool isTKAorCOIN
    ) internal returns (uint256) {
        processRewardInfo memory slot;
        slot.dealed = 0;

        Stake memory p;

        uint256 last = _stakes.getLastIndexStakes();

        for (uint256 i = 0; i < (last + 1); i++) {
            (p.account, p.liq, p.tokena, p.tokenb, p.flag) = _stakes
                .getStakeByIndex(i);

            if (p.flag == 1 && p.liq > 0) {
                (slot.woopsRewards, slot.remainder) = getCalcRewardAmount(
                    p.account,
                    amount,
                    totalLiquidity
                );
                if (slot.woopsRewards > 0) {
                    _stakes.changeToken(
                        p.account,
                        slot.woopsRewards,
                        2,
                        isTKAorCOIN
                    );

                    slot.dealed = slot.dealed.add(slot.woopsRewards);
                } else {
                    emit InsuficientRewardFund(p.account, isTKAorCOIN);
                }
            }
        } //for

        return slot.dealed;
    }
}
