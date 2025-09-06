import 'package:flutter/material.dart';
import 'package:myattendance/features/auth/states/account_type_handler.dart';
import 'package:myattendance/features/auth/widgets/login_form.dart';
import 'package:myattendance/features/auth/widgets/register_form.dart';
import 'package:myattendance/features/auth/widgets/user_type_selection.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AccountTypeHandler _accountTypeHandler = AccountTypeHandler();
  bool _isLogin = true;

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _onUserTypeSelected(String userType) {
    setState(() {
      _accountTypeHandler.setAccountType(userType);
    });
  }

  void _goBackToUserTypeSelection() {
    setState(() {
      _accountTypeHandler.setAccountType("");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _accountTypeHandler.accountType != ""
          ? AppBar(
              title: Text(
                _accountTypeHandler.accountType == 'student'
                    ? 'Student'
                    : 'Teacher',
                style: const TextStyle(
                  color: Color.fromARGB(255, 70, 6, 2),
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color.fromARGB(255, 70, 6, 2),
                ),
                onPressed: _goBackToUserTypeSelection,
              ),
            )
          : null,
      body: SafeArea(
        child: ChangeNotifierProvider.value(
          value: _accountTypeHandler,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_accountTypeHandler.accountType == "") ...[
                          const SizedBox(height: 32),
                          UserTypeSelection(
                            onUserTypeSelected: _onUserTypeSelected,
                          ),
                        ] else ...[
                          _isLogin ? const LoginForm() : const RegisterForm(),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _toggleAuthMode,
                            child: Text(
                              _isLogin
                                  ? 'Don\'t have an account? Sign Up'
                                  : 'Already have an account? Sign In',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
