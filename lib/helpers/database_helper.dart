import 'package:hive/hive.dart';

class DatabaseHelper {
  static final Box _userBox = Hive.box('users');
  static final Box _transactionsBox = Hive.box('transactions');

  Future<void> createUser(String name, String surname, String password) async {
    int lastAccountId = _userBox.length;

    const String agency = '0001';
    final String account = (lastAccountId + 1).toString().padLeft(5, '0');
    const double initialBalance = 0.0;

    await _userBox.put(account, {
      'name': name,
      'surname': surname,
      'agency': agency,
      'account': account,
      'password': password,
      'balance': initialBalance,
    });
  }

  static Future<void> updatePassword(String account, String newPassword) async {
    var box = Hive.box('users');
    Map<String, dynamic>? user = Map<String, dynamic>.from(box.get(account));

    if (user != null) {
      user['password'] = newPassword;
      await box.put(account, user);
    } else {
      throw Exception('Usuário não encontrado.');
    }
  }

  Map<String, dynamic>? loginUser(
      String agency, String account, String password) {
    final user = _userBox.get(account);
    if (user != null &&
        user['agency'] == agency &&
        user['password'] == password) {
      return Map<String, dynamic>.from(user);
    }
    return null;
  }

  double checkBalance(String account) {
    final user = _userBox.get(account);
    if (user != null) {
      return user['balance'];
    }
    throw Exception('Conta não encontrada.');
  }

  Future<void> deposit(String account, double amount) async {
  final user = _userBox.get(account);
  print('Usuário encontrado: $user');

  if (user != null) {
    final currentBalance = user['balance'];
    print('Saldo atual: $currentBalance');

    if (currentBalance is double) {
      final newBalance = currentBalance + amount;
      print('Novo saldo: $newBalance');

      await _userBox.put(account, {
        ...user,
        'balance': newBalance,
      });
      _addTransaction(account, 'Depósito', amount);
    } else {
      throw Exception('O saldo atual é inválido.');
    }
  } else {
    throw Exception('Conta não encontrada.');
  }
}

  Future<void> withdraw(String account, double amount) async {
    final user = Map<String, dynamic>.from(_userBox.get(account));
    if (user != null) {
      final currentBalance = user['balance'];
      if (currentBalance >= amount) {
        final newBalance = currentBalance - amount;
        user['balance'] = newBalance;
        await _userBox.put(account, user);
        _addTransaction(account, 'Saque', amount);
      } else {
        throw Exception('Saldo insuficiente.');
      }
    } else {
      throw Exception('Conta não encontrada.');
    }
  }

  Future<void> transfer(
      String fromAccount, String toAccount, double amount) async {
    final fromUser = Map<String, dynamic>.from(_userBox.get(fromAccount));
    final toUser = Map<String, dynamic>.from(_userBox.get(toAccount));

    if (fromUser != null && toUser != null) {
      final fromBalance = fromUser['balance'];
      if (fromBalance >= amount) {
        fromUser['balance'] = fromBalance - amount;
        await _userBox.put(fromAccount, fromUser);

        toUser['balance'] += amount;
        await _userBox.put(toAccount, toUser);

        _addTransaction(fromAccount, 'Transferência enviada', amount);
        _addTransaction(toAccount, 'Transferência recebida', amount);
      } else {
        throw Exception('Saldo insuficiente para transferência.');
      }
    } else {
      throw Exception('Uma das contas não foi encontrada.');
    }
  }

  void _addTransaction(String account, String type, double amount) {
    final transaction = {
      'account': account,
      'type': type,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
    };
    _transactionsBox.add(transaction);
  }

  List<Map<String, dynamic>> getTransactions(String account) {
    return _transactionsBox.values
        .where((transaction) => transaction['account'] == account)
        .toList()
        .cast<Map<String, dynamic>>();
  }

  Future<void> deleteAccount(String account) async {
    await _userBox.delete(account);
    _transactionsBox.deleteAll(
        _transactionsBox.keys.where((key) => _transactionsBox.get(key)['account'] == account));
  }

  List<Map<String, dynamic>> getAllUsers() {
    return _userBox.values
        .where((user) => user['account'] != null)
        .toList()
        .cast<Map<String, dynamic>>();
  }
}
