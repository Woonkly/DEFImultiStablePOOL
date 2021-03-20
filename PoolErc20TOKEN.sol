// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/math/SafeMath.sol";
import "https://github.com/Woonkly/DEFImultiStablePOOL/PoolERC20BASE.sol";

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

contract PoolERC20TOKEN is PoolERC20BASE {
    using SafeMath for uint256;

    //Section Type declarations

    //Section State variables
    uint256 public totalLiquidity;
    IERC20 internal _tokenA;
    address internal _erc20A;

    //Section Modifier

    //Section Events
    event TokenAChanged(address old, address news);
    event PoolCreated(
        uint256 totalLiquidity,
        address investor,
        uint256 token_amountA,
        uint256 token_amountB
    );

    event PoolClosed(
        uint256 tkA_reserve,
        uint256 tkB_reserve,
        uint256 liquidity,
        address destination
    );

    event PurchasedTokens(
        address purchaser,
        uint256 coins,
        uint256 tokens_bought
    );
    event FeeTokens(
        uint256 liqPart,
        uint256 opPart,
        uint256 crossPart,
        address operations,
        address beneficiary,
        address crossbeneficiary
    );
    event TokensSold(address vendor, uint256 eth_bought, uint256 token_amount);
    event FeeCoins(
        uint256 liqPart,
        uint256 opPart,
        uint256 crPart,
        address beneficiary,
        address operations,
        address crossbeneficiary
    );
    event LiquidityChanged(uint256 oldLiq, uint256 newLiq);
    event LiquidityWithdraw(
        address investor,
        uint256 coins,
        uint256 token_amount,
        uint256 newliquidity
    );

    //Section functions

    constructor(
        address erc20A,
        address erc20B,
        uint32 feeReward,
        uint32 feeOperation,
        uint32 feeCross,
        address operations,
        address beneficiary,
        address crossbeneficiary,
        address stake,
        bool isBNBenv
    )
        public
        PoolERC20BASE(
            erc20B,
            feeReward,
            feeOperation,
            feeCross,
            operations,
            beneficiary,
            crossbeneficiary,
            stake,
            isBNBenv
        )
    {
        _erc20A = erc20A;
        _tokenA = IERC20(erc20A);
    }

    function getTokenAAddr() public view returns (address) {
        return _erc20A;
    }

    function setTokenAAddr(address news)
        external
        onlyIsInOwners
        returns (bool)
    {
        require(news != address(0), "0");
        address old = _erc20A;
        _erc20A = news;
        _tokenA = ERC20(news);
        emit TokenAChanged(old, news);
        return true;
    }

    function createPool(uint256 tokenA_amount, uint256 tokenB_amount)
        external
        nonReentrant
        returns (uint256)
    {
        require(
            _tokenA.allowance(_msgSender(), address(this)) >= tokenA_amount,
            "1"
        );
        require(
            _tokenB.allowance(_msgSender(), address(this)) >= tokenB_amount,
            "2"
        );

        require(!_stakes.StakeExist(_msgSender()), "3");

        require(totalLiquidity == 0, "4");

        totalLiquidity = tokenA_amount;

        _stakes.manageStake(_msgSender(), tokenA_amount);

        require(
            _tokenA.transferFrom(_msgSender(), address(this), tokenA_amount)
        );
        require(
            _tokenB.transferFrom(_msgSender(), address(this), tokenB_amount)
        );

        _paused = false;
        emit PoolCreated(
            totalLiquidity,
            _msgSender(),
            tokenA_amount,
            tokenB_amount
        );
        return totalLiquidity;
    }

    function closePool() external  onlyIsInOwners returns (bool) {
        

        require(
            _tokenA.transfer(_operations, _tokenA.balanceOf(address(this)))
        );
       
        require(
            _tokenB.transfer(_operations, _tokenB.balanceOf(address(this)))
        );

        totalLiquidity = 0;

        setPause(true);

        return true;
    }


    function isOverLimit(uint256 amount, bool isTKA)
        public
        view
        returns (bool)
    {
        return (getPercImpact(amount, isTKA) > 10);
    }

    function getPercImpact(uint256 amount, bool isTKA)
        public
        view
        returns (uint8)
    {
        uint256 reserve = 0;

        if (isTKA) {
            reserve = _tokenA.balanceOf(address(this));
        } else {
            reserve = _tokenB.balanceOf(address(this));
        }

        uint256 p = amount.mul(100).div(reserve);

        if (p <= 100) {
            return uint8(p);
        }
        return uint8(100);
    }

    function getMaxAmountSwap() public view returns (uint256, uint256) {
        return (
            _tokenA.balanceOf(address(this)).mul(10).div(100),
            _tokenB.balanceOf(address(this)).mul(10).div(100)
        );
    }

    function currentAtoB(uint256 tokenA_amount) public view returns (uint256) {
        return
            price(
                tokenA_amount,
                _tokenA.balanceOf(address(this)),
                _tokenB.balanceOf(address(this))
            );
    }

    function currentBtoA(uint256 tokenB_amount) public view returns (uint256) {
        return
            price(
                tokenB_amount,
                _tokenB.balanceOf(address(this)),
                _tokenA.balanceOf(address(this))
            );
    }

    function WithdrawReward(uint256 amount, bool isTKA)
        external
        returns (bool)
    {
        require(!isPaused(), "p");

        require(_stakes.StakeExist(_msgSender()), "1");

        uint256 tka = 0;
        uint256 tkb = 0;

        (tka, tkb) = _stakes.getValues(_msgSender());

        uint256 remainder = 0;

        if (isTKA) {
            require(amount <= tka, "2");

            require(amount <= getMyTokensBalance(_erc20A), "3");

            require(_tokenA.transfer(_msgSender(), amount), "4");

            remainder = tka.sub(amount);
        } else {
            //token

            require(amount <= tkb, "5");

            require(amount <= getMyTokensBalance(_erc20B), "6");

            require(_tokenB.transfer(_msgSender(), amount), "7");

            remainder = tkb.sub(amount);
        }

        return _stakes.changeToken(_msgSender(), remainder, 1, isTKA);
    }

    function getCalcRewardAmount(address account, uint256 amount)
        public
        view
        returns (uint256, uint256)
    {
        if (!_stakes.StakeExist(account)) return (0, 0);

        uint256 liq = 0;
        uint256 part = 0;

        (liq, , ) = _stakes.getStake(account);

        part = liq * amount.div(totalLiquidity);

        return (part, amount - part);
    }

    function sellTokenB(uint256 tka_amount)
        external
        nonReentrant
        returns (uint256)
    {
        require(!isPaused(), "p");

        require(totalLiquidity > 0, "1");

        require(!isOverLimit(tka_amount, true), "2");

        uint256 tokenb_reserve = _tokenB.balanceOf(address(this));

        uint256 tokens_bought =
            price(tka_amount, getMyTokensBalance(_erc20A), tokenb_reserve);

        uint256 tokens_bought0fee =
            planePrice(tka_amount, getMyTokensBalance(_erc20A), tokenb_reserve);

        require(tokens_bought <= getMyTokensBalance(_erc20B), "3");

        require(
            _tokenA.allowance(_msgSender(), address(this)) >= tka_amount,
            "4"
        );

        require(_tokenA.transferFrom(_msgSender(), address(this), tka_amount));

        require(_tokenB.transfer(_msgSender(), tokens_bought), "5");

        emit PurchasedTokens(_msgSender(), tka_amount, tokens_bought);

        uint256 tokens_fee = tokens_bought0fee - tokens_bought;

        uint256 tokens_opPart;
        uint256 tokens_liqPart;
        uint256 tokens_crPart;
        uint256 tokens_remainder;

        (
            tokens_remainder,
            tokens_liqPart,
            tokens_opPart,
            tokens_crPart
        ) = calcFees(tokens_fee);

        if (_isBNBenv) {
            require(_tokenB.transfer(_beneficiary, tokens_opPart), "6");
        } else {
            require(_tokenB.transfer(_operations, tokens_opPart), "7");
        }

        require(_tokenB.transfer(_crossbeneficiary, tokens_crPart), "8");

        processRewardInfo memory slot;

        slot.dealed = _DealLiquidity(tokens_liqPart, totalLiquidity, false);

        emit FeeTokens(
            tokens_liqPart,
            tokens_opPart,
            tokens_crPart,
            _operations,
            _beneficiary,
            _crossbeneficiary
        );

        if (slot.dealed > tokens_liqPart) {
            return tokens_bought;
        }

        uint256 leftover = tokens_liqPart.sub(slot.dealed);

        if (leftover > 0) {
            require(_tokenB.transfer(_operations, leftover), "9");
            emit NewLeftover(_operations, leftover, false);
        }

        return tokens_bought;
    }

    function sellTokenA(uint256 tokenb_amount)
        external
        nonReentrant
        returns (uint256)
    {
        require(!isPaused(), "p");

        require(
            _tokenB.allowance(_msgSender(), address(this)) >= tokenb_amount,
            "!aptk"
        );

        require(totalLiquidity > 0, "1");

        require(!isOverLimit(tokenb_amount, false), "2");

        uint256 tokenb_reserve = _tokenB.balanceOf(address(this));

        uint256 tka_bought =
            price(
                tokenb_amount,
                tokenb_reserve,
                _tokenA.balanceOf(address(this))
            );

        uint256 tka_bought0fee =
            planePrice(
                tokenb_amount,
                tokenb_reserve,
                _tokenA.balanceOf(address(this))
            );

        require(tka_bought <= getMyTokensBalance(_erc20A), "3");

        require(_tokenA.transfer(_msgSender(), tka_bought), "4");

        require(
            _tokenB.transferFrom(_msgSender(), address(this), tokenb_amount),
            "5"
        );

        emit TokensSold(_msgSender(), tka_bought, tokenb_amount);

        uint256 tka_fee = tka_bought0fee - tka_bought;

        uint256 tka_opPart;
        uint256 tka_crPart;
        uint256 tka_liqPart;
        uint256 tka_remainder;

        (tka_remainder, tka_liqPart, tka_opPart, tka_crPart) = calcFees(
            tka_fee
        );

        if (_isBNBenv) {
            require(_tokenA.transfer(_beneficiary, tka_opPart), "6");
        } else {
            require(_tokenA.transfer(_operations, tka_opPart), "7");
        }

        require(_tokenA.transfer(_crossbeneficiary, tka_crPart), "8");

        processRewardInfo memory slot;

        slot.dealed = _DealLiquidity(tka_liqPart, totalLiquidity, true);

        emit FeeCoins(
            tka_liqPart,
            tka_opPart,
            tka_crPart,
            _beneficiary,
            _operations,
            _crossbeneficiary
        );

        if (slot.dealed > tka_liqPart) {
            return tka_bought;
        }

        uint256 leftover = tka_liqPart.sub(slot.dealed);

        if (leftover > 0) {
            require(_tokenA.transfer(_operations, leftover), "9");

            emit NewLeftover(_operations, leftover, true);
        }

        return tka_bought;
    }

    function calcTokenBToAddLiq(uint256 tokenA) public view returns (uint256) {
        return
            (
                tokenA.mul(_tokenB.balanceOf(address(this))).div(
                    _tokenA.balanceOf(address(this))
                )
            )
                .add(1);
    }

    function AddLiquidity(uint256 tokenA_amount)
        external
        nonReentrant
        returns (uint256)
    {
        require(!isPaused(), "p");

        uint256 tka_reserve = _tokenA.balanceOf(address(this));

        uint256 tokenB_amount = calcTokenBToAddLiq(tokenA_amount);

        require(
            _msgSender() != address(0) &&
                _tokenB.allowance(_msgSender(), address(this)) >= tokenB_amount,
            "1"
        );

        require(
            _tokenA.allowance(_msgSender(), address(this)) >= tokenA_amount,
            "2"
        );

        uint256 liquidity_minted =
            tokenA_amount.mul(totalLiquidity).div(tka_reserve);

        _stakes.manageStake(_msgSender(), liquidity_minted);

        uint256 oldLiq = totalLiquidity;

        totalLiquidity = totalLiquidity.add(liquidity_minted);

        require(
            _tokenA.transferFrom(_msgSender(), address(this), tokenA_amount)
        );

        require(
            _tokenB.transferFrom(_msgSender(), address(this), tokenB_amount)
        );

        emit LiquidityChanged(oldLiq, totalLiquidity);

        return liquidity_minted;
    }

    function getValuesLiqWithdraw(address investor, uint256 liq)
        public
        view
        returns (uint256, uint256)
    {
        if (!_stakes.StakeExist(investor)) {
            return (0, 0);
        }

        uint256 inv;

        (inv, , ) = _stakes.getStake(investor);

        if (liq > inv) {
            return (0, 0);
        }

        uint256 tka_amount =
            liq.mul(_tokenA.balanceOf(address(this))).div(totalLiquidity);
        uint256 tokenB_amount =
            liq.mul(_tokenB.balanceOf(address(this))).div(totalLiquidity);
        return (tka_amount, tokenB_amount);
    }

    function getMaxValuesLiqWithdraw(address investor)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (!_stakes.StakeExist(investor)) {
            return (0, 0, 0);
        }

        uint256 tokenB_reserve = _tokenB.balanceOf(address(this));

        uint256 tka_amount;
        uint256 tokenB_amount;
        uint256 inv;

        (inv, , ) = _stakes.getStake(investor);

        tka_amount = inv.mul(_tokenA.balanceOf(address(this))).div(
            totalLiquidity
        );
        tokenB_amount = inv.mul(tokenB_reserve).div(totalLiquidity);

        return (inv, tka_amount, tokenB_amount);
    }

    function WithdrawLiquidity(uint256 liquid)
        external
        returns (uint256, uint256)
    {
        require(!isPaused(), "p");

        require(totalLiquidity > 0, "1");

        require(_stakes.StakeExist(_msgSender()), "2");

        uint256 inv_liq;

        (inv_liq, , ) = _stakes.getStake(_msgSender());

        require(liquid <= inv_liq, "3");

        uint256 tokenB_reserve = _tokenB.balanceOf(address(this));

        uint256 tka_amount =
            liquid.mul(_tokenA.balanceOf(address(this))).div(totalLiquidity);

        uint256 tokenB_amount = liquid.mul(tokenB_reserve).div(totalLiquidity);

        require(tka_amount <= getMyTokensBalance(_erc20A), "4");

        require(tokenB_amount <= getMyTokensBalance(_erc20B), "5");

        _stakes.substractFromStake(_msgSender(), liquid);

        uint256 oldLiq = totalLiquidity;

        totalLiquidity = totalLiquidity.sub(liquid);

        require(_tokenA.transfer(_msgSender(), tka_amount), "6");

        require(_tokenB.transfer(_msgSender(), tokenB_amount), "7");

        emit LiquidityWithdraw(
            _msgSender(),
            tka_amount,
            tokenB_amount,
            totalLiquidity
        );
        emit LiquidityChanged(oldLiq, totalLiquidity);
        return (tka_amount, tokenB_amount);
    }
}
