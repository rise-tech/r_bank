import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'helpers/database_helper.dart';
import 'main.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Map<String, dynamic> user;
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  void _updateUser() {
    final updatedUser =
        Map<String, dynamic>.from(Hive.box('users').get(user['account']));
    setState(() {
      user = updatedUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('R.Bank'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignatureForm(),
                  ),
                );
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 800,
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Olá, ${user['name']}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildGridButton(context, 'Depositar', Icons.attach_money,
                          Colors.green, _showDepositDialog),
                      _buildGridButton(context, 'Sacar', Icons.money_off,
                          Colors.orange, _showWithdrawDialog),
                      _buildGridButton(context, 'Transferir', Icons.swap_horiz,
                          Colors.blue, _showTransferDialog),
                      _buildGridButton(context, 'Extrato', Icons.receipt,
                          Colors.purple, _showStatementDialog),
                      _buildGridButton(context, 'Atualizar Senha', Icons.person,
                          Colors.indigo, _showUpdateDetailsDialog),
                      _buildGridButton(
                          context,
                          'Fechar Conta',
                          Icons.delete_forever,
                          Colors.red,
                          _showCloseAccountDialog,
                          highlight: true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Saldo: R\$ ${user['balance'].toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridButton(BuildContext context, String title, IconData icon,
      Color color, Function(BuildContext) onTap,
      {bool highlight = false}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: highlight ? Colors.red : color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () => onTap(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog(BuildContext context) {
    final TextEditingController depositController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Depositar'),
          content: TextField(
            controller: depositController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Valor a depositar',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final double depositAmount =
                    double.tryParse(depositController.text) ?? 0;
                if (depositAmount > 0) {
                  await dbHelper.deposit(user['account'], depositAmount);
                  _updateUser();
                  Navigator.pop(context);
                  _showSnackBar(
                      context, 'Depósito realizado com sucesso!', Colors.green);
                } else {
                  _showSnackBar(context, 'Valor inválido', Colors.red);
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    final TextEditingController withdrawController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sacar'),
          content: TextField(
            controller: withdrawController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Valor a sacar',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final double withdrawAmount =
                    double.tryParse(withdrawController.text) ?? 0;
                if (withdrawAmount > 0) {
                  try {
                    await dbHelper.withdraw(user['account'], withdrawAmount);
                    _updateUser();
                    Navigator.pop(context);
                    _showSnackBar(
                        context, 'Saque realizado com sucesso!', Colors.green);
                  } catch (e) {
                    _showSnackBar(
                        context, 'Saldo insuficiente ou erro: $e', Colors.red);
                  }
                } else {
                  _showSnackBar(context, 'Valor inválido', Colors.red);
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showTransferDialog(BuildContext context) {
    final TextEditingController transferAmountController =
        TextEditingController();
    String? selectedAccount;
    List<Map<String, dynamic>> users = dbHelper.getAllUsers();
    users.removeWhere((u) => u['account'] == user['account']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Transferir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Conta destino'),
                items: users.map<DropdownMenuItem<String>>((user) {
                  return DropdownMenuItem<String>(
                    value: user['account'],
                    child: Text('${user['name']} (${user['account']})'),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedAccount = value;
                },
              ),
              TextField(
                controller: transferAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor a transferir',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final double transferAmount =
                    double.tryParse(transferAmountController.text) ?? 0;
                if (transferAmount > 0 && selectedAccount != null) {
                  try {
                    await dbHelper.transfer(
                        user['account'], selectedAccount!, transferAmount);
                    _updateUser();
                    Navigator.pop(context);
                    _showSnackBar(context,
                        'Transferência realizada com sucesso!', Colors.green);
                  } catch (e) {
                    _showSnackBar(context, 'Erro: $e', Colors.red);
                  }
                } else {
                  _showSnackBar(
                      context, 'Valor inválido ou conta não selecionada', Colors.red);
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showStatementDialog(BuildContext context) {
    List<Map<String, dynamic>> transactions =
        dbHelper.getTransactions(user['account']);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Extrato'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                var transaction = transactions[index];
                return ListTile(
                  title: Text(transaction['type']),
                  subtitle: Text(transaction['date']),
                  trailing: Text('R\$ ${transaction['amount']}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController passwordController = TextEditingController();
        final TextEditingController passwordVerifyController =
            TextEditingController();
        return AlertDialog(
          title: const Text('Atualizar Senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Nova Senha',
                ),
                obscureText: true,
              ),
              TextField(
                controller: passwordVerifyController,
                decoration: const InputDecoration(
                  labelText: 'Repita a Nova Senha',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text.isNotEmpty &&
                    passwordVerifyController.text.isNotEmpty) {
                  if (passwordController.text == passwordVerifyController.text) {
                    if (passwordController.text != user['password']) {
                      try {
                        await DatabaseHelper.updatePassword(
                            user['account'], passwordController.text);
                        Navigator.pop(context);
                        _showSnackBar(context, 'Senha atualizada com sucesso!',
                            Colors.green);
                      } catch (e) {
                        _showSnackBar(
                            context, 'Erro ao atualizar senha: $e', Colors.red);
                      }
                    } else {
                      _showSnackBar(
                          context,
                          'A nova senha não pode ser igual à anterior.',
                          Colors.yellow);
                    }
                  } else {
                    _showSnackBar(
                        context, 'As senhas não coincidem.', Colors.yellow);
                  }
                } else {
                  _showSnackBar(
                      context, 'Preencha todos os campos.', Colors.red);
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showCloseAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Fechar Conta'),
          content: const Text(
              'Tem certeza que deseja fechar sua conta? Esta ação é irreversível.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await dbHelper.deleteAccount(user['account']);
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignatureForm(),
                  ),
                );
                _showSnackBar(
                    context, 'Conta fechada com sucesso.', Colors.green);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    });
  }
}
