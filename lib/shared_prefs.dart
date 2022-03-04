import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:solana/solana.dart';

class SharedPrefs {
  late SharedPreferences sharedPrefs;

  void initPrefs() async {
    sharedPrefs = await SharedPreferences.getInstance();
  }

  void setWallet(Ed25519HDKeyPair wallet) async {
    sharedPrefs.setString(
        'wallet', const JsonEncoder().convert(await wallet.extract()));
  }

  Ed25519HDKeyPair? getWallet() {
    String? wallet = sharedPrefs.getString('wallet');
    if (wallet == null) {
      return null;
    } else {
      return const JsonDecoder().convert(wallet);
    }
  }

  void setAddress(String address) {
    sharedPrefs.setString('wallet_address', address);
  }

  String? getMnemonic() {
    return sharedPrefs.getString('wallet_mnemonic');
  }

  void setMnemonic(String mnemonic) {
    sharedPrefs.setString('wallet_mnemonic', mnemonic);
  }

  String? getPrivateKey() {
    return sharedPrefs.getString('wallet_private_key');
  }

  void setPrivateKey(String privateKey) {
    sharedPrefs.setString('wallet_private_key', privateKey);
  }
}
