pragma solidity ^0.5.0;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Context {
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//Master contract
contract PixelPool is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    IERC20 public target;//Nuts token地址
    address governance;//项目方账户地址
    struct UserInfo {
        uint256 amount;//质押的数量
        uint256 userRewardPerTokenPaid;//已支付给用户的单个token收益
        uint256 rewards;//质押的收益
    }
    //pool info
    struct PoolInfo {
        IERC20 lpToken;//lp token地址
        uint256 initReward;//初始化奖池大小
        uint256 startTime;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 totalSupply;
        uint256 rate;//initial rate
        uint256 rateStep;//period rate changing step
        uint256 rateEnd;//last rate ratio
        uint256 decimals;
        uint256 currentEpoch;
        uint256 endTime;
    }

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => uint256) public durationList;
    mapping(uint256 => uint256) public allocPoint;
    mapping(uint256 => uint256) public totalRewardList;
    // Info of each pool.
    mapping(uint256 => PoolInfo) public poolInfo;

    //初始化Nuts token地址
    constructor(
        IERC20 _target
    ) public {
        target = _target;
    }

    event RewardAdded(uint256 indexed pid, uint256 reward);
    event Staked(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 indexed pid, uint256 reward);

    //添加池子
    function add(uint256 _pid, address _lpToken, uint256 _decimals, uint256 _startTime, uint256 _allocPoint,
        uint256 _initReward, uint256 _duration, uint256 _rateBegin, uint256 _rateStep, uint256 _rateEnd) external
    onlyOwner {
        // 池子id幂等
        require(poolInfo[_pid].startTime == 0, "pool already added");
        require(_allocPoint > 0, "AllocPoint must more than 0");
        require(_initReward > 0, "Initial reward must more than 0");
        require(_duration > 0, "Duration must greater than 0");
        require(_decimals > 0, "Decimals must greater than 0");
        require(_allocPoint >= _initReward, "AllocPoint must greater than or equal to initial reward");

        if (_rateStep > 0) {
            require(_rateBegin < _rateEnd, "rateBegin must less then rateEnd");
        }
        //挖矿开始时间，当前区块时间戳大于指定的开始时间，则以当前区块时间戳为开始时间
        uint256 startTime = block.timestamp > _startTime ? block.timestamp : _startTime;
        //挖矿结束时间
        uint256 periodFinish = startTime.add(_duration);
        uint256 endTime = _allocPoint == _initReward ? periodFinish : 0;//if _allocPoint equals _initReward, then endtime should be periodFinish
        //矿池信息
        poolInfo[_pid] = PoolInfo({
        lpToken : IERC20(_lpToken),
        //矿池初始奖励池大小
        initReward : _initReward,
        startTime : startTime,
        periodFinish : periodFinish,
        //单位时间挖矿总收益
        rewardRate : _initReward.div(_duration),
        lastUpdateTime : startTime,
        //矿池当前单个质押的token的挖矿总收益
        rewardPerTokenStored : 0,
        //矿池总质押
        totalSupply : 0,
        rate : _rateBegin,
        rateStep : _rateStep,
        rateEnd : _rateEnd,
        decimals : _decimals,
        //挖矿阶段标识
        currentEpoch : 1,
        endTime : endTime
        });
        durationList[_pid] = _duration;
        //矿池奖励池大小阈值
        allocPoint[_pid] = _allocPoint;
        totalRewardList[_pid] = _initReward;
        emit RewardAdded(_pid, _initReward);
    }

    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner checkExists(_pid) {
        require(_allocPoint > 0, "Cannot allocPoint 0");
        allocPoint[_pid] = _allocPoint;
    }
    function setGovernance(address _governance) public onlyOwner{
        governance = _governance;
    }

    //质押，用户可以质押lp来挖Nuts
    function stake(uint256 _pid, uint256 amount) public checkExists(_pid) checkStart(_pid) updateReward(_pid, msg.sender) checkhalve(_pid)
    {
        require(amount > 0, "Cannot stake 0");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.totalSupply = pool.totalSupply.add(amount);
        user.amount = user.amount.add(amount);
        pool.lpToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, _pid, amount);
    }
    //解质押lp
    function withdraw(uint256 _pid, uint256 amount) public checkExists(_pid) checkStart(_pid) updateReward(_pid, msg.sender) checkhalve(_pid)  {
        require(amount > 0, "Cannot withdraw 0");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.totalSupply = pool.totalSupply.sub(amount);
        user.amount = user.amount.sub(amount);
        pool.lpToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, _pid, amount);
    }
    //退出挖矿，解质押lp并提取挖矿收益
    function exit(uint256 _pid) external checkExists(_pid) {
        //解质押lp
        withdraw(_pid, userInfo[_pid][msg.sender].amount);
        //提取挖矿收益
        getReward(_pid);
    }
    //获取用户挖矿总收益
    function earned(uint256 _pid, address account) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][account];
        uint256 calculatedEarned = user.amount
        .mul(rewardPerToken(_pid).sub(user.userRewardPerTokenPaid))//当前单个质押的token的挖矿总收益减去已支付给用户的单个token的收益，即为单个token还应支付给用户的收益
        .div(10 ** pool.decimals)
        .add(user.rewards);
        // avoid over allocPoint
        if (calculatedEarned > allocPoint[_pid]) {
            calculatedEarned = allocPoint[_pid];
        }
        //用户挖矿总收益应小于Nuts账户余额
        uint256 poolBalance = target.balanceOf(address(this));
        if (calculatedEarned > poolBalance) return poolBalance;
        return calculatedEarned;
    }

    //当前单个质押的token的挖矿总收益
    function rewardPerToken(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.totalSupply == 0) {//矿池总质押
            return pool.rewardPerTokenStored;//矿池当前单个质押的token的挖矿总收益
        }
        return
        pool.rewardPerTokenStored.add(
            lastTimeRewardApplicable(_pid).sub(pool.lastUpdateTime)//距离池子上次更新的时间间隔
            .mul(pool.rewardRate)//单位时间挖矿总收益
            .mul(10 ** pool.decimals)
            .div(pool.totalSupply)//矿池总质押
        );
    }

    function lastTimeRewardApplicable(uint256 _pid) public view returns (uint256) {
        return Math.min(block.timestamp, poolInfo[_pid].periodFinish);
    }

    //提取挖矿收益
    function getReward(uint256 _pid) public checkExists(_pid) checkStart(_pid) updateReward(_pid, msg.sender) checkhalve(_pid) {
        //获取用户挖矿总收益
        uint256 reward = earned(_pid, msg.sender);
        if (reward > 0) {
            userInfo[_pid][msg.sender].rewards = 0;
            uint256 govReward = Math.min(reward.mul(10).div(100), target.balanceOf(address(this)).sub(reward));
            target.safeTransfer(msg.sender, reward);
            //项目方赚取用户收益的10%
            if (governance != address(0)) {
                target.safeTransfer(governance, govReward);
            }
            emit RewardPaid(msg.sender, _pid, reward);
        }
    }

    function getNextRate(uint256 currentEpoch, uint256 rate, uint256 step, uint256 end) pure private returns (uint256){
        if (currentEpoch > 1 && step > 0) {
            return Math.min(end, rate.add(step));
        }
        return rate;
    }

    modifier checkExists(uint256 _pid){
        require(poolInfo[_pid].startTime > 0, "pid invaild");
        _;
    }
    modifier checkStart(uint256 _pid){
        require(block.timestamp > poolInfo[_pid].startTime, "not start yet");
        _;
    }

    modifier updateReward(uint256 _pid, address account) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 rewardPerTokenStored = rewardPerToken(_pid);
        pool.rewardPerTokenStored = rewardPerTokenStored;
        pool.lastUpdateTime = lastTimeRewardApplicable(_pid);
        if (account != address(0)) {
            UserInfo storage user = userInfo[_pid][account];
            user.rewards = earned(_pid, account);//用户挖矿总收益
            user.userRewardPerTokenPaid = rewardPerTokenStored;//当前单个质押的token的挖矿总收益 10 ** pool.decimals
        }
        _;
    }

    //挖矿阶梯策略
    modifier checkhalve(uint256 _pid){
        require(durationList[_pid] > 0);
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp >= pool.periodFinish) {//当前阶段结束
            uint256 rewardMultiplier = getNextRate(pool.currentEpoch, pool.rate, pool.rateStep, pool.rateEnd);
            uint256 duration = durationList[_pid];
            uint256 currentReward = pool.initReward.mul(rewardMultiplier).div(100);
            uint256 totalReward = totalRewardList[_pid];
            if (totalReward.add(currentReward) > allocPoint[_pid]) {
                currentReward = allocPoint[_pid].sub(totalReward);
            }
            if (currentReward > 0) {
                totalRewardList[_pid] = totalReward.add(currentReward);
                pool.currentEpoch = pool.currentEpoch + 1;
                //意味着挖矿到达最后阶段
                if (totalRewardList[_pid] == allocPoint[_pid]) {
                    pool.endTime = block.timestamp.add(duration);
                }
            }
            pool.rate = rewardMultiplier;
            pool.initReward = currentReward;//当前阶段的挖矿总收益
            pool.lastUpdateTime = block.timestamp;
            pool.rewardRate = currentReward.div(duration);
            pool.periodFinish = block.timestamp.add(duration);
            emit RewardAdded(_pid, currentReward);
        }
        _;
    }

}
