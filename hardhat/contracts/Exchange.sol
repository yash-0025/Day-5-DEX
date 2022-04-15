// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

  import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract Exchange is ERC20 {
    address public cryptoDevTokenAddress;

    // We have to keep track  of Crypto Dev LP tokens
    constructor (address _CryptoDevtoken) ERC20("CryptoDev LP Token", "CDLP") {
        require(_CryptoDevtoken != address(0),"Token address is a null address.");
        cryptoDevTokenAddress = _CryptoDevtoken;
    }

    // Function to return the Crypto dev token held by the contract 
    function getReserve() public view returns (uint256) {
        return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
    }

    // We have to add liquidity to the exchange
    function addLiquidity(uint256 _amount) public payable returns(uint256) {
        uint256 liquidity;
        uint256 ethBalance = address(this).balance;
        uint256 cryptoDevTokenReserve = getReserve();
        ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);

  /* 
    If the reserve is empty we will intake any supplied value of ETHER and CryptoDEv token by 
    user as there is no ratio currently
    */
    if (cryptoDevTokenReserve == 0) {
        // We will transfer cryptoDev token from user account  to contract 
        cryptoDevToken.transferFrom(msg.sender, address(this), (_amount));
        // take the current eth balance of the LP token to the user
//  liquidity provided is equal to the eth balance as this is the first time user is 
// adding ETh to the contract so whatever eth contract has is equal to the one supplied
// by the user in the current addliquidity call
// liquidity tokens that need to be minted to the user on addliquidity call should always
// be proportional to the eth specified by the user
liquidity = ethBalance;
_mint(msg.sender, liquidity);

} else {

    // So if the reserve is not empty then intake any value supplied by the user for ETher
    // and determine according to the ratio like how many CryptoDev tokens need to be supplied
    // to prevent any large price impacts because of the additional liquidity

    // EThReserve should be the current ethbalance subtracted by the value of ether sent by the
    // user in the current addliquidity call

    uint256 ethReserve = ethBalance - msg.value;
 // Ratio should always be maintained so that there are no major price impacts when adding liquidity
// Ratio here is -> (cryptoDevTokenAmount user can add/cryptoDevTokenReserve in the contract) = 
// (Eth Sent by the user/Eth Reserve in the contract);
// So doing some maths, (cryptoDevTokenAmount user can add) 
// = (Eth Sent by the user * cryptoDevTokenReserve /Eth Reserve);
    uint256 cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve) / (ethReserve);
    require(_amount >= cryptoDevTokenAmount, "Amount of token sent is less than the minimum token required");
// transfer only (cryptoDevTokenAmount user can add) amount of `Crypto Dev tokens` from users account
// to the contract

    cryptoDevToken.transferFrom(msg.sender, address(this), cryptoDevTokenAmount);
liquidity = (totalSupply() * msg.value) / ethReserve;
_mint(msg.sender, liquidity);
}
return liquidity;
    }

    function removeLiquidity(uint256 _amount) public returns(uint256, uint256) {
        require(_amount > 0, "_amount should be greater than zero");
        uint256 ethReserve = address(this).balance;
        uint256 _totalSupply = totalSupply();
// The amount of Eth that would be sent back to the user is based
    // on a ratio
    // Ratio is -> (Eth sent back to the user/ Current Eth reserve)
    // = (amount of LP tokens that user wants to withdraw)/ Total supply of `LP` tokens
    // Then by some maths -> (Eth sent back to the user)
    // = (Current Eth reserve * amount of LP tokens that user wants to withdraw)/Total supply of `LP` tokens
uint256 ethAmount = (ethReserve * _amount) / _totalSupply;
// The amount of Crypto Dev token that would be sent back to the user is based on the ratio
// Ratio = Cryptodev sent back to user / current crypto dev reserve
// =( Crypto dev token reserve * amount of Lp token that user want to withdraw )/total supply Of lp token
uint256 cryptoDevTokenAmount = (getReserve() * _amount) / _totalSupply;
// Burn the sent Lp token from the user wallet because they are already sent to remove liquidity
 _burn(msg.sender, _amount);
 // Transfer the ethamount from user wallet to the contract
 payable(msg.sender).transfer(ethAmount);
 // Transfer cryptoDevtoken amount  to cryptoDev token from users wallet to contract
 ERC20(cryptoDevTokenAddress).transfer(msg.sender, cryptoDevTokenAmount);
 return (ethAmount, cryptoDevTokenAmount);
    }

function getAmountOfTokens(    uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) public pure returns(uint256) {
    require(inputReserve > 0 && outputReserve > 0, "Invalid Reserves");
    // We are chargin 1% fees 
    // Input amount with fees = (inputamount - (1*(inputamount)/100)) = ((inputamount)*99)/100
    uint256 inputAmountWithFee = inputAmount * 99;
    // Because we need to follow the concept of' XY = K' curve
 // so the final formulae is Δy = (y*Δx)/(x + Δx);
// Δy in our case is `tokens to be recieved`
// Δx = ((input amount)*99)/100, x = inputReserve, y = outputReserve
// So by putting the values in the formulae you can get the numerator and denominator  
uint256 numerator = inputAmountWithFee * outputReserve;
uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
return numerator/denominator;

}


// Fucntion to swap eth for cryptoDev token

function ethToCryptoDevToken(uint256 _minToken) public payable {
    uint256 tokenReserve = getReserve();
    // call the `getAmountOfTokens` to get the amount of crypto dev tokens
    // that would be returned to the user after the swap
    // Notice that the `inputReserve` we are sending is equal to
    //  `address(this).balance - msg.value` instead of just `address(this).balance`
    // because `address(this).balance` already contains the `msg.value` user has sent in the given call
    // so we need to subtract it to get the actual input reserve

    uint256 tokensBought = getAmountOfTokens(msg.value, 
    address(this).balance,
     tokenReserve
     );

     require(tokensBought >= _minToken, "Insufficient output amount");
     // Transfer the crypto dev token to the user
     ERC20(cryptoDevTokenAddress).transfer(msg.sender, tokensBought);
}

//  function to swap crypto dev to eth
function cryptoDevTokenToEth(uint256 _tokenSold, uint _minEth) public {
    uint256 tokenReserve = getReserve();
    // Call the getAmountOfTOkens to get the amount of ether
    // It will return the user after the swap
    uint256 ethBought = getAmountOfTokens(_tokenSold,
     tokenReserve,
    address(this).balance);

require(ethBought >= _minEth, "Insufficient amount");
// Transfer CryptoDev tokens ffom the user address to the contract
ERC20(cryptoDevTokenAddress).transferFrom(
    msg.sender,
    address(this),
    _tokenSold
);
// send the ethBought to the user from the contract
payable(msg.sender).transfer(ethBought);
}
}