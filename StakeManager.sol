// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/math/SafeMath.sol";
import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/token/ERC20/ERC20.sol";
import "https://github.com/Woonkly/MartinHSolUtils/Utils.sol";

import "https://github.com/Woonkly/MartinHSolUtils/Owners.sol";


contract StakeManager   is Owners,ERC20{

 using SafeMath for uint256;

    struct Stake {
    address account;
    uint256 reward;
    uint256 pending;
    uint8 flag; //0 no exist  1 exist 2 deleted
    
  }

  // las index of 
  uint256 internal _lastIndexStakes;
  // store new  by internal  id (_lastIndexStakes)
  mapping(uint256 => Stake) internal _Stakes;    
  // store address  -> internal  id (_lastIndexStakes)
  mapping(address => uint256) internal _IDStakesIndex;    
 uint256 internal _StakeCount;

 

constructor (string memory name, string memory symbol)  ERC20(name,symbol) public {
    
      _lastIndexStakes = 0;
       _StakeCount = 0;

    }    
    
    
 function _beforeTokenTransfer(address from, address to, uint256 amount) internal override virtual { 

        if(from != address(0) &&  to != address(0)   &&  !StakeExist(to) && amount>0 ){
            _newStake(to,0 );
        }

}
    
    
    function manageStake(address account, uint256 amount)   public onlyIsInOwners returns(bool){

        if(!StakeExist(account)){
            //NEW
            newStake(account, amount );
        }else{
            //has funds
            addToStake(account, amount);
        }
        
        return true;
        
    }
    


    function getStakeCount() public view returns (uint256) {
        return _StakeCount;
    }
    
    function getLastIndexStakes() public view returns (uint256) {
        return _lastIndexStakes;
    }

    
    


    function StakeExist(address account) public view returns (bool) {
        return _StakeExist( _IDStakesIndex[account]);
    }

    function StakeIndexExist(uint256 index) public view returns (bool) {
        
        if(_StakeCount==0) return false;
        
        if(index <  (_lastIndexStakes + 1) ) return true;
        
        return false;
    }


    function _StakeExist(uint256 StakeID)internal view returns (bool) {
        
        //0 no exist  1 exist 2 deleted
        if(_Stakes[StakeID].flag == 1 ){ 
            return true;
        }
        return false;         
    }


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
  
  
  
  
  event addNewStake(address account,uint256 amount);

 function _newStake(address account,uint256 amount ) internal onlyNewStake(account) returns (uint256){
    _lastIndexStakes=_lastIndexStakes.add(1);
    _StakeCount=  _StakeCount.add(1);
    
    _Stakes[_lastIndexStakes].account = account;
    _Stakes[_lastIndexStakes].reward=0;
    _Stakes[_lastIndexStakes].pending=0;
    _Stakes[_lastIndexStakes].flag = 1;
    
    _IDStakesIndex[account] = _lastIndexStakes;

    if(amount>0){
        _mint(account,  amount);        
    }
    
    emit addNewStake(account,amount);
    return _lastIndexStakes;
}    


    
     
 function newStake(address account,uint256 amount ) public onlyIsInOwners onlyNewStake(account) returns (uint256){
     return _newStake( account,amount );
     /*
    _lastIndexStakes=_lastIndexStakes.add(1);
    _StakeCount=  _StakeCount.add(1);
    
    _Stakes[_lastIndexStakes].account = account;
    _Stakes[_lastIndexStakes].reward=0;
    _Stakes[_lastIndexStakes].pending=0;
    _Stakes[_lastIndexStakes].flag = 1;
    
    _IDStakesIndex[account] = _lastIndexStakes;

    if(amount>0){
        _mint(account,  amount);        
    }
    
    emit addNewStake(account,amount);
    return _lastIndexStakes;
    
    */
}    


event StakeAdded(address account, uint256 oldAmount,uint256 newAmount);

function addToStake(address account, uint256 addAmount) public onlyIsInOwners onlyStakeExist(account) returns(uint256){

    uint256 oldAmount = balanceOf(account);    
    if(addAmount>0){
        _mint(account,  addAmount);    
    }
    

    emit StakeAdded( account, oldAmount, addAmount );
    
    return _IDStakesIndex[account];
}   




event StakeReNewed(address account, uint256 oldAmount,uint256 newAmount);

function renewStake(address account, uint256 newAmount) public onlyIsInOwners onlyStakeExist(account) returns(uint256){

    uint256 oldAmount = balanceOf(account);    
    if(oldAmount>0){
        _burn( account,oldAmount);    
    }
    
    if(newAmount>0){
        _mint(account,  newAmount);        
    }
    

    emit StakeReNewed( account, oldAmount, newAmount);
    
    return _IDStakesIndex[account];
}   




event RewaredChanged(address account,uint256 amount,uint8 set);
function changeReward(address account,uint256 amount,uint8 set) public onlyIsInOwners onlyStakeExist(account) returns(bool){
    

        
        if(set==1){
            _Stakes[ _IDStakesIndex[account] ].reward=amount;
        }
        
        if(set==2){
            _Stakes[ _IDStakesIndex[account] ].reward=_Stakes[ _IDStakesIndex[account] ].reward.add(amount);    
        }
        
        if(set==3){
            _Stakes[ _IDStakesIndex[account] ].reward=_Stakes[ _IDStakesIndex[account] ].reward.sub(amount);    
        }
        
        

    emit RewaredChanged( account, amount,set);
}


event PendingChanged(address account,uint256 amount,uint8 set);
function changePending(address account,uint256 amount,uint8 set) public onlyIsInOwners onlyStakeExist(account) returns(bool){
    

        
        if(set==1){
            _Stakes[ _IDStakesIndex[account] ].pending=amount;
        }
        
        if(set==2){
            _Stakes[ _IDStakesIndex[account] ].pending=_Stakes[ _IDStakesIndex[account] ].pending.add(amount);    
        }
        
        if(set==3){
            _Stakes[ _IDStakesIndex[account] ].pending=_Stakes[ _IDStakesIndex[account] ].pending.sub(amount);    
        }
        
        

    emit PendingChanged( account, amount,set);
}






event StakeRemoved(address account);

function removeStake(address account) public onlyIsInOwners onlyStakeExist(account) {
    _Stakes[ _IDStakesIndex[account] ].flag = 2;
    _Stakes[ _IDStakesIndex[account] ].account=address(0);
    _Stakes[ _IDStakesIndex[account] ].reward=0;
    _Stakes[ _IDStakesIndex[account] ].pending=0;
    uint256 bl=balanceOf(account);
    if(bl>0){
        _burn( account,bl);    
    }
    
    _StakeCount=  _StakeCount.sub(1);
    emit StakeRemoved( account);
}

event StakeSubstracted(address account, uint256 oldAmount,uint256 subAmount, uint256 newAmount);

function substractFromStake(address account, uint256 subAmount) public onlyIsInOwners onlyStakeExist(account) returns(uint256){

    uint256 oldAmount = balanceOf(account);    
    
    if(oldAmount==0){
        return _IDStakesIndex[account];
    }
    
    require(subAmount <= oldAmount,"SM invalid amount ");

    _burn( account,subAmount);    

    
    emit StakeSubstracted( account, oldAmount, subAmount,balanceOf(account) );
    
    return _IDStakesIndex[account];
}   




function getValues(address account )public view returns(uint256,uint256){
    if(!StakeExist( account)) return (0,0);
    
    Stake memory p= _Stakes[ _IDStakesIndex[account] ];
    
    return (p.reward,p.pending) ;
}




 function getStake(address account) public view returns( uint256 ,uint256,uint256) {
     
        if(!StakeExist( account)) return (0,0,0);
     
        Stake memory p= _Stakes[ _IDStakesIndex[account] ];
         
        return (balanceOf(account)  ,p.reward,p.pending );
    }



function getStakeByIndex(uint256 index) public view  returns(address, uint256 ,uint256,uint256,uint8) {

        if(!StakeIndexExist( index)) return (address(0), 0,0,0,0);
     
        Stake memory p= _Stakes[ index ];
         
        return (p.account,  balanceOf(p.account)  ,p.reward,p.pending, p.flag);
        
    }



function getAllStake() public view returns(uint256[] memory, address[] memory ,uint256[] memory , uint256[] memory,uint256[] memory) {
  
    uint256[] memory indexs=new uint256[](_StakeCount);
    address[] memory pACCs=new address[](_StakeCount);
    uint256[] memory pAmounts=new uint256[](_StakeCount);
    uint256[] memory pREW=new uint256[](_StakeCount);
    uint256[] memory pPEND=new uint256[](_StakeCount);

    uint256 ind=0;
    
    for (uint32 i = 0; i < (_lastIndexStakes +1) ; i++) {
        Stake memory p= _Stakes[ i ];
        if(p.flag == 1 ){
            indexs[ind]=i;
            pACCs[ind]=p.account;
            pAmounts[ind]=balanceOf(p.account);
            pREW[ind]=p.reward;
            pPEND[ind]=p.pending;
            ind++;
        }
    }

    return (indexs, pACCs, pAmounts,pREW,pPEND);

}

event AllStakeRemoved();
function removeAllStake() public onlyIsInOwners returns(bool){
    for (uint32 i = 0; i < (_lastIndexStakes +1) ; i++) {
        _IDStakesIndex[_Stakes[ i ].account] = 0;
        
        address acc=_Stakes[ i ].account;
        _Stakes[ i ].flag=0;
        _Stakes[ i ].account=address(0);
        _Stakes[ i ].reward=0;
        _Stakes[ i ].pending=0;
        uint256 bl=balanceOf(acc);
        if(bl>0){
            _burn( acc,bl);    
        }
        
        
    }
    _lastIndexStakes = 0;
    _StakeCount = 0;
    emit AllStakeRemoved();
    return true;
}
  



    
}