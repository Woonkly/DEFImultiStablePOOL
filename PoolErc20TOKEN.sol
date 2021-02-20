// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/math/SafeMath.sol";
import "https://github.com/Woonkly/DEFImultiStablePOOL/PoolERC20BASE.sol";


contract PoolERC20TOKEN  is PoolERC20BASE {

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

    event PoolCreated(uint256 totalLiquidity,address investor,uint256 token_amountA,uint256 token_amountB);
    
    function createPool(uint256 tokenA_amount,uint256 tokenB_amount) public returns (uint256) {

        require(_tokenA.allowance(_msgSender(),address(this)) >= tokenA_amount , "!aptk");
        require(_tokenB.allowance(_msgSender(),address(this)) >= tokenB_amount , "!aptk"); 
        
        require(! _stakes.StakeExist(_msgSender()),"DX:!");    
        
        require(totalLiquidity==0,"DEX:i");

        totalLiquidity = tokenA_amount;

        _stakes.manageStake(_msgSender(), tokenA_amount);

        require(_tokenA.transferFrom(_msgSender(), address(this), tokenA_amount));
        require(_tokenB.transferFrom(_msgSender(), address(this), tokenB_amount));
        
        _paused=false;
        emit PoolCreated( totalLiquidity,_msgSender(),tokenA_amount,tokenB_amount);
        return totalLiquidity;
    }
    

    event PoolClosed(uint256 tkA_reserve,uint256 tkB_reserve, uint256 liquidity,address destination);    

    function closePool() public onlyIsInOwners  returns(bool){

        uint256 tokenA_reserve = _tokenA.balanceOf(address(this));
        uint256 tokenB_reserve = _tokenB.balanceOf(address(this));

        require(_tokenA.transfer(_operations, tokenA_reserve) ,"MP:1");
        require(_tokenB.transfer(_operations, tokenB_reserve) ,"MP:2");

        uint256 liq=totalLiquidity;
        totalLiquidity=0;

        setPause(true);
        
        emit PoolClosed(tokenA_reserve, tokenB_reserve, liq,_operations);    
        
        return true;
    }

    
    function isOverLimit(uint256 amount,bool isTKA) public view returns(bool){
        if( getPercImpact( amount, isTKA)>10 ){
          return true;  
        } 
        return false;
    }
    
    
    function getPercImpact(uint256 amount,bool isTKA) public view returns(uint8){
        
        uint256 reserve=0;

        if(isTKA){
            reserve=_tokenA.balanceOf(address(this));
        }else{
            reserve=_tokenB.balanceOf(address(this));
        }

        uint256 p=amount.mul(100)/reserve;
        
        if(p<=100){
            return uint8(p);
        }else{
            return uint8(100);
        }
    }


    function getMaxAmountSwap() public view returns(uint256,uint256){
        
        return( _tokenA.balanceOf(address(this)).mul(10)/100 , _tokenB.balanceOf(address(this)).mul(10)/100  );    
    }


    function currentAtoB(uint256 tokenA_amount) public view returns(uint256){

        return price(tokenA_amount, _tokenA.balanceOf(address(this)) , _tokenB.balanceOf(address(this))); 


    }
    

    function currentBtoA(uint256 tokenB_amount) public view returns(uint256){

        return  price(tokenB_amount,  _tokenB.balanceOf(address(this)) ,  _tokenA.balanceOf(address(this))); 

    }



    function WithdrawReward(uint256 amount, bool isTKA)   public returns(bool){

        require( !isPaused() ,"p");
        
        require(_stakes.StakeExist(_msgSender()),"MP:!");        
        
        _withdrawReward( _msgSender(),  amount, isTKA);

        return true;
    }



    function _withdrawReward(address account, uint256 amount , bool isTKA)  internal returns(bool){
        
        require( !isPaused() ,"p");
        
        
        
        if(!_stakes.StakeExist(account)){
            return false;
        }
        
        uint256 tka=0;
        uint256 tkb=0;
        
        (tka, tkb) =_stakes.getValues(account );
        
        uint256 remainder = 0;
        

            
        if(isTKA){
            require(amount <= tka,"MP:1");    
            
            require( amount <= getMyTokensBalance(_erc20A) ,"MP:-tk" );     
            
            require(_tokenA.transfer(account, amount) ,"MP:5");    

            remainder = tka.sub(amount);
            

        }else{  //token
            
            require(amount <= tkb,"MP:amew");    

            require( amount <= getMyTokensBalance(_erc20B) ,"DX:-tk" );     
            
            require(_tokenB.transfer(account, amount) ,"DX:5");    

            remainder = tkb.sub(amount);
        }


        
        if(remainder==0){
            _stakes.changeToken(account,0, 1,isTKA);
            
        }else{
            _stakes.changeToken(account,remainder, 1,isTKA);

        }

    }




    function getCalcRewardAmount(address account,  uint256 amount) public view returns(uint256,uint256){
        
    
        
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



    event PurchasedTokens(address purchaser,uint256 coins, uint256 tokens_bought);
    event FeeTokens(uint256 liqPart,uint256 opPart,uint256 crossPart , address operations, address beneficiary, address crossbeneficiary);
    



    function sellTokenB(uint256 tka_amount) public    returns (uint256) {
        

        
        require( !isPaused() ,"p");
        
        require(totalLiquidity>0,"MP:0");
        
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
        
        slot.dealed=_DealLiquidity( tokens_liqPart, totalLiquidity, false);

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
    

    
    


    function sellTokenA(uint256 tokenb_amount)   public returns (uint256) {
        
            require( !isPaused() ,"p");

            require(  _tokenB.allowance(_msgSender(),address(this)) >= tokenb_amount , "!aptk"); 
            
            require(totalLiquidity>0,"MP:0");
            
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
            
            slot.dealed=_DealLiquidity( tka_liqPart, totalLiquidity, true);

            
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
    
    
    
    
    
    
    

    function calcTokenBToAddLiq(uint256 tokenA) public view returns(uint256){

            return (tokenA.mul(_tokenB.balanceOf(address(this))) / _tokenA.balanceOf(address(this)) ).add(1); 

    }

    






    event LiquidityChanged(uint256 oldLiq, uint256 newLiq);
    
    function AddLiquidity(uint256 tokenA_amount) public   returns (uint256) {
        

        require( !isPaused() ,"p");
        
        uint256 tka_reserve = _tokenA.balanceOf(address(this));
        
        uint256 tokenB_amount = calcTokenBToAddLiq(tokenA_amount);

        require( _msgSender() != address(0) && _tokenB.allowance(_msgSender(),address(this)) >= tokenB_amount   , "MP:1"); 
        
        require(  _tokenA.allowance(_msgSender(),address(this)) >= tokenA_amount   , "MP:2"); 
        
        uint256 liquidity_minted = tokenA_amount.mul(totalLiquidity) / tka_reserve;

        _stakes.manageStake(_msgSender(), liquidity_minted);
        
        uint256 oldLiq=totalLiquidity;
        
        totalLiquidity = totalLiquidity.add(liquidity_minted);
        
        require(_tokenA.transferFrom(_msgSender(), address(this), tokenA_amount));
        
        require(_tokenB.transferFrom(_msgSender(), address(this), tokenB_amount));
        
        emit LiquidityChanged(oldLiq, totalLiquidity);
        
        return liquidity_minted;
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
        
        uint256 tka_amount = liq.mul(_tokenA.balanceOf(address(this))) / totalLiquidity;
        uint256 tokenB_amount = liq.mul(_tokenB.balanceOf(address(this))) / totalLiquidity;
        return(tka_amount,tokenB_amount);
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
        
        
        tka_amount = inv.mul( _tokenA.balanceOf(address(this)) ) / totalLiquidity;
        tokenB_amount = inv.mul(tokenB_reserve) / totalLiquidity;

        return(inv,tka_amount,tokenB_amount);
    }
    

    event LiquidityWithdraw(address investor,uint256 coins, uint256 token_amount,uint256 newliquidity);

    function _withdrawFunds( address account, uint256 liquid)  internal returns(uint256,uint256){

        require( _stakes.StakeExist(account),"MP:!");    
        
        uint256 inv_liq;
        
        (inv_liq,,)=_stakes.getStake(account);

        require( liquid <= inv_liq ,"MP:3" );
        
        uint256 tokenB_reserve = _tokenB.balanceOf(address(this));
        
        uint256 tka_amount = liquid.mul( _tokenA.balanceOf(address(this))  ) / totalLiquidity;  
        
        uint256 tokenB_amount = liquid.mul(tokenB_reserve) / totalLiquidity;

        require( tka_amount <= getMyTokensBalance(_erc20A) ,"MP:1" );
        
        require( tokenB_amount <= getMyTokensBalance(_erc20B) ,"MP:2" );

        _stakes.substractFromStake(account, liquid);         

        uint256 oldLiq=totalLiquidity;
        
        totalLiquidity = totalLiquidity.sub(liquid);

        require(_tokenA.transfer(account, tka_amount),"MP:3");    

        require(_tokenB.transfer(account, tokenB_amount),"MP:4");    

        emit LiquidityWithdraw(account, tka_amount, tokenB_amount, totalLiquidity );
        emit LiquidityChanged(oldLiq, totalLiquidity);
        return (tka_amount, tokenB_amount);
    }

    


    function WithdrawLiquidity(uint256 liquid) public    returns (uint256, uint256) {

        require( !isPaused() ,"p");
        
        require(totalLiquidity>0,"MP:0");

        require( _stakes.StakeExist(_msgSender()),"MP:!");    

        return _withdrawFunds( _msgSender(), liquid);
        
       
    }



}
