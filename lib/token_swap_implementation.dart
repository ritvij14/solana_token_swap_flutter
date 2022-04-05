import 'package:solana/dto.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'package:solana_token_swap_flutter/token_swap_instruction.dart';
import 'package:solana_token_swap_flutter/token_swap_program.dart';

Future<void> createSwap(Ed25519HDKeyPair wallet, String tokenAmint) async {
  SolanaClient solanaClient = SolanaClient(
    rpcUrl: Uri.parse("https://api.devnet.solana.com"),
    websocketUrl: Uri.parse("wss://api.devnet.solana.com"),
  );

  // liquidity token account
  print("liquidity token account");
  Ed25519HDKeyPair liquidityTokenAccount = await Ed25519HDKeyPair.random();

  List<Message> messages = [
    SystemProgram.createAccount(
      pubKey: liquidityTokenAccount.address,
      fromPubKey: wallet.address,
      lamports: await solanaClient.rpcClient.getMinimumBalanceForRentExemption(
          TokenProgram.neededMintAccountSpace),
      space: TokenProgram.neededAccountSpace,
      owner: wallet.address,
    ),
  ];

  print("token swap auth");
  Ed25519HDKeyPair tokenSwapAccount = await Ed25519HDKeyPair.random();

  final String authority = await findProgramAddress(
    programId: TokenSwapProgram.programId,
    seeds: [(await tokenSwapAccount.extractPublicKey()).bytes],
  );

  // liquidity token mint
  print("liquidity token mint");
  messages.add(
    TokenProgram.initializeMint(
      mint: liquidityTokenAccount.address,
      mintAuthority: authority,
      rent: await solanaClient.rpcClient.getMinimumBalanceForRentExemption(
          TokenProgram.neededMintAccountSpace),
      space: TokenProgram.neededAccountSpace,
      decimals: 9,
    ),
  );

  // holding account for tokenA
  print("holding account for tokenA");
  Ed25519HDKeyPair tokenAHoldingAccount = await Ed25519HDKeyPair.random();
  messages.add(
    TokenProgram.createAccount(
      mint: tokenAmint,
      address: tokenAHoldingAccount.address,
      owner: authority,
      rent: await solanaClient.rpcClient.getMinimumBalanceForRentExemption(
          TokenProgram.neededMintAccountSpace),
      space: TokenProgram.neededAccountSpace,
    ),
  );

  //depositor pool account
  print("depositor pool account");
  Ed25519HDKeyPair depositorPoolAccount = await Ed25519HDKeyPair.random();
  messages.add(
    TokenProgram.createAccount(
      mint: liquidityTokenAccount.address,
      address: depositorPoolAccount.address,
      owner: wallet.address,
      rent: await solanaClient.rpcClient.getMinimumBalanceForRentExemption(
          TokenProgram.neededMintAccountSpace),
      space: TokenProgram.neededAccountSpace,
    ),
  );

  // creating fee pool account its set from env variable or to creater of the pool
  // creater of the pool is not allowed in some versions of token-swap program
  print("fee pool account");
  Ed25519HDKeyPair feeAccount = await Ed25519HDKeyPair.random();
  messages.add(
    TokenProgram.createAccount(
      mint: liquidityTokenAccount.address,
      address: feeAccount.address,
      owner: wallet.address,
      rent: await solanaClient.rpcClient.getMinimumBalanceForRentExemption(
          TokenProgram.neededMintAccountSpace),
      space: TokenProgram.neededAccountSpace,
    ),
  );

  print("Sending above transactions");
  var tx = messages.map((e) async {
    return await solanaClient.rpcClient.signAndSendTransaction(e, [
      liquidityTokenAccount,
      depositorPoolAccount,
      feeAccount,
    ]);
  });

  print(tx);
}

// Future<List> createSwap(Ed25519HDKeyPair payer, String tokenAmint) async {
//   print("TOKEN_SWAP: creating addresses");
//   SolanaClient solanaClient = SolanaClient(
//     rpcUrl: Uri.parse("https://api.devnet.solana.com"),
//     websocketUrl: Uri.parse("wss://api.devnet.solana.com"),
//   );
//   Ed25519HDKeyPair tokenSwapAccount = await Ed25519HDKeyPair.random();
//   print("TOKEN_SWAP: airdropping addresses");

//   await solanaClient.rpcClient
//       .requestAirdrop(tokenSwapAccount.address, lamportsPerSol);
//   Ed25519HDKeyPair authority = await Ed25519HDKeyPair.random();
//   Ed25519HDKeyPair feeAccount = await Ed25519HDKeyPair.random();

//   ProgramAccount tokenAccountA =
//       await solanaClient.createAssociatedTokenAccount(
//     mint: tokenAmint,
//     funder: tokenSwapAccount,
//   );

//   await solanaClient.rpcClient
//       .requestAirdrop(feeAccount.address, lamportsPerSol);

//   print("TOKEN_SWAP: create pool mint");

//   final poolMint = await solanaClient.initializeMint(
//     owner: tokenSwapAccount,
//     decimals: 9,
//   );

//   final poolTokenAccount = await solanaClient.createAssociatedTokenAccount(
//     funder: tokenSwapAccount,
//     mint: poolMint.mint,
//   );

//   await solanaClient.transferMint(
//     destination: poolTokenAccount.pubkey,
//     amount: 10000000,
//     mint: poolMint.mint,
//     owner: tokenSwapAccount,
//   );

//   print("TOKEN_SWAP: creating the swap");

//   final message = TokenSwapProgram.createSwap(
//     tokenSwapAccount: tokenSwapAccount.address,
//     authority: authority.address,
//     tokenAccountA: tokenAccountA.pubkey,
//     tokenAccountB: tokenSwapAccount.address,
//     poolToken: poolMint.mint,
//     feeAccount: feeAccount.address,
//     poolTokenAccount: poolTokenAccount.pubkey,
//     tokenProgramId: TokenProgram.programId,
//     tradeFeeNumerator: 10,
//     tradeFeeDenominator: 10,
//     ownerTradeFeeNumerator: 10,
//     ownerTradeFeeDenominator: 10,
//     ownerWithdrawFeeNumerator: 10,
//     ownerWithdrawFeeDenominator: 10,
//     hostFeeNumerator: 10,
//     hostFeeDenominator: 10,
//     curveType: 10,
//     payer: payer.address,
//     // still not completely clear about the concepts of rent and space so using
//     // arbitrary values. I think they are mainly for the amount of data being stored but not completely sure.
//     rent: 1000,
//     space: 1000,
//   );

//   final signature = await solanaClient.rpcClient.signAndSendTransaction(
//     message,
//     [payer, tokenSwapAccount],
//   );

//   return [
//     signature,
//     tokenSwapAccount,
//     authority,
//     tokenAccountA,
//     poolMint,
//     poolTokenAccount
//   ];
// }

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
