import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:solana/dto.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'package:solana_token_swap_flutter/shared_prefs.dart';
import 'package:bip39/bip39.dart' as bip39;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String walletAddress = "";
  final SharedPrefs prefs = SharedPrefs();
  final rpcClient = RpcClient('https://api.devnet.solana.com');
  final subscriptionClient = SubscriptionClient.connect(
      Platform.environment['DEVNET_WEBSOCKET_URL'] ??
          'ws://api.devnet.solana.com');
  double walletBalance = 0.0;
  List<ProgramAccount> tokens = [];
  late Ed25519HDKeyPair mint;
  late Ed25519HDKeyPair freezeAuthority;
  late Ed25519HDKeyPair mintAuthority;
  late Ed25519HDKeyPair wallet;

  void _createWallet() async {
    String randomMnemonic = bip39.generateMnemonic();
    final wallet = await Ed25519HDKeyPair.fromMnemonic(randomMnemonic);
    final address = wallet.address;
    // final privateKey = wallet.
    prefs.setAddress(address);
    prefs.setMnemonic(randomMnemonic);
    setState(() {
      walletAddress = address;
      this.wallet = wallet;
    });
  }

  void _checkOrCreateBalance() async {
    double balance = await rpcClient.getBalance(walletAddress) / pow(10, 9);
    if (balance == 0.0) {
      await rpcClient.requestAirdrop(walletAddress, lamportsPerSol);
      balance = await rpcClient.getBalance(walletAddress) / pow(10, 9);
    }
    setState(() {
      walletBalance = balance;
    });
  }

  void _checkWallet() async {
    var address = prefs.getAddress();
    if (address != null) {
      setState(() {
        walletAddress = address;
      });
    } else {
      _createWallet();
    }
    mint = await Ed25519HDKeyPair.random();
    freezeAuthority = await Ed25519HDKeyPair.random();
    mintAuthority = await Ed25519HDKeyPair.random();
    print("WalletAddress:" + walletAddress);
    print("Mint:" + mint.address);
    print("FreezeAuthority:" + freezeAuthority.address);
    print("MintAuthority:" + mintAuthority.address);
  }

  void _createToken() async {
    // await rpcClient.requestAirdrop(mintAuthority.address, lamportsPerSol);

    // initialize mint
    final rent = await rpcClient
        .getMinimumBalanceForRentExemption(TokenProgram.neededMintAccountSpace);
    await sendMessage(
      TokenProgram.initializeMint(
        mint: mint.address,
        mintAuthority: mintAuthority.address,
        freezeAuthority: freezeAuthority.address,
        rent: rent,
        space: TokenProgram.neededMintAccountSpace,
        decimals: 5,
      ),
      [mintAuthority, mint],
    );

    // display result
    print("token minting done");
  }

  void _mintTo() async {
    // mint tokens to user's account
    await sendMessage(
      TokenProgram.mintTo(
        mint: mint.address,
        destination: walletAddress,
        authority: mintAuthority.address,
        amount: 10,
      ),
      [mintAuthority],
    );
  }

  void _createMintAccount() async {
    final rent = await rpcClient
        .getMinimumBalanceForRentExemption(TokenProgram.neededMintAccountSpace);
// create account
    await sendMessage(
      TokenProgram.createAccount(
        mint: mint.address,
        address: walletAddress,
        owner: mintAuthority.address,
        rent: rent,
        space: TokenProgram.neededAccountSpace,
      ),
      [mintAuthority, wallet],
    );
  }

  void _getTokens() async {
    final tokenInfo = await rpcClient.getTokenAccountsByOwner(walletAddress,
        const TokenAccountsFilter.byProgramId(TokenProgram.programId));

    if (tokenInfo.isNotEmpty) {
      setState(() {
        tokens = tokenInfo;
      });
    }
  }

  Future<void> sendMessage(
    Message message,
    List<Ed25519HDKeyPair> signers,
  ) =>
      _sendMessage(
        rpcClient: rpcClient,
        subscriptionClient: subscriptionClient,
        message: message,
        signers: signers,
      );

  Future<void> _sendMessage({
    required RpcClient rpcClient,
    required SubscriptionClient subscriptionClient,
    required Message message,
    required List<Ed25519HDKeyPair> signers,
  }) async {
    final signature = await rpcClient.signAndSendTransaction(message, signers);
    await subscriptionClient.waitForSignatureStatus(
      signature,
      status: ConfirmationStatus.finalized,
    );
  }

  @override
  void initState() {
    super.initState();
    prefs.initPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Your wallet address: ${walletAddress.isNotEmpty ? '${walletAddress.substring(0, 5)}...${walletAddress.substring(walletAddress.length - 5)}' : ''}',
            ),
            Text(
              'Your wallet balance: $walletBalance SOL',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _checkWallet,
                  child: const Text('Check Wallet'),
                ),
                ElevatedButton(
                  onPressed: _checkOrCreateBalance,
                  child: const Text('Check Balance'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await rpcClient.requestAirdrop(
                        walletAddress, lamportsPerSol);
                    _checkOrCreateBalance();
                  },
                  child: const Text('Airdrop'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _createToken,
                    child: const Text('Create Token'),
                  ),
                  ElevatedButton(
                    onPressed: _createMintAccount,
                    child: const Text('Create Acc'),
                  ),
                  ElevatedButton(
                    onPressed: _mintTo,
                    child: const Text('Mint the Token'),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _getTokens,
              child: const Text('Show Tokens'),
            ),
            ...tokens.map((token) {
              return Row(
                children: [
                  Text(
                    '${token.pubkey.substring(0, 5)}...${token.pubkey.substring(token.pubkey.length - 5)}',
                  ),
                  Text(
                    '${token.account.lamports}',
                  ),
                ],
              );
            })
          ],
        ),
      ),
    );
  }
}
