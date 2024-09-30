// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'helpers/database_helper.dart';
import 'home_screen.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('users');
  await Hive.openBox('transactions');
  runApp(const RBankApp());
}

class RBankApp extends StatelessWidget {
  const RBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rodrigues.Bank',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const SignatureForm(),
    );
  }
}

class SignatureForm extends StatefulWidget {
  const SignatureForm({super.key});

  @override
  _SignatureFormState createState() => _SignatureFormState();
}

class _SignatureFormState extends State<SignatureForm> {
  final TextEditingController _agencyController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _validateAgency = false;
  bool _validateAccount = false;
  bool _validatePassword = false;

  final dbHelper = DatabaseHelper();

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  bool _validateForm() {
    setState(() {
      _validateAgency = _agencyController.text.isEmpty;
      _validateAccount = _accountController.text.isEmpty;
      _validatePassword = _passwordController.text.isEmpty;
    });

    return !_validateAgency && !_validateAccount && !_validatePassword;
  }

  void _register(String name, String surname, String password) {
  if (name.isEmpty || surname.isEmpty || password.isEmpty) {
    _showSnackBar('Por favor, preencha todos os campos', Colors.red);
    return;
  }

  DatabaseHelper().createUser(name, surname, password).then((_) {
    final lastAccountId = Hive.box('users').length;
    const agency = '0001';
    final account = lastAccountId.toString().padLeft(5, '0');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Credenciais de Acesso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Agência: $agency'),
              Text('Conta: $account'),
              const SizedBox(height: 10),
              const Text(
                'Por favor, anote suas credenciais.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final user = {
                  'name': name,
                  'surname': surname,
                  'agency': agency,
                  'account': account,
                  'balance': 0.0,
                };
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(user: user),
                  ),
                );
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }).catchError((error) {
    _showSnackBar('Erro ao criar usuário: $error', Colors.red);
  });
}

void _login(String agency, String account, String password) {
  final user = DatabaseHelper().loginUser(agency, account, password);
  if (user != null) {
    _showSnackBar('Acesso concedido', Colors.green);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(user: user),
      ),
    );
  } else {
    _showSnackBar('Dados incorretos', Colors.red);
  }
}

  void _showRegisterDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController surnameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cadastro de Usuário'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: surnameController,
                decoration: const InputDecoration(labelText: 'Sobrenome'),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    surnameController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  _register(
                    nameController.text,
                    surnameController.text,
                    passwordController.text,
                  );
                  _showSnackBar(
                      'Usuário cadastrado com sucesso', Colors.green);
                  Navigator.of(context).pop();
                } else {
                  _showSnackBar('Preencha todos os campos', Colors.red);
                }
              },
              child: const Text('Cadastrar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 800,
            child: Card(
              elevation: 5,
              color: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 800,
                    height: 40,
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15)),
                        color: Colors.deepPurple),
                    child: const Center(
                      child: Text(
                        'R.Bank',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _agencyController,
                          decoration: InputDecoration(
                            labelText: 'Agência',
                            errorText:
                                _validateAgency ? 'Campo obrigatório' : null,
                          ),
                        ),
                        TextField(
                          controller: _accountController,
                          decoration: InputDecoration(
                            labelText: 'Conta',
                            errorText:
                                _validateAccount ? 'Campo obrigatório' : null,
                          ),
                        ),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            errorText:
                                _validatePassword ? 'Campo obrigatório' : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _login(
                            _agencyController.text,
                            _accountController.text,
                            _passwordController.text,
                          ),
                          child: const Text('Entrar'),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [TextButton(onPressed: _showRegisterDialog, child: const Text('Ainda não possui uma conta?'))],)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
