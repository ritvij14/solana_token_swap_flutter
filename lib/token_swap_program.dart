import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'package:solana_token_swap_flutter/token_swap_instruction.dart';

class TokenSwapProgram extends Message {
  TokenSwapProgram._({
    required List<Instruction> instructions,
  }) : super(
          instructions: instructions,
        );

  static const programId = 'SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8';

  factory TokenSwapProgram.createSwap({
    required String payer,
    required String tokenSwapAccount,
    required int rent,
    required int space,
    required String authority,
    required String tokenAccountA,
    required String tokenAccountB,
    required String poolToken,
    required String poolTokenAccount,
    required String feeAccount,
    required String tokenProgramId,
    required int tradeFeeNumerator,
    required int tradeFeeDenominator,
    required int ownerTradeFeeNumerator,
    required int ownerTradeFeeDenominator,
    required int ownerWithdrawFeeNumerator,
    required int ownerWithdrawFeeDenominator,
    required int hostFeeNumerator,
    required int hostFeeDenominator,
    required int curveType,
  }) =>
      TokenSwapProgram._(instructions: [
        SystemInstruction.createAccount(
          fromPubKey: payer,
          pubKey: tokenSwapAccount,
          lamports: rent,
          space: space,
          owner: TokenSwapProgram.programId,
        ),
        TokenSwapInstruction.initializeSwap(
          tokenSwapAccount: tokenSwapAccount,
          poolAuthority: authority,
          tokenAccountA: tokenAccountA,
          tokenAccountB: tokenAccountB,
          poolToken: poolToken,
          feeAccount: feeAccount,
          poolTokenAccount: poolTokenAccount,
          tokenProgramId: tokenProgramId,
          tradeFeeNumerator: tradeFeeNumerator,
          tradeFeeDenominator: tradeFeeDenominator,
          ownerTradeFeeNumerator: ownerTradeFeeNumerator,
          ownerTradeFeeDenominator: ownerTradeFeeDenominator,
          ownerWithdrawFeeNumerator: ownerWithdrawFeeNumerator,
          ownerWithdrawFeeDenominator: ownerWithdrawFeeDenominator,
          hostFeeNumerator: hostFeeNumerator,
          hostFeeDenominator: hostFeeDenominator,
          curveType: curveType,
        ),
      ]);

  factory TokenSwapProgram.depositTokens({
    required String tokenSwap,
    required String authority,
    required String userTransferAuthority,
    required String sourceA,
    required String sourceB,
    required String intoA,
    required String intoB,
    required String poolToken,
    required String poolAccount,
    required String tokenProgramId,
    required int poolTokenAmount,
    required int maximumTokenA,
    required int maximumTokenB,
  }) =>
      TokenSwapProgram._(
        instructions: [
          TokenSwapInstruction.depositAllTokenTypesInstruction(
            tokenSwap: tokenSwap,
            authority: authority,
            userTransferAuthority: userTransferAuthority,
            sourceA: sourceA,
            sourceB: sourceB,
            intoA: intoA,
            intoB: intoB,
            poolToken: poolToken,
            poolAccount: poolAccount,
            swapProgramId: TokenSwapProgram.programId,
            tokenProgramId: tokenProgramId,
            poolTokenAmount: poolTokenAmount,
            maximumTokenA: maximumTokenA,
            maximumTokenB: maximumTokenB,
          ),
        ],
      );
}
