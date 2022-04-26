# Mula Token
This repo contains the code for the Mula Finance token (MULA) and some associated contracts: MulaIdo.sol,MulaSeed.sol,MulaTokenUtils.sol,MulaSaleUtils.sol and MulaVestorUtils.sol.

MulaToken.sol
MulaToken.sol is an ERC20 token that represents the cryptographic right to purchase MULA tokens. Alongside ERC-20 and full-token pausing.

BSC-SCAN

Transfer + TransferFrom
The only other thing in this contract is a wrapper around the ERC20 transfer and transferFrom functions. The only thing that happens is that we ensure that the transfers can only be made after the pause staged, and we also return the bool result of the transfer so it can be used with SafeERC20.

MulaIdoVestor.sol,MulaSeedVestor
These contracts ensures distributions of the tokens according to a linear vesting schedule. These contracts extends the MulaVestorUtils.sol file which facilitates withdrawals and vesting dtails and any point in time.

What does these codes do and why?
This code provides the ability for tokens to be transferred to a beneficiary's address according to a linear vesting schedule.

