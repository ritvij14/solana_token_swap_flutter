import 'package:solana/encoder.dart';

class TokenSwapInstruction extends Instruction {
  TokenSwapInstruction._({
    required List<AccountMeta> accounts,
    required Iterable<int> data,
  }) : super(
          programId: "SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8",
          accounts: accounts,
          data: data,
        );

  factory TokenSwapInstruction.initializeSwap({
    required String tokenSwapAccount,
    required String poolAuthority,
    required String tokenAccountA,
    required String tokenAccountB,
    required String poolToken,
    required String feeAccount,
    required String poolTokenAccount,
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
      TokenSwapInstruction._(
        accounts: [
          AccountMeta.writeable(pubKey: tokenSwapAccount, isSigner: false),
          AccountMeta.readonly(pubKey: poolAuthority, isSigner: false),
          AccountMeta.readonly(pubKey: tokenAccountA, isSigner: false),
          AccountMeta.readonly(pubKey: tokenAccountB, isSigner: false),
          AccountMeta.writeable(pubKey: poolToken, isSigner: false),
          AccountMeta.readonly(pubKey: feeAccount, isSigner: false),
          AccountMeta.writeable(pubKey: poolTokenAccount, isSigner: false),
          AccountMeta.readonly(pubKey: tokenProgramId, isSigner: false),
        ],
        data: Buffer.fromConcatenatedByteArrays([
          [0], // this is the array given to initializeMint in the token program
          Buffer.fromInt64(tradeFeeNumerator),
          Buffer.fromInt64(tradeFeeDenominator),
          Buffer.fromInt64(ownerTradeFeeNumerator),
          Buffer.fromInt64(ownerTradeFeeDenominator),
          Buffer.fromInt64(ownerWithdrawFeeNumerator),
          Buffer.fromInt64(ownerWithdrawFeeDenominator),
          Buffer.fromInt64(hostFeeNumerator),
          Buffer.fromInt64(hostFeeDenominator),
          Buffer.fromInt8(curveType),
        ]),
      );

  factory TokenSwapInstruction.depositAllTokenTypesInstruction({
    required String tokenSwap,
    required String authority,
    required String userTransferAuthority,
    required String sourceA,
    required String sourceB,
    required String intoA,
    required String intoB,
    required String poolToken,
    required String poolAccount,
    required String swapProgramId,
    required String tokenProgramId,
    required int poolTokenAmount,
    required int maximumTokenA,
    required int maximumTokenB,
  }) =>
      TokenSwapInstruction._(
        accounts: [
          AccountMeta.readonly(pubKey: tokenSwap, isSigner: false),
          AccountMeta.readonly(pubKey: authority, isSigner: false),
          AccountMeta.readonly(pubKey: userTransferAuthority, isSigner: true),
          AccountMeta.writeable(pubKey: sourceA, isSigner: false),
          AccountMeta.writeable(pubKey: sourceB, isSigner: false),
          AccountMeta.writeable(pubKey: intoA, isSigner: false),
          AccountMeta.writeable(pubKey: intoB, isSigner: false),
          AccountMeta.writeable(pubKey: poolToken, isSigner: false),
          AccountMeta.writeable(pubKey: poolAccount, isSigner: false),
          AccountMeta.readonly(pubKey: tokenProgramId, isSigner: false),
        ],
        data: Buffer.fromConcatenatedByteArrays([
          [2],
          Buffer.fromInt64(poolTokenAmount),
          Buffer.fromInt64(maximumTokenA),
          Buffer.fromInt64(maximumTokenB),
        ]),
      );
}
