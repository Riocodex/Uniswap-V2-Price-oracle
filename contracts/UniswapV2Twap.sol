pragma solidity 0.6.6;
// NOTE: using solidity 0.6.6 to match imports

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";

contract UniswapV2Twap {
    //in uniswapv2 the number are represented in decimals and solidity doesnt have them so they created their own using fixed point, to use this we declare fixed point
    using FixedPoint for *;

    //this will be the time to wait before we updated twap
    uint public constant PERIOD = 10;

    IUniswapV2Pair public immutable pair;
    address public immutable token0;
    address public immutable token1;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint32 public blockTimestampLast;

    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    constructor(IUniswapV2Pair _pair) public {
        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();
        price0CumulativeLast = _pair.price0CumulativeLast();
        price1CumulativeLast = _pair.price1CumulativeLast();
        (,,blockTimestampLast) = _pair.getReserves();
    }


    //this function will update the price0average and price1average
    //call the function once , wait for a minimum of PERIOD which is elapsed time, call it again and it will compute the two time weighted average prices
    function update()  returns () {
        (
            uint price0Cumulative,
            uint price1Cumulative,
            uint32 blockTimestamp

        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint timeElapsed = blockTimestamp - blockTimestampLast;
        require(timeElapsed >= PERIOD, "time elapsed < min period");

        //uq112 x 112 is a struct and thee input for the struct is uint224 so we rapped the formula for the price)average with uint224
        price0Average = FixedPoint.uq112x112(uint224(
            price0Cumulative - price0CumulativeLast) / timeElapsed);

        price1Average = FixedPoint.uq112x112(
            uint224(price1Cumulative - price1CumulativeLast) / timeElapsed);

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
        
    }

    //after user puts in token and amount in this function will calculate amount out using either prrice0average or price1average
    function consult(address token, uint amountIn)
    external 
    view
    returns(uint amountOut)
    {
        require(token == token0 || token == token1, "invalid token");
        if(token == token0){
             // NOTE: using FixedPoint for *
            // NOTE: mul returns uq144x112
            // NOTE: decode144 decodes uq144x112 to uint144
            amountOut = price0Average.mul(amountIn).decode144(); 
        }else{
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }

}