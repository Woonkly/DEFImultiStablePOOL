// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/math/SafeMath.sol";
import "https://github.com/Woonkly/DEFImultiStablePOOL/PoolERC20BASE.sol";


contract PoolERC20COIN  is PoolERC20BASE {

    using SafeMath for uint256;
    uint256 public totalLiquidity;
    IERC20 internal _tokenA;
    address internal _erc20A;

  constructor(address erc20A, address erc20B, 
            uint32 feeReward,uint32 feeOperation, uint32 feeCross,
            address operations, address beneficiary,address crossbeneficiary,
            address stake,bool isBNBenv) PoolERC20BASE(  erc20B, feeReward, feeOperation,  feeCross,
                                                    operations,  beneficiary, crossbeneficiary, stake, isBNBenv)
    public {

            _erc20A=erc20A;
            _tokenA = IERC20(erc20A);

  }


    function getCoinReserve() public view returns(uint256){
        return  _coin_reserve;
    }


    function isBNB() public view returns(bool){
        return _isCOIN;
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




    function getTokenAAddr() public view returns(address){
        return _erc20A;
    }
    
    
    event TokenAChanged(address old,address news);
    function setTokenAAddr(address news) public onlyIsInOwners returns(bool){
        address old=_erc20A;
        _erc20A=news;
        _tokenA= ERC20(news);
        emit TokenAChanged(old,news);
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


    
    event CoinReceived(uint256 coins);
      receive() external payable override {
            if(!isPaused()) {
                //coinToToken();
            }
            emit CoinReceived(msg.value);
        }
        
    function addCoin() public payable returns(bool){
        _coin_reserve =address(this).balance;
        return true;
    }

    
  
    event PoolCreatedCOIN(uint256 totalLiquidity,address investor,uint256 token_amount);
    
    function createPoolCOIN(uint256 token_amount) public payable   returns (uint256) {
        
        require(_isCOIN,"MP:1");

        require(_tokenB.allowance(_msgSender(),address(this)) >= token_amount , "!aptk"); 
        
        require(! _stakes.StakeExist(_msgSender()),"DX:!");    
        
        require(totalLiquidityCOIN==0,"DEX:i");
        
        require(msg.value > 0 ,"DX:I");
        
        totalLiquidityTOKEN=0;
        totalLiquidityCOIN = address(this).balance;
        _coin_reserve = totalLiquidityCOIN;
        
        _stakes.manageStake(_msgSender(), totalLiquidityCOIN);

        require(_tokenB.transferFrom(_msgSender(), address(this), token_amount));
        
        _paused=false;
        
        emit PoolCreatedCOIN( totalLiquidityCOIN,_msgSender(),token_amount);
        return totalLiquidityCOIN;
    }
    
    event PoolCreatedTOKEN(uint256 totalLiquidity,address investor,uint256 token_amountA,uint256 token_amountB);
    
    function createPoolTOKEN(uint256 token_amountA,uint256 token_amountB) public returns (uint256) {
        
        require( !_isCOIN,"MP:1");

        require(_tokenA.allowance(_msgSender(),address(this)) >= token_amountA , "!aptk");
        require(_tokenB.allowance(_msgSender(),address(this)) >= token_amountB , "!aptk"); 
        
        require(! _stakes.StakeExist(_msgSender()),"DX:!");    
        
        require(totalLiquidityTOKEN==0,"DEX:i");
        

        totalLiquidityCOIN =0;
        
        totalLiquidityTOKEN = token_amountA;
        
        _coin_reserve = 0;
        
        _stakes.manageStake(_msgSender(), token_amountA);

        require(_tokenA.transferFrom(_msgSender(), address(this), token_amountA));
        require(_tokenB.transferFrom(_msgSender(), address(this), token_amountB));
        
        _paused=false;
        emit PoolCreatedTOKEN( totalLiquidityTOKEN,_msgSender(),token_amountA,token_amountB);
        return totalLiquidityCOIN;
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



    
    function isOverLimit(uint256 amount,bool isTKAorCOIN) public view returns(bool){
        if( getPercImpact( amount, isTKAorCOIN)>10 ){
          return true;  
        } 
        return false;
    }
    
    
    function getPercImpact(uint256 amount,bool isTKAorCOIN) public view returns(uint8){
        
        uint256 reserve=0;
        
        
        if(_isCOIN){
            
            if(isTKAorCOIN){
                reserve=_coin_reserve;
            }else{
                reserve=_tokenB.balanceOf(address(this));
            }
            
            
        }else{
            
            if(isTKAorCOIN){
                reserve=_tokenA.balanceOf(address(this));
            }else{
                reserve=_tokenB.balanceOf(address(this));
            }
            
            
        }

        uint256 p=amount.mul(100)/reserve;
        
        if(p<=100){
            return uint8(p);
        }else{
            return uint8(100);
        }
    }


    function getMaxAmountSwap() public view returns(uint256,uint256){
        
        if(_isCOIN){
            return( _coin_reserve.mul(10)/100 , _tokenB.balanceOf(address(this)).mul(10)/100  );    
        }else{
            return( _tokenA.balanceOf(address(this)).mul(10)/100 , _tokenB.balanceOf(address(this)).mul(10)/100  );    
        }
         
        
    }


    function currentAtoB(uint256 token_amountA) public view returns(uint256){

        if(_isCOIN){

            return price(token_amountA, _coin_reserve, _tokenB.balanceOf(address(this))); 
            
        }
            
        return price(token_amountA, _tokenA.balanceOf(address(this)) , _tokenB.balanceOf(address(this))); 


    }
    

    function currentBtoA(uint256 token_amountB) public view returns(uint256){

        if(_isCOIN){

            return price(token_amountB,  _tokenB.balanceOf(address(this)) ,  _coin_reserve); 

            
        }
            
        return  price(token_amountB,  _tokenB.balanceOf(address(this)) ,  _tokenA.balanceOf(address(this))); 

    }



    struct processRewardInfo {
            uint256 remainder;
            uint256 woopsRewards;
            uint256 dealed;
            address me;
            bool resp;
    }        


    function WithdrawReward(uint256 amount, bool isTKAorCOIN)   public returns(bool){

        require( !isPaused() ,"p");
        
        require(_stakes.StakeExist(_msgSender()),"DX:!");        
        
        _withdrawReward( _msgSender(),  amount, isTKAorCOIN);

        return true;
    }



    function _withdrawReward(address account, uint256 amount , bool isTKAorCOIN)  internal returns(bool){
        
        require( !isPaused() ,"p");
        
        
        
        if(!_stakes.StakeExist(account)){
            return false;
        }
        
        uint256 tka=0;
        uint256 tkb=0;
        
        (tka, tkb) =_stakes.getValues(account );
        
        uint256 remainder = 0;
        
        if(_isCOIN){
            
            if(isTKAorCOIN){
                require(amount <= tka,"DX:1");    
    
                require( amount <= getMyCoinBalance() ,"DX:-c" );        
                
                address(uint160(account)).transfer(amount);
    
                remainder = tka.sub(amount);
                
    
            }else{  //token
                
                require(amount <= tkb,"DX:amew");    
    
                require( amount <= getMyTokensBalance(_erc20B) ,"DX:-tk" );     
                
                require(_tokenB.transfer(account, amount) ,"DX:5");    

                remainder = tkb.sub(amount);
            }

            
        }else{
            
            if(isTKAorCOIN){
                require(amount <= tka,"DX:1");    
                
                require( amount <= getMyTokensBalance(_erc20A) ,"DX:-tk" );     
                
                require(_tokenA.transfer(account, amount) ,"DX:5");    

                remainder = tka.sub(amount);
                
    
            }else{  //token
                
                require(amount <= tkb,"DX:amew");    
    
                require( amount <= getMyTokensBalance(_erc20B) ,"DX:-tk" );     
                
                require(_tokenB.transfer(account, amount) ,"DX:5");    

                remainder = tkb.sub(amount);
            }

        }
        
        
        
        if(remainder==0){
            _stakes.changeToken(account,0, 1,isTKAorCOIN);
            
        }else{
            _stakes.changeToken(account,remainder, 1,isTKAorCOIN);

        }

    }




    function getCalcRewardAmount(address account,  uint256 amount) public view returns(uint256,uint256){
        
    
        
        if(!_stakes.StakeExist(account)) return (0,0);

        uint256 liq=0;
        uint256 part=0;


        (liq,,) = _stakes.getStake(account);

        
        if(liq==0 ) return (0,0);
        
        if(_isCOIN){
            part=liq * amount / totalLiquidityCOIN;
            
        }else{
            
            part=liq * amount / totalLiquidityTOKEN;
            
        }

        
        if(part==0) return (0,0);
        
        uint256 remainder = amount - part;
        
        return (part,remainder);    

    }

    event InsuficientRewardFund(address account,bool isTKAorCOIN);
    event NewLeftover(address account, uint256 leftover,bool isTKAorCOIN);


    function _DealLiquidity( uint256 amount,bool isTKAorCOIN) internal returns(uint256){
        
        processRewardInfo memory slot; slot.dealed=0;
        
        Stake memory p;
        

        uint256 last=_stakes.getLastIndexStakes();

        for (uint256 i = 0; i < (last +1) ; i++) {

            (p.account,p.liq ,p.tokena,p.tokenb ,p.flag)=_stakes.getStakeByIndex(i);
            
            if(p.flag == 1 ){

                (slot.woopsRewards, slot.remainder) = getCalcRewardAmount(p.account, amount );
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





    

    event PurchasedTokens(address purchaser,uint256 coins, uint256 tokens_bought);
    event FeeTokens(uint256 liqPart,uint256 opPart,uint256 crossPart , address operations, address beneficiary, address crossbeneficiary);
    
    function coinToToken() public payable   returns (uint256) {
        
        require(_isCOIN,"MP:1");
        
        require( !isPaused() ,"p");
        
        require(totalLiquidityCOIN>0,"MP:0");
        
        require(!isOverLimit(msg.value,true),'MP:c');
        
        uint256 token_reserve = _tokenB.balanceOf(address(this));
        
        uint256 tokens_bought = price(msg.value, _coin_reserve , token_reserve);
        
        uint256 tokens_bought0fee = planePrice(msg.value, _coin_reserve , token_reserve); 
        
        _coin_reserve=_coin_reserve.add(msg.value);
        
        require( tokens_bought <= getMyTokensBalance(_erc20B) ,"MP:a" );
        
        require(_tokenB.transfer(_msgSender(), tokens_bought) ,"MP:b");
        
        emit PurchasedTokens(_msgSender(),  msg.value,  tokens_bought);
        
        uint256 tokens_fee=tokens_bought0fee - tokens_bought;

        uint256 tokens_opPart;
        uint256 tokens_liqPart;
        uint256 tokens_crPart;
        uint256 tokens_remainder;
        
        ( tokens_remainder, tokens_liqPart , tokens_opPart , tokens_crPart )=calcFees(tokens_fee);        

        if(_isBNBenv){
            require(_tokenB.transferFrom(address(this), _beneficiary, tokens_opPart) ,"MP:2");
        }else{
            require(_tokenB.transferFrom(address(this), _operations, tokens_opPart) ,"MP:3");    
        }

        require(_tokenB.transfer(_crossbeneficiary, tokens_crPart) ,"MP:1");    

        
        processRewardInfo memory slot;
        
        slot.dealed=_DealLiquidity( tokens_liqPart, false);

        emit FeeTokens(tokens_liqPart,tokens_opPart,tokens_crPart ,_operations, _beneficiary, _crossbeneficiary);

        
        if(slot.dealed > tokens_liqPart ){
            return tokens_bought;
        }
        
        uint256 leftover=tokens_liqPart.sub(slot.dealed);
        
        if(leftover > 0){
            require(_tokenB.transfer(_operations, leftover) ,"MP:4");
            emit NewLeftover( _operations, leftover,false);
        }

        return tokens_bought;
    }
    



    function sellTokenB(uint256 tka_amount) public    returns (uint256) {
        
        require(!_isCOIN,"MP:1");
        
        require( !isPaused() ,"p");
        
        require(totalLiquidityTOKEN>0,"MP:0");
        
        require(!isOverLimit(tka_amount,true),'MP:c');
        
        uint256 tokenb_reserve = _tokenB.balanceOf(address(this));
        
        uint256 tokens_bought = price(tka_amount, getMyTokensBalance(_erc20A) , tokenb_reserve);
        
        uint256 tokens_bought0fee = planePrice(tka_amount, getMyTokensBalance(_erc20A) , tokenb_reserve);
        

        require( tokens_bought <= getMyTokensBalance(_erc20B) ,"MP:a" );
        
        require(  _tokenA.allowance(_msgSender(),address(this)) >= tka_amount , "!aptk"); 

        require(_tokenA.transferFrom(_msgSender(), address(this), tka_amount));
        
        require(_tokenB.transfer(_msgSender(), tokens_bought) ,"MP:b");
        
        emit PurchasedTokens(_msgSender(),  tka_amount,  tokens_bought);
        
        uint256 tokens_fee=tokens_bought0fee - tokens_bought;

        uint256 tokens_opPart;
        uint256 tokens_liqPart;
        uint256 tokens_crPart;
        uint256 tokens_remainder;
        
        ( tokens_remainder, tokens_liqPart , tokens_opPart , tokens_crPart )=calcFees(tokens_fee);        

        if(_isBNBenv){
            require(_tokenB.transferFrom(address(this), _beneficiary, tokens_opPart) ,"MP:2");
        }else{
            require(_tokenB.transferFrom(address(this), _operations, tokens_opPart) ,"MP:3");    
        }

        require(_tokenB.transfer(_crossbeneficiary, tokens_crPart) ,"MP:1");    

        processRewardInfo memory slot;
        
        slot.dealed=_DealLiquidity( tokens_liqPart, false);

        emit FeeTokens(tokens_liqPart,tokens_opPart,tokens_crPart,  _operations, _beneficiary, _crossbeneficiary);
        
        if(slot.dealed > tokens_liqPart ){
            return tokens_bought;
        }
        
        uint256 leftover=tokens_liqPart.sub(slot.dealed);
        
        if(leftover > 0){
            require(_tokenB.transfer(_operations, leftover) ,"MP:4");
            emit NewLeftover( _operations, leftover,false);
        }

        return tokens_bought;
    }

    

    event TokensSold(address vendor,uint256 eth_bought,uint256 token_amount);
    event FeeCoins(uint256 liqPart,uint256 opPart,uint256 crPart,address beneficiary , address operations,address crossbeneficiary);
    
    function tokenToCoin(uint256 token_amount)   public returns (uint256) {
        
            require(_isCOIN,"MP:1");
        
            require( !isPaused() ,"p");

            require(  _tokenB.allowance(_msgSender(),address(this)) >= token_amount , "!aptk"); 
            
            require(totalLiquidityCOIN>0,"MP:0");
            
            require(!isOverLimit(token_amount,false),'DX:c');    
            
            uint256 token_reserve = _tokenB.balanceOf(address(this));
            
            uint256 eth_bought = price(token_amount, token_reserve, _coin_reserve ); 
            
            uint256 eth_bought0fee = planePrice(token_amount, token_reserve,  _coin_reserve); 
            
            require( eth_bought <= getMyCoinBalance() ,"DX:!" );
            
            _msgSender().transfer(eth_bought);
            
            _coin_reserve =address(this).balance;    
            
            require(_tokenB.transferFrom(_msgSender(), address(this), token_amount));
            
            emit TokensSold(_msgSender(),eth_bought, token_amount);
            
            uint256 eth_fee=eth_bought0fee - eth_bought;

            uint256 eth_opPart;
            uint256 eth_liqPart;
            uint256 eth_crPart;
            uint256 eth_remainder;

            ( eth_remainder, eth_liqPart , eth_opPart , eth_crPart )=calcFees(eth_fee);
            
            
            if(_isBNBenv){
                address(uint160(_beneficiary)).transfer(eth_opPart);
            }else{
                address(uint160(_operations)).transfer(eth_opPart);
            }

            address(uint160(_crossbeneficiary)).transfer(eth_crPart);

            processRewardInfo memory slot;
            
            slot.dealed=_DealLiquidity( eth_liqPart, true);

            
            emit FeeCoins( eth_liqPart, eth_opPart , eth_crPart , _beneficiary ,  _operations, _crossbeneficiary);
            
            if(slot.dealed > eth_liqPart ){
                return eth_bought;
            }

            uint256 leftover=eth_liqPart.sub(slot.dealed);
            
            if(leftover > 0){
                address(uint160(_operations)).transfer(leftover);
                emit NewLeftover( _operations, leftover,true);
            }
            
            _coin_reserve =address(this).balance;

            return eth_bought;
    }
    
    
    
    


    function sellTokenA(uint256 tokenb_amount)   public returns (uint256) {
        
            require(!_isCOIN,"MP:1");
        
            require( !isPaused() ,"p");

            require(  _tokenB.allowance(_msgSender(),address(this)) >= tokenb_amount , "!aptk"); 
            
            require(totalLiquidityTOKEN>0,"MP:0");
            
            require(!isOverLimit(tokenb_amount,false),'MP:c');    
            
            uint256 tokenb_reserve = _tokenB.balanceOf(address(this));
            
            uint256 tka_bought = price(tokenb_amount, tokenb_reserve, _tokenA.balanceOf(address(this)) ); 
            
            uint256 tka_bought0fee = planePrice(tokenb_amount, tokenb_reserve, _tokenA.balanceOf(address(this)) ); 
            
            require( tka_bought <= getMyTokensBalance(_erc20A) ,"MP:!" );
            
            require(_tokenA.transfer(_msgSender(), tka_bought) ,"MP:b");

            require(_tokenB.transferFrom(_msgSender(), address(this), tokenb_amount),"MP:2");
            
            emit TokensSold(_msgSender(),tka_bought, tokenb_amount);
            
            uint256 tka_fee=tka_bought0fee - tka_bought;

            uint256 tka_opPart;
            uint256 tka_crPart;
            uint256 tka_liqPart;
            uint256 tka_remainder;

            ( tka_remainder, tka_liqPart , tka_opPart , tka_crPart )=calcFees(tka_fee);

            if(_isBNBenv){

                require(_tokenA.transfer(_beneficiary, tka_opPart) ,"MP:c");
                
            }else{

                require(_tokenA.transfer(_operations, tka_opPart) ,"MP:d");
            }

            require(_tokenA.transfer(_crossbeneficiary, tka_crPart) ,"MP:e");


            processRewardInfo memory slot;
            
            slot.dealed=_DealLiquidity( tka_liqPart, true);

            
            emit FeeCoins( tka_liqPart, tka_opPart , tka_crPart , _beneficiary ,  _operations, _crossbeneficiary);
            
            if(slot.dealed > tka_liqPart ){
                return tka_bought;
            }

            uint256 leftover=tka_liqPart.sub(slot.dealed);
            
            if(leftover > 0){
                
                require(_tokenA.transfer(_operations, leftover) ,"MP:f");
                
                emit NewLeftover( _operations, leftover,true);
            }

            return tka_bought;
    }
    
    
    
    
    
    
    

    function calcTokenBToAddLiq(uint256 tokenAorCoinDeposit) public view returns(uint256){
            if(_isCOIN){
                
                return (tokenAorCoinDeposit.mul(_tokenB.balanceOf(address(this))) / _coin_reserve ).add(1); 
                
            }else{
                
                return (tokenAorCoinDeposit.mul(_tokenB.balanceOf(address(this))) / _tokenA.balanceOf(address(this)) ).add(1); 
            }
            
    }

    






    event LiquidityChanged(uint256 oldLiq, uint256 newLiq);
    
    function AddLiquidityCOIN() public payable  returns (uint256) {
        
        require(_isCOIN,"MP:1");
        
        require( !isPaused() ,"p");
        
        uint256 tka_reserve = _coin_reserve;
        
        uint256 tokenB_amount = calcTokenBToAddLiq(msg.value);
        

        require( _msgSender() != address(0) && _tokenB.allowance(_msgSender(),address(this)) >= tokenB_amount   , "MP:1"); 
        
        uint256 liquidityCOIN_minted = msg.value.mul(totalLiquidityCOIN) / tka_reserve;
        
        _coin_reserve=_coin_reserve.add(msg.value);    
        
        _stakes.manageStake(_msgSender(), liquidityCOIN_minted);
        
        uint256 oldLiq=totalLiquidityCOIN;
        
        totalLiquidityCOIN = totalLiquidityCOIN.add(liquidityCOIN_minted);
        
        require(_tokenB.transferFrom(_msgSender(), address(this), tokenB_amount));
        
        emit LiquidityChanged(oldLiq, totalLiquidityCOIN);
        
        return liquidityCOIN_minted;
    }


    function AddLiquidityTOKEN(uint256 tokenA_amount) public   returns (uint256) {
        
        require(!_isCOIN,"MP:1");
        
        require( !isPaused() ,"p");
        
        uint256 tka_reserve = _tokenA.balanceOf(address(this));
        
        uint256 tokenB_amount = calcTokenBToAddLiq(tokenA_amount);

        require( _msgSender() != address(0) && _tokenB.allowance(_msgSender(),address(this)) >= tokenB_amount   , "MP:1"); 
        
        require(  _tokenA.allowance(_msgSender(),address(this)) >= tokenA_amount   , "MP:2"); 
        
        uint256 liquidityTOKEN_minted = tokenA_amount.mul(totalLiquidityTOKEN) / tka_reserve;

        _stakes.manageStake(_msgSender(), liquidityTOKEN_minted);
        
        uint256 oldLiq=totalLiquidityTOKEN;
        
        totalLiquidityTOKEN = totalLiquidityTOKEN.add(liquidityTOKEN_minted);
        
        require(_tokenA.transferFrom(_msgSender(), address(this), tokenA_amount));
        
        require(_tokenB.transferFrom(_msgSender(), address(this), tokenB_amount));
        
        emit LiquidityChanged(oldLiq, totalLiquidityTOKEN);
        
        return liquidityTOKEN_minted;
    }




    function getValuesLiqWithdraw(address investor, uint256 liq) public view returns(uint256, uint256){

        if(!_stakes.StakeExist(investor)){
            return (0,0);
        }
        
       uint256 inv;
       
        (inv,,)=_stakes.getStake(investor);
        
        if(liq>inv){
            return (0,0);
        }
        
        if(_isCOIN){
            uint256 tka_amount = liq.mul(_coin_reserve) / totalLiquidityCOIN;
            uint256 tokenB_amount = liq.mul(_tokenB.balanceOf(address(this))) / totalLiquidityCOIN;
            return(tka_amount,tokenB_amount);
        }else{
            uint256 tka_amount = liq.mul(_tokenA.balanceOf(address(this))) / totalLiquidityTOKEN;
            uint256 tokenB_amount = liq.mul(_tokenB.balanceOf(address(this))) / totalLiquidityTOKEN;
            return(tka_amount,tokenB_amount);
            
        }
    }



    function getMaxValuesLiqWithdraw(address investor) public view  returns(uint256,uint256, uint256){
        
        if(!_stakes.StakeExist(investor)){
            return (0,0,0);
        }
        
        uint256 tokenB_reserve = _tokenB.balanceOf(address(this));

        uint256 tka_amount;
        uint256 tokenB_amount;
        uint256 inv;
       
        (inv,,)=_stakes.getStake(investor);
        
        
        if(_isCOIN){
            tka_amount = inv.mul(_coin_reserve) / totalLiquidityCOIN;
            tokenB_amount = inv.mul(tokenB_reserve) / totalLiquidityCOIN;
            
            
        }else{
            tka_amount = inv.mul( _tokenA.balanceOf(address(this)) ) / totalLiquidityTOKEN;
            tokenB_amount = inv.mul(tokenB_reserve) / totalLiquidityTOKEN;
            
        }
        
        return(inv,tka_amount,tokenB_amount);
    }
    

    event LiquidityWithdraw(address investor,uint256 coins, uint256 token_amount,uint256 newliquidity);
    
    function _withdrawFundsCOIN( address account, uint256 liquid)  internal returns(uint256,uint256){
        
        require(_isCOIN,"MP:1");

        require( _stakes.StakeExist(account),"MP:!");    
        
        uint256 inv_liq;
        
        (inv_liq,,)=_stakes.getStake(account);

        require( liquid <= inv_liq ,"MP:3" );
        
        uint256 tokenB_reserve = _tokenB.balanceOf(address(this));
        
        uint256 tka_amount = liquid.mul(_coin_reserve) / totalLiquidityCOIN;  
        
        uint256 tokenB_amount = liquid.mul(tokenB_reserve) / totalLiquidityCOIN;

        require( tka_amount <= getMyCoinBalance() ,"MP:1" );
        
        require( tokenB_amount <= getMyTokensBalance(_erc20B) ,"MP:2" );

        _stakes.substractFromStake(account, liquid);         

        uint256 oldLiq=totalLiquidityCOIN;
        
        totalLiquidityCOIN = totalLiquidityCOIN.sub(liquid);

        address(uint160(account)).transfer(tka_amount);
        
        _coin_reserve = address(this).balance;

        require(_tokenB.transfer(account, tokenB_amount),"MP:3");    

        emit LiquidityWithdraw(account, tka_amount, tokenB_amount, totalLiquidityCOIN );
        emit LiquidityChanged(oldLiq, totalLiquidityCOIN);
        return (tka_amount, tokenB_amount);
    }
    


    function _withdrawFundsTOKEN( address account, uint256 liquid)  internal returns(uint256,uint256){
        
        require(!_isCOIN,"MP:1");

        require( _stakes.StakeExist(account),"MP:!");    
        
        uint256 inv_liq;
        
        (inv_liq,,)=_stakes.getStake(account);

        require( liquid <= inv_liq ,"MP:3" );
        
        uint256 tokenB_reserve = _tokenB.balanceOf(address(this));
        
        uint256 tka_amount = liquid.mul( _tokenA.balanceOf(address(this))  ) / totalLiquidityTOKEN;  
        
        uint256 tokenB_amount = liquid.mul(tokenB_reserve) / totalLiquidityTOKEN;

        require( tka_amount <= getMyTokensBalance(_erc20A) ,"MP:1" );
        
        require( tokenB_amount <= getMyTokensBalance(_erc20B) ,"MP:2" );

        _stakes.substractFromStake(account, liquid);         

        uint256 oldLiq=totalLiquidityTOKEN;
        
        totalLiquidityTOKEN = totalLiquidityTOKEN.sub(liquid);

        require(_tokenA.transfer(account, tka_amount),"MP:3");    

        require(_tokenB.transfer(account, tokenB_amount),"MP:4");    

        emit LiquidityWithdraw(account, tka_amount, tokenB_amount, totalLiquidityTOKEN );
        emit LiquidityChanged(oldLiq, totalLiquidityTOKEN);
        return (tka_amount, tokenB_amount);
    }

    
    function WithdrawLiquidityCOIN(uint256 liquid) public    returns (uint256, uint256) {
        
        require(_isCOIN,"MP:1");
        
        require( !isPaused() ,"p");
        
        require(totalLiquidityCOIN>0,"MP:0");

        require( _stakes.StakeExist(_msgSender()),"MP:!");    

        return _withdrawFundsCOIN( _msgSender(), liquid);
        
       
    }


    function WithdrawLiquidityTOKEN(uint256 liquid) public    returns (uint256, uint256) {
        
        require(!_isCOIN,"MP:1");
        
        require( !isPaused() ,"p");
        
        require(totalLiquidityTOKEN>0,"MP:0");

        require( _stakes.StakeExist(_msgSender()),"MP:!");    

        return _withdrawFundsTOKEN( _msgSender(), liquid);
        
       
    }



}
