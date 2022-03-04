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
}
