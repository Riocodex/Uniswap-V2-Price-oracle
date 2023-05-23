const hre = require("hardhat");

async function main(){
    const ContractFactory = await hre.ethers.getContractFactory("UniswapV2Twap");
    const contract = await ContractFactory.deploy();

    await contract.deployed();

    console.log("contract deployed @ ",contract.address);
    
}


main().catch((error) =>{
    console.error(error);
    process.exitCode=1;
  });