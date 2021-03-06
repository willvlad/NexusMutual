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


pragma solidity 0.4.11;
import "./master.sol";
import "./SafeMaths.sol";
contract NXMTokenData {
    using SafeMaths for uint;
    master ms1;
    address masterAddress;
    string public version = 'NXM 0.1';
    bytes8 public name;
    bytes8 public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address owner;
    uint  initialTokens;
    uint public currentFounderTokens;
    uint public memberCounter;
    uint64  bookTime;
    uint64  minVoteLockPeriod;
    uint16 public scValidDays;
    uint public joiningFee;
    address public joiningFeeAddress;

    // Arjun - Data Begin
    struct stakeCommission
    {
        uint commissionAmt;
        uint commissionDate;
    }
    struct stake{
        address stakerAdd;
        address scAddress;
        uint amount;
        uint burnedAmount;
        uint dateAdd;
    }
    // Arjun - Data End
    struct lockToken
    {
        uint validUpto;
        uint amount;
    }
    
    
    struct allocatedTokens{
        address memberAdd;
        uint tokens;
        uint date_add;
        uint blockNumber;
    }

    // Arjun - Data Begin
    // smartContractAddress[] smartContractAddresses;
    mapping (address => uint[]) scAddress_Stake;
    stake[] stakeDetails;
    mapping (address => uint[]) staker_Index;
    mapping (address => mapping(address => mapping(uint => stakeCommission[]))) staker_SC_Commission;
    // Arjun - Data End
    allocatedTokens[] allocatedFounderTokens;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(uint=>lockToken[])) public depositCN_Cover;
    mapping (address => lockToken[])   lockedCA;
    mapping (address => lockToken[])  lockedCN;
    mapping (address => lockToken[])  bookedCA;
    mapping (address => mapping(uint => lockToken)) public lockedCN_Cover;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (bytes4 => uint) public currency_token; 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _of,bytes16 eventName , uint coverId ,uint tokens);
    mapping (address => mapping (uint => lockToken[])) public burnCAToken; 
    mapping (bytes4 => uint) public poolFundValue;
    address[] public allMembers;
    mapping (address => uint) isInallMembers;    
    uint public LockTokenTimeAfterCoverExp;

    function NXMTokenData(
    uint256 initialSupply,
    bytes8 tokenName,
    uint8 decimalUnits,
    bytes8 tokenSymbol
    ) {
        owner = msg.sender;
        initialTokens = 1500000;
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;
        bookTime = SafeMaths.mul64(SafeMaths.mul64(12,60),60);
        minVoteLockPeriod = SafeMaths.mul64(7 , 1 days);     
        LockTokenTimeAfterCoverExp=SafeMaths.mul(35,1 days);  
        // Arjun - Data Begin 
        scValidDays=200;
        joiningFee=2000000000000000; //gwei - 0.002*(10**18)
        // Arjun - Data End             
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
    modifier onlyOwner{
        ms1=master(masterAddress);
        require(ms1.isOwner(msg.sender) == 1);
        _; 
    }
    /// @dev Gets the number of NXM Tokens that are alloted by the creator to the founders.
    function getCurrentFounderTokens() constant returns(uint tokens) 
    {
        tokens = currentFounderTokens;
    }
    /// @dev Gets the minimum time(in milliseconds) for which CA tokens should be locked, in order to participate in claims assessment.
    function getMinVoteLockPeriod() constant returns(uint64 period)
    {
        period = minVoteLockPeriod;
    }
    /// @dev Sets the minimum time(in milliseconds) for which CA tokens should be locked, in order to be used in claims assessment.
    function changeMinVoteLockPeriod(uint64 period) onlyOwner
    {
        minVoteLockPeriod = period;
    } 
    /// @dev Sets the current number of NXM Tokens, allocated to founders.
    function changeCurrentFounderTokens(uint tokens) onlyInternal 
    {
        currentFounderTokens = tokens;
    }
    /// @dev Sets the maximum number of tokens that can be allocated as founder tokens.
    /// @param initTokens number of tokens.
    function changeIntialTokens(uint initTokens) onlyOwner
    {
        if(initTokens>currentFounderTokens)
            initialTokens=initTokens;

    }
    /// @dev Adds the number of tokens received by an address a founder tokens.
    /// @param _to Address of founder member.
    /// @param tokens Number of tokens allocated.
    function addInAllocatedFounderTokens(address _to ,uint  tokens) onlyInternal
    {
        allocatedFounderTokens.push(allocatedTokens(_to , tokens , now , block.number));
    }
    /// @dev Changes the time period up to which tokens will be locked. Used to generate the validity period of tokens booked by a user for participating in claim's assessment/claim's voting.
    function changeBookTime(uint64 _time) onlyOwner
    {
        bookTime = _time;
    }
    /// @dev Gets the time period(in milliseconds) for which a claims assessor's tokens are booked, i.e., cannot be used to caste another vote.
    function getBookTime() constant returns(uint64 _time)
    {
        _time = bookTime;
    }
    /// @dev Gets the total number of tokens (Locked + Unlocked) of a User.
    /// @param _add Address.
    /// @return bal Number of tokens.
    function getBalanceOf(address _add)constant returns(uint bal) 
    {
        bal = balanceOf[_add];
    }
    /// @dev Updates the number to tokens of a user.
    /// @param _of Address.
    /// @param tokens New number of tokens.
    function changeBalanceOf(address _of , uint tokens)  onlyInternal
    {
        balanceOf[_of] = tokens;
    }
    /// @dev Gets total number of NXM tokens that are in circulation.
    function getTotalSupply()constant returns (uint ts)
    {
        ts = totalSupply;
    }
    /// @dev Changes number of NXM tokens that are in circulation.
    function changeTotalSupply(uint tokens) onlyInternal
    {
        totalSupply = tokens;
    }
    /// @dev Allows a given address (Spender) to spend a given amount of the money on behalf of the other user.
    /// @param a1 Allower's address.
    /// @param a2 Spender's address who will be allowed to spend a given no.of tokens on behalf of the owner.
    /// @param value tokens upto which Spender is allowed to transfer.
    function setAllowance(address a1,address a2,uint value) onlyInternal
    {
        allowance[a1][a2] = value;
    }

    /// @dev Gets the no. of tokens a user is allowed to spend on behalf of the other user. 
    /// @param a1 Allower's address who has given the allowance to spend.
    /// @param a2 Spender's address.
    /// @return value tokens upto which Spender is allowed to transfer.
    function getAllowance(address a1 , address a2) constant returns(uint value)
    {
        value = allowance[a1][a2];
    }
    /// @dev Gets number of NXM tokens generated by receiving funding in fiat crypto.
    /// @param curr Currency name.
    /// @return tokens Number of tokens.
    function getCurrencyTokens(bytes4 curr) constant returns(uint tokens)
    {
        tokens = currency_token[curr];
    }
    /// @dev Changes the number of NXM tokens generated by receiving funding in fiat crypto.
    /// @param curr Currency name.
    /// @param tokens Number of tokens.
    function changeCurrencyTokens(bytes4 curr , uint tokens) onlyInternal
    {
        currency_token[curr] = tokens;
    }
    /// @dev Checks if a given address is already an NXM Member or not.
    /// @param _add Address.
    /// @return check 0 not an existing member,1 existing member
    function checkInallMemberArray(address _add) constant returns(uint8 check)
    {
        check = 0;
        if(isInallMembers[_add]==1)
            check=1;
    }
    /// @dev Adds a given address as to the NXM member list.
    function addInAllMemberArray(address _add) onlyInternal
    {
        isInallMembers[_add] = 1;
        allMembers.push(_add);
    }
    /// @dev Increases the count of NXM Members by 1 (called whenever a new Member is added).
    function incMemberCounter() onlyInternal
    {
        memberCounter++;
    }
    /// @dev Decreases the count of NXM Members by 1 (called when a member is removed i.e. NXM tokens of a member is 0).
    function decMemberCounter() onlyInternal
    {
        memberCounter--;
    }
    /// @dev Gets the maximum number of tokens that can be allocated as Founder Tokens
    function getInitialFounderTokens() constant returns(uint tokens)
    {
        tokens = initialTokens;
    }
    /// @dev Gets the total number of NXM members.
    function getAllMembersLength() constant returns(uint len)
    {
        len = allMembers.length;
    }
    /// @dev Gets the address of a member using index.
    function getMember_index(uint i) constant returns(address _add)
    {
        _add = allMembers[i];
    }
     /// @dev Gets the pool fund amount in a given currency.
    function getPoolFundValue(bytes4 curr) constant returns(uint amount)
    {
        amount=poolFundValue[curr];
    }
    /// @dev Sets the amount funded in a pool in a given currency
    function changePoolFundValue(bytes4 curr , uint val) onlyInternal
    {
        poolFundValue[curr] = val;
    }
    /// @dev books the user's tokens for maintaining Assessor Velocity, i.e. once a token is used to cast a vote as a claims assessor, the same token cannot be used to cast another vote before a fixed period of time(in milliseconds)
    /// @param _of user's address.
    /// @param value number of tokens that will be locked for a period of time. 
    function pushBookedCA(address _of ,uint value) onlyInternal
    {
        //bookedCA[_of].push(lockToken(timestamp + forTime , value));
        bookedCA[_of].push(lockToken(SafeMaths.add(now , bookTime) , value));
    }
    /// @dev Gets number of times a user has locked tokens for claim assessment.
    /// @param _of User's address.
    /// @return len number to times
    function getLockCALength(address _of) constant returns (uint len)
    {
        len = lockedCA[_of].length;
    }
    /// @dev Gets the validity date and number of tokens locked under CA at a given index of mapping
    function getLockCAWithIndex(address _of ,uint index) constant returns(uint valid , uint amt)
    {
        valid = lockedCA[_of][index].validUpto;
        amt = lockedCA[_of][index].amount;
    }
    /// @dev Gets number of times a user has locked tokens for claim assessment.
    /// @param _of User's address.
    /// @return len number to times
    function getLockedCALength(address _of) constant returns(uint len)
    {
        len = lockedCA[_of].length;
    }
   /// @dev Gets the validity date and number of tokens locked under CA at a given index of mapping
    function getLockedCA_index(address _of , uint index) constant returns(uint valid ,uint val)
    {
        valid = lockedCA[_of][index].validUpto;
        val = lockedCA[_of][index].amount;
    }
    /// @dev Updates the number of tokens locked for Claims assessment.
    /// @param _of User's address.
    /// @param index index position.
    /// @param value number of tokens.
    function changeLockedCA_Index(address _of , uint index , uint value) onlyInternal
    {
        lockedCA[_of][index].amount = value;
    }
    /// @dev Extends the validity period of tokens locked under claims assessment.
    /// @param _of User's address.
    /// @param index index position.
    /// @param newTimestamp New validity date(timestamp).
    function extendCA(address _of , uint index , uint newTimestamp) onlyInternal
    {
        lockedCA[_of][index].validUpto = newTimestamp;
    }
    /// @dev Gets number of times a user has locked tokens for covers.
    /// @param _of User's address.
    /// @return len number of times tokens has been locked for covers.
    function getLockedCNLength(address _of) constant returns(uint len)
    {
        len = lockedCN[_of].length;
    }
    /// @dev Gets the validity date and number of lock tokens against cover notes of a user at a given index.
    function getLockedCN_index(address _of , uint index) constant returns(uint valid ,uint val)
    {
        valid = lockedCN[_of][index].validUpto;
        val = lockedCN[_of][index].amount;
    }
    /// @dev Updates the number and validity of tokens locked for cover notes by a user using the mapping index.
    /// @param _of User's address.
    /// @param index index position.
    /// @param timestamp New validity date(timestamp).
    /// @param amount1 New number of tokens.
    function updateLockedCN(address _of , uint index ,uint timestamp , uint amount1) onlyInternal
    {
        lockedCN[_of][index].validUpto = timestamp;
        lockedCN[_of][index].amount = amount1;
    }

    /// @dev Gets number of times a user's tokens have been booked for participation in claims assessment.
    /// @param _of User's address.
    /// @return len number to times
    function getBookedCALength(address _of) constant returns(uint len)
    {
        len = bookedCA[_of].length;
    }
    /// @dev Gets the validity date and number of tokens booked for participation in claims assessment, at a given mapping index.
    function getBookedCA_index(address _of , uint index) constant returns(uint valid ,uint val)
    {
        valid = bookedCA[_of][index].validUpto;
        val = bookedCA[_of][index].amount;
    }
    /// @dev Gets the number of times a user has deposit tokens to submit claim of a cover.
    /// @param _of User's address.
    /// @param coverid Cover Id against which tokens are deposit.
    /// @return len Number of times.
    function getDepositCN_CoverLength(address _of , uint coverid) constant returns(uint len)
    {
        len = depositCN_Cover[_of][coverid].length;
    }
    /// @dev Gets the validity and number of tokens deposited by the owner of a cover for Claim Submission.
    /// @param _of user's address.
    /// @param coverid Cover Id.
    /// @param index Index value of mapping.
    /// @return valid Validity Timestamp.
    /// @return val number of tokens to be deposited.
    function getDepositCN_Cover_Index(address _of , uint coverid , uint index) constant returns(uint valid ,uint val)
    {
        valid = depositCN_Cover[_of][coverid][index].validUpto;
        val = depositCN_Cover[_of][coverid][index].amount;
    }
    /// @dev Updates the validity and number of tokens deposited by the owner of a cover for Claim Submission.
    /// @param _of user's address
    /// @param coverid Cover Id.
    /// @param index Index value of mapping.
    /// @param _timestamp New Validity Timestamp of tokens.
    /// @param amount1 New number of tokens to deposit.
    function updateDepositCN_Cover_Index(address _of , uint coverid,uint index,uint _timestamp , uint amount1) onlyInternal
    {
        depositCN_Cover[_of][coverid][index].validUpto = _timestamp;
        depositCN_Cover[_of][coverid][index].amount = amount1;
    }
    /// @dev Gets validity and number of tokens locked against a given cover.
    /// @param _of User's address.
    /// @param coverid Cover id.
    /// @return valid Validity timestamp of locked tokens.
    /// @return val number of locked tokens.
    function getLockedCN_Cover(address _of , uint coverid)constant returns(uint valid ,uint val)
    {
        valid = lockedCN_Cover[_of][coverid].validUpto;
        val = lockedCN_Cover[_of][coverid].amount;
    }
    /// @dev Updates the validity and number of tokens locked against a cover of a user.
    function updateLockedCN_Cover(address _of ,uint coverid, uint timestamp,uint amount1) onlyInternal
    {
        lockedCN_Cover[_of][coverid].validUpto = timestamp;
        lockedCN_Cover[_of][coverid].amount = amount1;
    }
    /// @dev Calculates the Sum of tokens locked for Claim Assessments of a user.
    function getBalanceCAWithAddress(address _to) constant returns (uint sum)
    {
        sum=0;
        for(uint i=0 ; i < lockedCA[_to].length ;i++ )
        {
            if(now<lockedCA[_to][i].validUpto)
                sum=SafeMaths.add(sum,lockedCA[_to][i].amount);
        }
    } 
    /// @dev Calculates the Sum of tokens locked for Cover Note of a user.(available + unavailable)
    function getBalanceCN(address _to) constant returns (uint sum)
    {
        sum=0;
        for(uint i=0 ; i < lockedCN[_to].length ;i++ )
        {
            if(now<lockedCN[_to][i].validUpto)
                sum=SafeMaths.add(sum,lockedCN[_to][i].amount);
        } 
       
    } 
   
    /// @dev Calculates the sum of tokens booked by a user for Claim Assessment.
    function getBookedCA(address _to) constant returns (uint sum)
    {
        sum=0;
        for(uint i=0 ; i < bookedCA[_to].length ;i++ )
        {
            if(now<bookedCA[_to][i].validUpto)
                sum=SafeMaths.add(sum,bookedCA[_to][i].amount);
        }
    }  
    
    /// @dev Calculates the total number of tokens deposited in a cover by a user.
    /// @param coverId cover id.
    /// @param _of user's address.
    /// @return sum total number of tokens deposited in a cover by a user.
    function getDepositCN(uint coverId , address _of) constant returns (uint sum)
    {
        sum=0;
        for(uint i=0 ; i < depositCN_Cover[_of][coverId].length ;i++ )
        {
            if(now<depositCN_Cover[_of][coverId][i].validUpto)
                sum=SafeMaths.add(sum,depositCN_Cover[_of][coverId][i].amount);
        }
    } 
    /// @dev Calculates the remaining number of locked tokens that are not deposit for claim submission (can be used in deposit) by a user of a cover. 
    function getBalanceLockedTokens(uint coverId , address _of) constant returns(uint amt)
    {
        uint lockedTokens=0;
        if(lockedCN_Cover[_of][coverId].validUpto > uint64(now))
            lockedTokens = lockedCN_Cover[_of][coverId].amount;
        amt = SafeMaths.sub(lockedTokens , getDepositCN(coverId , _of));
    }

    
    /// @dev Adds details of tokens that are locked for Claim Assessments by a user.
    /// @param _of User's address.
    /// @param _timestamp Validity of tokens.
    /// @param _value number of tokens lock.
    function lockCA(address _of , uint _timestamp ,uint _value) onlyInternal
    {
        lockedCA[_of].push(lockToken(_timestamp,_value));
    }
    
    /// @dev Adds details of tokens that are locked against a given cover by a user.
    /// @param _of User's address.
    /// @param coverid Cover Id.
    /// @param _timestamp Validity of tokens.
    /// @param amount number of tokens lock.
    function pushInLockedCN_Cover(address _of ,uint coverid , uint _timestamp , uint amount) onlyInternal
    {
        lockedCN[_of].push(lockToken(_timestamp,amount));
        lockedCN_Cover[_of][coverid]=lockToken(_timestamp,amount);
    }
    /// @dev Adds details of tokens that are burned against a given claim of a user.
    /// @param _of User's address.
    /// @param claimid Claim Id.
    /// @param timestamp Validity of tokens.
    /// @param amount number of tokens burnt.
    function pushInBurnCAToken(address _of , uint claimid, uint timestamp , uint amount) onlyInternal
    {
        burnCAToken[_of][claimid].push(lockToken(timestamp , amount));
    }
    /// @dev Adds details of tokens that are Booked for Claim Assessment by a user.
    /// @param _of User's address.
    /// @param _timestamp Validity of tokens.
    /// @param value number of tokens booked.
    function pushInBookedCA(address _of , uint _timestamp ,uint value) onlyInternal
    {
        bookedCA[_of].push(lockToken(_timestamp , value));
    }
    /// @dev Adds details of tokens that are deposit against a given cover by a user for submission of claim.
    /// @param _of User's address.
    /// @param coverid Cover Id.
    /// @param timestamp Validity of tokens.
    /// @param amount1 number of tokens deposited.
    function pushInDepositCN_Cover(address _of , uint coverid , uint timestamp , uint amount1) onlyInternal
    {
        depositCN_Cover[_of][coverid].push(lockToken(timestamp , amount1));
    }
    /// @dev Locked Token after Cover Expired for given time.
    function setLockTokenTimeAfterCoverExp(uint time) onlyInternal{
        LockTokenTimeAfterCoverExp=time;
    }

    // Arjun - Data Begin
    function addStake(address _of,address _scAddress, uint _amount) onlyInternal
    {
        stakeDetails.push(stake(_of,_scAddress,_amount,0,now));
        scAddress_Stake[_scAddress].push(stakeDetails.length-1);
        staker_Index[_of].push(stakeDetails.length-1);
    }
    function getStakeDetails(uint _index) constant returns(uint _indx,address _stakerAdd, address _scAddress,uint _amount,uint _burnedAmount, uint _dateAdd)
    {
        _indx=_index;
        _stakerAdd=stakeDetails[_index].stakerAdd;
        _scAddress=stakeDetails[_index].scAddress;
        _amount=stakeDetails[_index].amount;
        _burnedAmount=stakeDetails[_index].burnedAmount;
        _dateAdd=stakeDetails[_index].dateAdd;
    }
    function updateBurnedAmount(uint _index,uint _burnedAmount) onlyInternal
    {
        stakeDetails[_index].burnedAmount=SafeMaths.add(stakeDetails[_index].burnedAmount,_burnedAmount);
    }
    function pushStakeCommissions(address _of, address _scAddress, uint _stakerIndx, uint _commissionAmt,uint _commissionDate) onlyInternal
    {
        staker_SC_Commission[_of][_scAddress][_stakerIndx].push(stakeCommission(_commissionAmt,_commissionDate));
    }
    
    function getStakeCommission(address _of, address _scAddress, uint _stakerIndx,uint _index) constant returns(uint indx, uint stakerIndex,uint commissionAmt,uint commissionDate)
    {
        indx=_index;
        stakerIndex=_stakerIndx;
        commissionAmt = staker_SC_Commission[_of][_scAddress][_stakerIndx][_index].commissionAmt;
        commissionDate = staker_SC_Commission[_of][_scAddress][_stakerIndx][_index].commissionDate;
    }
    function getStakeCommissionLength(address _of, address _scAddress, uint _stakerIndx) constant returns(uint _length)
    {
         _length=staker_SC_Commission[_of][_scAddress][_stakerIndx].length;
    }
    
    function getTotalStakeCommission(address _of, address _scAddress, uint _stakerIndx) constant returns(uint stakerIndex,uint commissionAmt)
    {
        commissionAmt=0;
        stakerIndex=_stakerIndx;
        for(uint i=0; i<staker_SC_Commission[_of][_scAddress][_stakerIndx].length;i++){
            commissionAmt=SafeMaths.add(commissionAmt,staker_SC_Commission[_of][_scAddress][_stakerIndx][i].commissionAmt);
        }
    }
    function getTotalStakedAmtAgaintScAddress(address _scAddress) constant returns(uint _totalStakeAmt)
    {
        _totalStakeAmt=0;
        for(uint i=0; i<scAddress_Stake[_scAddress].length;i++){
            _totalStakeAmt=SafeMaths.add(_totalStakeAmt,stakeDetails[scAddress_Stake[_scAddress][i]].amount);
        }
    }
    function getTotalStakerAgainstScAddress(address _scAddress) constant returns(uint){
        return scAddress_Stake[_scAddress].length;
    }
    function getScAddressIndexByScAddressAndIndex(address _scAddress,uint _index) constant returns(uint _indx, uint _scAddressIndx){
        _indx=_index;
        _scAddressIndx= scAddress_Stake[_scAddress][_index];
    }
    function getTotalScAddressesAgainstStaker(address _of) constant returns(uint){
        return staker_Index[_of].length;
    }
    function getStakerIndexByStakerAddAndIndex(address _of,uint _index) constant returns(uint _indx, uint _stakerIndx){
        _indx=_index;
        _stakerIndx= staker_Index[_of][_index];
    }
    function getTotalStakedAmtByStakerAgainstScAddress(address _of,address _scAddress) constant returns(uint _totalStakedAmt)
    {
        _totalStakedAmt=0;
        for(uint i=0; i<staker_Index[_of].length;i++){
            if(stakeDetails[staker_Index[_of][i]].scAddress==_scAddress)
            _totalStakedAmt=SafeMaths.add(_totalStakedAmt,stakeDetails[staker_Index[_of][i]].amount);
        }
    }
    function changeSCValidDays(uint16 _days) onlyInternal
    {
        scValidDays=_days;
    }
    function setJoiningfee(uint val)onlyInternal
    {
       joiningFee=val;
    }
    function setJoiningFeeAddress(address _add) onlyInternal{
        joiningFeeAddress=_add;
    }
    // Arjun - Data End
}
