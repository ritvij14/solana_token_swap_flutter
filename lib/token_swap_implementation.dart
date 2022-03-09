import 'package:solana/dto.dart';
import 'package:solana/solana.dart';
import 'package:solana_token_swap_flutter/token_swap_instruction.dart';
import 'package:solana_token_swap_flutter/token_swap_program.dart';

Future<List> createSwap(Ed25519HDKeyPair payer, String tokenAmint) async {
  SolanaClient solanaClient = SolanaClient(
    rpcUrl: Uri.parse("https://api.devnet.solana.com"),
    websocketUrl: Uri.parse("wss://api.devnet.solana.com"),
  );
  Ed25519HDKeyPair tokenSwapAccount = await Ed25519HDKeyPair.random();
  Ed25519HDKeyPair authority = await Ed25519HDKeyPair.random();
  Ed25519HDKeyPair feeAccount = await Ed25519HDKeyPair.random();
  ProgramAccount tokenAccountA =
      await solanaClient.createAssociatedTokenAccount(
    mint: tokenAmint,
    funder: tokenSwapAccount,
  );

  await solanaClient.rpcClient
      .requestAirdrop(tokenSwapAccount.address, lamportsPerSol);

  final poolMint = await solanaClient.initializeMint(
    owner: tokenSwapAccount,
    decimals: 9,
  );

  final poolTokenAccount = await solanaClient.createAssociatedTokenAccount(
    funder: tokenSwapAccount,
    mint: poolMint.mint,
  );

  await solanaClient.transferMint(
    destination: poolTokenAccount.pubkey,
    amount: 10000000,
    mint: poolMint.mint,
    owner: tokenSwapAccount,
  );

  final message = TokenSwapProgram.createSwap(
    tokenSwapAccount: tokenSwapAccount.address,
    authority: authority.address,
    tokenAccountA: tokenAccountA.pubkey,
    tokenAccountB: tokenSwapAccount.address,
    poolToken: poolMint.mint,
    feeAccount: feeAccount.address,
    poolTokenAccount: poolTokenAccount.pubkey,
    tokenProgramId: TokenProgram.programId,
    tradeFeeNumerator: 10,
    tradeFeeDenominator: 10,
    ownerTradeFeeNumerator: 10,
    ownerTradeFeeDenominator: 10,
    ownerWithdrawFeeNumerator: 10,
    ownerWithdrawFeeDenominator: 10,
    hostFeeNumerator: 10,
    hostFeeDenominator: 10,
    curveType: 10,
    payer: payer.address,
    // still not completely clear about the concepts of rent and space so using
    // arbitrary values. I think they are mainly for the amount of data being stored but not completely sure.
    rent: 1000,
    space: 1000,
  );

  final signature = await solanaClient.rpcClient.signAndSendTransaction(
    message,
    [payer, tokenSwapAccount],
  );

  return [
    signature,
    tokenSwapAccount,
    authority,
    tokenAccountA,
    poolMint,
    poolTokenAccount
  ];
}

Future<void> depositTokens(
  Ed25519HDKeyPair tokenSwapAccount,
  Ed25519HDKeyPair authority,
  Ed25519HDKeyPair owner,
  String ownerTokenA,
  ProgramAccount tokenAccountA,
  SplToken poolMint,
  ProgramAccount poolTokenAccount,
) async {
  SolanaClient solanaClient = SolanaClient(
    rpcUrl: Uri.parse("https://api.devnet.solana.com"),
    websocketUrl: Uri.parse("wss://api.devnet.solana.com"),
  );
  Ed25519HDKeyPair transferAuthority = await Ed25519HDKeyPair.random();

  final message = TokenSwapProgram.depositTokens(
    tokenSwap: tokenSwapAccount.address,
    authority: authority.address,
    userTransferAuthority: transferAuthority.address,
    sourceA: owner.address,
    sourceB: ownerTokenA,
    intoA: tokenSwapAccount.address,
    intoB: tokenAccountA.pubkey,
    poolToken: poolMint.mint,
    poolAccount: poolTokenAccount.pubkey,
    tokenProgramId: TokenProgram.programId,
    poolTokenAmount: 1,
    maximumTokenA: 1,
    maximumTokenB: 1,
  );

  final signature = await solanaClient.rpcClient.signAndSendTransaction(
    message,
    [owner, transferAuthority],
  );
}
