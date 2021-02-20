// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/math/SafeMath.sol";
import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/token/ERC20/ERC20.sol";
import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/utils/ReentrancyGuard.sol";
import "https://github.com/Woonkly/MartinHSolUtils/PausabledLMH.sol";
import "https://github.com/Woonkly/MartinHSolUtils/BaseLMH.sol";
import "https://github.com/Woonkly/DEFImultiStablePOOL/StakeManager.sol";
import "https://github.com/Woonkly/DEFImultiStablePOOL/IWStaked.sol";



contract PoolERC20BASE  is BaseLMH,Owners,PausabledLMH, ReentrancyGuard {

    using SafeMath for uint256;

    IERC20 internal _tokenB;
    
    address internal _operations;
    address internal _beneficiary;
    address internal _crossbeneficiary;
    
    IWStaked internal  _stakes;
    address internal  _stakeable;
    
    
    uint256 internal _gasRequired;
    uint32 internal _feeReward;
    uint32 internal _feeOperation;
    uint32 internal _feeCross;
    uint32 internal _baseFee;
    bool internal _isBNBenv;
    address internal _erc20B;
    

    
  constructor( address erc20B, 
            uint32 feeReward,uint32 feeOperation, uint32 feeCross,
            address operations, address beneficiary,address crossbeneficiary,
            address stake,bool isBNBenv)
    public {
        

            _erc20B=erc20B;
            _feeReward=feeReward;
            _feeOperation=feeOperation;
            _feeCross=feeCross;
            _beneficiary=beneficiary;
            _crossbeneficiary=crossbeneficiary;
            _operations=operations;
            _stakes= IWStaked(stake);
            _stakeable=stake;
            _isBNBenv=isBNBenv;
            _tokenB = IERC20(erc20B);

            _paused=true;
            _baseFee=10000;
            _gasRequired=150000;
  }
  







    function isCOIN() public view returns(bool){
        return _isBNBenv;
    }


    function getBeneficiary() public view returns(address){
        return _beneficiary;    
    }
    
    event BeneficiaryChanged(address oldBn, address newBn);

    function setBeneficiary(address newBn) public onlyIsInOwners returns(bool){
        require(newBn != address(0), "DX:0addr");
        address old=_beneficiary;
        _beneficiary = newBn;
        emit BeneficiaryChanged(old,_beneficiary);
        return true;
    }




    function getFeeOperation() public view returns(uint32){
        return _feeOperation;    
    }
    
    event FeeOperationChanged(uint32 oldFee, uint32 newFee);

    function setFeeOperation(uint32 newFee) public onlyIsInOwners returns(bool){
        require( (newFee>0 && newFee<=1000000),'DX:!');
        uint32 old=_feeOperation;
        _feeOperation=newFee;
        emit FeeOperationChanged(old,_feeOperation);
        return true;
    }


    function getFeeReward() public view returns(uint32){
        return _feeReward;    
    }
    
    event FeeRewardChanged(uint32 oldFee, uint32 newFee);

    function setFeeReward(uint32 newFee) public onlyIsInOwners returns(bool){
        require( (newFee>0 && newFee<=1000000),'DX:!');
        uint32 old=_feeReward;
        _feeReward=newFee;
        emit FeeRewardChanged(old,_feeReward);
        return true;
    }
    
    

    function getFeeCROSS() public view returns(uint32){
        return _feeCross;    
    }
    
    event CROSSRewardChanged(uint32 oldFee, uint32 newFee);

    function setFeeCROSS(uint32 newFee) public onlyIsInOwners returns(bool){
        require( (newFee>0 && newFee<=1000000),'DX:!');
        uint32 old=_feeCross;
        _feeCross=newFee;
        emit CROSSRewardChanged(old,_feeReward);
        return true;
    }



    function getBaseFee() public view returns(uint32){
        return _baseFee;    
    }
    
    event BaseFeeChanged(uint32 oldbFee, uint32 newbFee);

    function setBaseFee(uint32 newbFee) public onlyIsInOwners returns(bool){
        require( (newbFee>0 && newbFee<=1000000),'DX:!');
        uint32 old=_baseFee;
        _baseFee=newbFee;
        emit BaseFeeChanged(old,_baseFee);
        return true;
    }



    function getGasRequired() public view returns(uint256){
        return _gasRequired;    
    }
    
    event GasRequiredChanged(uint256 oldg, uint256 newg);

    function setGasRequired(uint256 newg) public onlyIsInOwners returns(bool){
        uint256 old=_gasRequired;
        _gasRequired=newg;
        emit GasRequiredChanged(old,_gasRequired);
        return true;
    }



    
    function getOperations() public view returns(address){
        return _operations;    
    }
    
    event OperationsChanged(address oldOp, address newOp);

    function setOperations(address newOp) public onlyIsInOwners returns(bool){
        require(newOp != address(0), "DX:0addr");
        address old=_operations;
        _operations=newOp;
        emit OperationsChanged(old,_operations);
        return true;
    }
    






    function getStakeAddr() public view returns(address){
        return _stakeable;
    }
    
    
    event StakeAddrChanged(address old,address news);
    function setStakeAddr(address news) public onlyIsInOwners returns(bool){
        address old=_stakeable;
        _stakeable=news;
        _stakes= IWStaked(news);
        emit StakeAddrChanged(old,news);
        return true;
    }


    function getTokenBAddr() public view returns(address){
        return _erc20B;
    }
    
    
    event TokenBChanged(address old,address news);
    function setTokenBAddr(address news) public onlyIsInOwners returns(bool){
        address old=_erc20B;
        _erc20B=news;
        _tokenB= ERC20(news);
        emit TokenBChanged(old,news);
        return true;
    }

    





    
struct Stake {
    address account;
    uint256 liq;
    uint256 tokena;
    uint256 tokenb;
    uint8 flag; 
    
  }
    
    function getFee() internal view returns(uint32){
        
        uint32 fee=  _feeReward + _feeCross +_feeOperation;
        if(fee > _baseFee){
            return 0;
        }
        
        return _baseFee - fee;
        
    }


    function price(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public view  returns (uint256) {
          uint256 input_amount_with_fee = input_amount.mul( uint256(getFee()));
          uint256 numerator = input_amount_with_fee.mul(output_reserve);
          uint256 denominator = input_reserve.mul(_baseFee).add(input_amount_with_fee);
          return numerator / denominator;
    }


    function planePrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256) {
          uint256 input_amount_with_fee0 = input_amount.mul( uint256(_baseFee));
          uint256 numerator = input_amount_with_fee0.mul(output_reserve);
          uint256 denominator = input_reserve.mul(_baseFee).add(input_amount_with_fee0);
          return numerator / denominator;
    }



    function calcFees(uint256 amount) public view returns(uint256,uint256,uint256 ,uint256 ){
        
        uint32 totFee=  _feeReward + _feeCross +_feeOperation;
        
        uint256 reward=amount.mul(_feeReward) / totFee;
        uint256 oper=amount.mul(_feeOperation) / totFee;
        uint256 cross=amount.mul(_feeCross) / totFee;
        uint256 remainder=amount - (reward + oper + cross);
        
        return ( remainder, reward , oper , cross );
    }



    




    struct processRewardInfo {
            uint256 remainder;
            uint256 woopsRewards;
            uint256 dealed;
            address me;
            bool resp;
    }        






    function getCalcRewardAmount(address account,  uint256 amount ,uint256 totalLiquidity) public view returns(uint256,uint256){
        
    
        
        if(!_stakes.StakeExist(account)) return (0,0);

        uint256 liq=0;
        uint256 part=0;


        (liq,,) = _stakes.getStake(account);

        
        if(liq==0 ) return (0,0);
        
        
        part=liq * amount / totalLiquidity;
        

        if(part==0) return (0,0);
        
        uint256 remainder = amount - part;
        
        return (part,remainder);    

    }



    event InsuficientRewardFund(address account,bool isTKAorCOIN);
    event NewLeftover(address account, uint256 leftover,bool isTKAorCOIN);


    function _DealLiquidity( uint256 amount, uint256 totalLiquidity,bool isTKAorCOIN) internal returns(uint256){
        
        processRewardInfo memory slot; slot.dealed=0;
        
        Stake memory p;
        

        uint256 last=_stakes.getLastIndexStakes();

        for (uint256 i = 0; i < (last +1) ; i++) {

            (p.account,p.liq ,p.tokena,p.tokenb ,p.flag)=_stakes.getStakeByIndex(i);
            
            if(p.flag == 1 ){

                (slot.woopsRewards, slot.remainder) = getCalcRewardAmount(p.account, amount,totalLiquidity );
                if(slot.woopsRewards>0){
                    
                    _stakes.changeToken(p.account,slot.woopsRewards, 2,isTKAorCOIN);

                    slot.dealed=slot.dealed.add(slot.woopsRewards);

                }else{
                    emit InsuficientRewardFund( p.account,isTKAorCOIN);
                }

            }
        }//for

        
        return slot.dealed;
    }


}
