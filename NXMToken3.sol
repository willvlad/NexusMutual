/* Copyright (C) 2017 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */



// This contract is now deprecated, merged with NXMToken and NXMToken1
// due to increase in gas limits

pragma solidity ^0.4.8;
import "./quotation.sol";
import "./NXMTokenData.sol";
import "./master.sol";
import "./MCR.sol";
import "./pool.sol";
contract NXMToken3 
{

    master ms1;
    address masterAddress;
    address quotationContact;  
     address mcrAddress;
    pool p1;
    address poolAddress;
    address tokenDataAddress;   
    quotation q1;    

    NXMTokenData td1;
     MCR m1;


    function changePoolAddress(address _add) onlyInternal
    {
        poolAddress = _add;
    }

    function changeMasterAddress(address _add)
    {
       if(masterAddress == 0x000)
            masterAddress = _add;
        else
        {
            ms1=master(masterAddress);
            if(ms1.isInternal(msg.sender) == 1)
                masterAddress = _add;
            else
                throw;
        }
    }
    modifier onlyInternal {
        ms1=master(masterAddress);
        require(ms1.isInternal(msg.sender) == 1);
        _; 
    }
   
     function changeQuoteAddress(address conad) onlyInternal
    {
        quotationContact=conad;
       
    }
  
  function changeMCRAddress(address _add) onlyInternal
    {
        mcrAddress = _add;
        m1=MCR(mcrAddress);
    }
    function changeTokenDataAddress(address _add) onlyInternal
    {
        tokenDataAddress = _add;
        td1 = NXMTokenData(tokenDataAddress);
    }
    /// @dev Calculates the surplus distribution weight of an NXM member. 
    /// @param _add User's address.
    /// @return weight Weight represents the proportion of surplus distribution a member should receive
    function calIndWeightForSD(address _add)  constant returns(uint weight)  
    {
        td1=NXMTokenData(tokenDataAddress);
        weight =0;
        if(td1.checkInallMemberArray(_add)==1)
        {
            //Get number of tokens locked for SD
            uint len1 = td1.getLockedSDLength(_add);
            uint vUpto;
            uint amount;
            for(uint j=0;j<len1;j++)
            {
                (vUpto,amount) = td1.getLockedSD_index(_add,j);
                if(vUpto > now)
                {
                    //Calculate weight based on number of tokens locked under SD and the time period for which they are valid
                    weight =weight + ((vUpto - now)*amount)/1 days;
                }
            }
        }
    }
   
    /// @dev Extends validity period of a given number of tokens locked for claims assessment.
    /// @param index  index of exisiting bond.
    /// @param _days number of days for which tokens will be extended.
    /// @param noOfTokens Number of tokens that will get extended. Should be less than or equal to the no.of tokens of selected bond.
    function extendCA(uint index , uint _days ,uint noOfTokens)
    {
        td1=NXMTokenData(tokenDataAddress);
        uint vUpto;
        uint amount;
        (vUpto,amount) = td1.getLockedCA_index(msg.sender,index);
        if(vUpto < now || amount < noOfTokens )throw;
        td1.changeLockedCA_Index(msg.sender,index,amount-noOfTokens);
        td1.lockCA(msg.sender,vUpto + (_days* 1 days ),noOfTokens);
               
    }
    /// @dev Unlocks tokens deposited against a cover.Changes the validity timestamp of deposit tokens.
    /// @dev In order to submit a claim,20% tokens are deposited by the owner. In case a claim is escalated, another 20% tokens are deposited.
    /// @param coverid Cover Id.
    /// @param all 0 in case we want only 1 undeposit against a cover,1 in order to undeposit all deposits against a cover
    function undepositCN(uint coverid, uint all) onlyInternal
    {   
        td1=NXMTokenData(tokenDataAddress);
        q1=quotation(quotationContact);
        address _to=q1.getMemberAddress(coverid);
        if (td1.getDepositCN(coverid , _to) < 0) throw;           // Check if the cover has tokens
        uint len = td1.getDepositCN_CoverLength(_to,coverid);
        uint vUpto;
        uint amount;
       for(uint i=0;i<len;i++)
       {
           (vUpto,amount) = td1.getDepositCN_Cover_Index(_to,coverid,i);
            if(vUpto>=now)
            {
                td1.updateDepositCN_Cover_Index(_to,coverid,i,now,amount);
                if(all==0)
                    break;
            }

       }
    }
  /// @dev Calculates the number of tokens to be distributed in a Surplus Distribution  
  function calSurplusDistributionValue() constant returns(uint finalValue)
    {
        p1=pool(poolAddress);
        td1=NXMTokenData(tokenDataAddress);
        m1=MCR(mcrAddress);
        uint val1;
        uint val2;
        uint val3;
        uint totalTokens = 0;
        uint toDistributeValue;
        uint len = td1.getAllMembersLength();
        for(uint i=0;i<len;i++)
        {
            address _add = td1.getMember_index(i);
            if(td1.checkInallMemberArray(_add)==1)
            {
                uint len1 = td1.getLockedSDLength(_add);
                uint vUpto;
                uint amount;
                for(uint j=0;j<len1;j++)
                {
                    (vUpto,amount) = td1.getLockedSD_index(_add,j);
                    if(vUpto > now)
                        totalTokens +=amount;
                }
            }
        }
        //val1 = 0.1 ETH per locked Token
        val1 = totalTokens/10;
        //val2=5% of last MCR Eth
        val2 = ((5*m1.getLastMCREtherFull())/100)*10000000000000000;
        //val3=50% of Total ETH in pool
        val3=(50*p1.getEtherPoolBalance())/100;

        if(val1 <= val2 && val1 <= val3)
            toDistributeValue = val1;
        else if(val2 <= val1 && val2 <= val3)
            toDistributeValue = val2;
        else if(val3 <= val1 && val3 <= val2)
            toDistributeValue = val3;

        finalValue = toDistributeValue;
    }
    /// @dev Locks a given number of tokens for Claim Assessment.
    /// @param _value number of tokens lock.
    /// @param _days Validity(in days) of tokens.
    function lockCA(uint _value,uint _days)
    {
        td1 = NXMTokenData(tokenDataAddress);
        if (td1.getBalanceOf(msg.sender)-td1.getBalanceCAWithAddress(msg.sender)-td1.getBalanceSD(msg.sender)-td1.getBalanceCN(msg.sender) < _value) throw;// Check if the sender has enough
        if (_value<=0) throw;
        td1.lockCA(msg.sender,now+_days*1 days,_value);        
    }
    /// @dev Locks a given number of tokens for Surplus Distribution.
    /// @param _value number of tokens lock.
    /// @param _days Validity(in days) of tokens.
    function lockSD(uint _value,uint _days)
    {
        td1 = NXMTokenData(tokenDataAddress);
        if (td1.getBalanceOf(msg.sender)-td1.getBalanceCAWithAddress(msg.sender)-td1.getBalanceSD(msg.sender)-td1.getBalanceCN(msg.sender) < _value) throw;  // Check if the sender has enough
        if (_value<=0) throw;
        td1.lockSD(msg.sender,now+_days*1 days,_value);        
        
    }
    
    /// @dev Extends the lock period of member tokens, as a punishment, if a user's decision is against of final decision of claim.
    /// @dev _to User's address
    /// @dev _days Extended no. of days.
    /// @dev token Number of tokens that will get extended.
    function lockSDWithAddress(address _to , uint _days , uint tokens) onlyInternal
    {
        td1 = NXMTokenData(tokenDataAddress);
        uint sum=0;
        tokens = tokens * 10000000000;
        uint len = td1.getLockedSDLength(_to);
        uint vUpto;
        uint amount;
        for(uint i=0 ; i < len ;i++ )
        {
            (vUpto,amount) = td1.getLockedSD_index(_to,i);
            if( now + 3*1 days < vUpto )
                sum+=amount;
        }
        if(sum<tokens)
        {
            uint tokensToLock = tokens-sum;
            uint availableTokens = td1.getBalanceOf(_to)-td1.getBalanceCAWithAddress(_to)-td1.getBalanceSD(_to)-td1.getBalanceCN(_to) ;
            if(availableTokens >= tokensToLock)
            {
                td1.lockSD(_to,now+_days*1 days,tokensToLock);
            }
            else if(availableTokens > 0)
            {
                td1.lockSD(_to,now+_days*1 days,availableTokens);
            }
        }
    }
   
  
    

}

