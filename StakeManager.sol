// SPDX-License-Identifier: MIT

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

pragma solidity ^0.6.6;

import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/math/SafeMath.sol";
import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/token/ERC20/ERC20.sol";
import "https://github.com/Woonkly/MartinHSolUtils/Utils.sol";

import "https://github.com/Woonkly/MartinHSolUtils/Owners.sol";

contract StakeManager is Owners, ERC20 {
    using SafeMath for uint256;

    //Section Type declarations

    struct Stake {
        address account;
        uint256 tokena;
        uint256 tokenb;
        uint8 flag; //0 no exist  1 exist 2 deleted
    }

    //Section State variables
    uint256 internal _lastIndexStakes;
    mapping(uint256 => Stake) internal _Stakes;
    mapping(address => uint256) internal _IDStakesIndex;
    uint256 internal _StakeCount;

    //Section Modifier
    modifier onlyNewStake(address account) {
        require(!this.StakeExist(account), "This Stake account exist");
        _;
    }

    modifier onlyStakeExist(address account) {
        require(StakeExist(account), "This Stake account not exist");
        _;
    }

    modifier onlyStakeIndexExist(uint256 index) {
        require(StakeIndexExist(index), "This Stake index not exist");
        _;
    }

    //Section Events
    event addNewStake(address account, uint256 amount);
    event StakeAdded(address account, uint256 oldAmount, uint256 newAmount);
    event StakeReNewed(address account, uint256 oldAmount, uint256 newAmount);
    event RewaredChanged(
        address account,
        uint256 amount,
        uint8 set,
        bool isTkA
    );
    event StakeRemoved(address account);
    event StakeSubstracted(
        address account,
        uint256 oldAmount,
        uint256 subAmount,
        uint256 newAmount
    );
    event AllStakeRemoved();

    //Section functions

    constructor(string memory name, string memory symbol)
        public
        ERC20(name, symbol)
    {
        _lastIndexStakes = 0;
        _StakeCount = 0;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(false);
        super._transfer(sender, recipient, amount);
    }

    function manageStake(address account, uint256 amount)
        public
        onlyIsInOwners
        returns (bool)
    {
        if (!StakeExist(account)) {
            newStake(account, amount);
        } else {
            addToStake(account, amount);
        }

        return true;
    }

    function transferStake(address origin, address destination)
        external
        onlyIsInOwners
        returns (bool)
    {
        require(StakeExist(origin), "!E");

        uint256 amount;
        uint256 tokena;
        uint256 tokenb;

        (amount, tokena, tokenb) = getStake(origin);

        manageStake(destination, amount);

        if (tokena > 0) {
            changeToken(destination, tokena, 2, true);
        }

        if (tokenb > 0) {
            changeToken(destination, tokenb, 2, false);
        }

        removeStake(origin);

        return true;
    }

    function getStakeCount() public view returns (uint256) {
        return _StakeCount;
    }

    function getLastIndexStakes() public view returns (uint256) {
        return _lastIndexStakes;
    }

    function StakeExist(address account) public view returns (bool) {
        return _StakeExist(_IDStakesIndex[account]);
    }

    function StakeIndexExist(uint256 index) public view returns (bool) {
        return (index < (_lastIndexStakes + 1));
    }

    function _StakeExist(uint256 StakeID) internal view returns (bool) {
        return (_Stakes[StakeID].flag == 1);
    }

    function _newStake(address account, uint256 amount)
        internal
        onlyNewStake(account)
        returns (uint256)
    {
        _lastIndexStakes = _lastIndexStakes.add(1);
        _StakeCount = _StakeCount.add(1);

        _Stakes[_lastIndexStakes].account = account;
        _Stakes[_lastIndexStakes].tokena = 0;
        _Stakes[_lastIndexStakes].tokenb = 0;
        _Stakes[_lastIndexStakes].flag = 1;

        _IDStakesIndex[account] = _lastIndexStakes;

        if (amount > 0) {
            _mint(account, amount);
        }

        emit addNewStake(account, amount);
        return _lastIndexStakes;
    }

    function newStake(address account, uint256 amount)
        public
        onlyIsInOwners
        onlyNewStake(account)
        returns (uint256)
    {
        return _newStake(account, amount);
    }

    function addToStake(address account, uint256 addAmount)
        public
        onlyIsInOwners
        onlyStakeExist(account)
        returns (uint256)
    {
        uint256 oldAmount = balanceOf(account);
        if (addAmount > 0) {
            _mint(account, addAmount);
        }

        emit StakeAdded(account, oldAmount, addAmount);

        return _IDStakesIndex[account];
    }

    function renewStake(address account, uint256 newAmount)
        external
        onlyIsInOwners
        onlyStakeExist(account)
        returns (uint256)
    {
        uint256 oldAmount = balanceOf(account);
        if (oldAmount > 0) {
            _burn(account, oldAmount);
        }

        if (newAmount > 0) {
            _mint(account, newAmount);
        }

        emit StakeReNewed(account, oldAmount, newAmount);

        return _IDStakesIndex[account];
    }

    function changeToken(
        address account,
        uint256 amount,
        uint8 set,
        bool isTkA
    ) public onlyIsInOwners onlyStakeExist(account) returns (bool) {
        if (isTkA) {
            if (set == 1) {
                _Stakes[_IDStakesIndex[account]].tokena = amount;
            }

            if (set == 2) {
                _Stakes[_IDStakesIndex[account]].tokena = _Stakes[
                    _IDStakesIndex[account]
                ]
                    .tokena
                    .add(amount);
            }

            if (set == 3) {
                _Stakes[_IDStakesIndex[account]].tokena = _Stakes[
                    _IDStakesIndex[account]
                ]
                    .tokena
                    .sub(amount);
            }
        } else {
            if (set == 1) {
                _Stakes[_IDStakesIndex[account]].tokenb = amount;
            }

            if (set == 2) {
                _Stakes[_IDStakesIndex[account]].tokenb = _Stakes[
                    _IDStakesIndex[account]
                ]
                    .tokenb
                    .add(amount);
            }

            if (set == 3) {
                _Stakes[_IDStakesIndex[account]].tokenb = _Stakes[
                    _IDStakesIndex[account]
                ]
                    .tokenb
                    .sub(amount);
            }
        }

        emit RewaredChanged(account, amount, set, isTkA);

        return true;
    }

    function removeStake(address account)
        public
        onlyIsInOwners
        onlyStakeExist(account)
    {
        _Stakes[_IDStakesIndex[account]].flag = 2;
        _Stakes[_IDStakesIndex[account]].account = address(0);
        _Stakes[_IDStakesIndex[account]].tokena = 0;
        _Stakes[_IDStakesIndex[account]].tokenb = 0;
        uint256 bl = balanceOf(account);
        if (bl > 0) {
            _burn(account, bl);
        }

        _StakeCount = _StakeCount.sub(1);
        emit StakeRemoved(account);
    }

    function substractFromStake(address account, uint256 subAmount)
        external
        onlyIsInOwners
        onlyStakeExist(account)
        returns (uint256)
    {
        uint256 oldAmount = balanceOf(account);

        if (oldAmount == 0) {
            return _IDStakesIndex[account];
        }

        require(subAmount <= oldAmount, "SM invalid amount ");

        _burn(account, subAmount);

        emit StakeSubstracted(
            account,
            oldAmount,
            subAmount,
            balanceOf(account)
        );

        return _IDStakesIndex[account];
    }

    function getValues(address account) public view returns (uint256, uint256) {
        if (!StakeExist(account)) return (0, 0);

        Stake memory p = _Stakes[_IDStakesIndex[account]];

        return (p.tokena, p.tokenb);
    }

    function getStake(address account)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (!StakeExist(account)) return (0, 0, 0);

        Stake memory p = _Stakes[_IDStakesIndex[account]];

        return (balanceOf(account), p.tokena, p.tokenb);
    }

    function getStakeByIndex(uint256 index)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint8
        )
    {
        if (!StakeIndexExist(index)) return (address(0), 0, 0, 0, 0);

        Stake memory p = _Stakes[index];

        return (p.account, balanceOf(p.account), p.tokena, p.tokenb, p.flag);
    }

    function getAllStake()
        public
        view
        returns (
            uint256[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256[] memory indexs = new uint256[](_StakeCount);
        address[] memory pACCs = new address[](_StakeCount);
        uint256[] memory pAmounts = new uint256[](_StakeCount);
        uint256[] memory pA = new uint256[](_StakeCount);
        uint256[] memory pB = new uint256[](_StakeCount);

        uint256 ind = 0;

        for (uint32 i = 0; i < (_lastIndexStakes + 1); i++) {
            Stake memory p = _Stakes[i];
            if (p.flag == 1) {
                indexs[ind] = i;
                pACCs[ind] = p.account;
                pAmounts[ind] = balanceOf(p.account);
                pA[ind] = p.tokena;
                pB[ind] = p.tokenb;
                ind++;
            }
        }

        return (indexs, pACCs, pAmounts, pA, pB);
    }

    function removeAllStake() external onlyIsInOwners returns (bool) {
        for (uint32 i = 0; i < (_lastIndexStakes + 1); i++) {
            _IDStakesIndex[_Stakes[i].account] = 0;

            address acc = _Stakes[i].account;
            _Stakes[i].flag = 0;
            _Stakes[i].account = address(0);
            _Stakes[i].tokena = 0;
            _Stakes[i].tokenb = 0;
            uint256 bl = balanceOf(acc);
            if (bl > 0) {
                _burn(acc, bl);
            }
        }
        _lastIndexStakes = 0;
        _StakeCount = 0;
        emit AllStakeRemoved();
        return true;
    }
}
