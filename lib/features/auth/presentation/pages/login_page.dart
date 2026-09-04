import 'package:cms/core/theme/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/core/services/base_url_storage.dart';
import 'package:cms/core/di/injection_container.dart' as di;
import 'package:cms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cms/features/auth/presentation/bloc/auth_event.dart';
import 'package:cms/features/auth/presentation/bloc/auth_state.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedBaseUrl();
  }

  Future<void> _loadSavedBaseUrl() async {
    final storage = di.sl<BaseUrlStorage>();
    final savedUrl = await storage.getBaseUrl();
    if (savedUrl != null && savedUrl.isNotEmpty && mounted) {
      setState(() {
        _urlController.text = savedUrl;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated && state.errorMessage != null) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: AppColors.surface,
                title: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Login Failed',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  state.errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryText.withValues(alpha: 0.8),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryButton,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: sizeContextOf(context, 24.0),
                  vertical: sizeContextOf(context, 32.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.secondary, AppColors.accent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.engineering_rounded,
                                size: 40,
                                color: Color(0xFF27372B),
                              ),
                            ),
                          ),
                          SizedBox(height: sizeContextOf(context, 20)),
                          Text(
                            'BuildX',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                  fontSize: 44,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Developed by Quantbit Technologies',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.primaryText.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          SizedBox(height: sizeContextOf(context, 12)),
                          Image.asset(
                            'assets/images/logo.png',
                            height: sizeContextOf(context, 60),
                            fit: BoxFit.contain,
                          ),
                          // SizedBox(height: sizeContextOf(context, 6)),
                          // Text(
                          //   'Secure Command Center Login',
                          //   textAlign: TextAlign.center,
                          //   style: Theme.of(context).textTheme.bodyMedium
                          //       ?.copyWith(
                          //         color: AppColors.primaryText.withValues(
                          //           alpha: 0.7,
                          //         ),
                          //       ),
                          // ),
                        ],
                      ),
                    ),
                    SizedBox(height: sizeContextOf(context, 40)),

                    // Login Card
                    Card(
                      elevation: 0,
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: AppColors.outlineVariant,
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: sizeContextOf(context, 20.0),
                          vertical: sizeContextOf(context, 28.0),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Sign In',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryText,
                                    ),
                              ),
                              SizedBox(height: sizeContextOf(context, 14)),
                              TextFormField(
                                controller: _urlController,
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Server URL',
                                  prefixIcon: Icon(Icons.cloud_outlined),
                                  hintText: 'https://your-site.frappe.cloud',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Server URL is required';
                                  }
                                  if (!BaseUrlStorage.isValidUrl(value.trim())) {
                                    return 'Please enter a valid URL';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: sizeContextOf(context, 20)),
                              TextFormField(
                                controller: _usernameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email ID',
                                  prefixIcon: Icon(Icons.person_outline),
                                  hintText: 'Enter your Email ID',
                                ),
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Email ID is required'
                                    : null,
                              ),
                              SizedBox(height: sizeContextOf(context, 20)),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  hintText: 'Enter your password',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.primaryText.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Password is required'
                                    : null,
                              ),
                              SizedBox(height: sizeContextOf(context, 28)),
                              ElevatedButton(
                                onPressed: state is AuthLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState?.validate() ??
                                            false) {
                                          context.read<AuthBloc>().add(
                                            LoginSubmitted(
                                              _urlController.text.trim(),
                                              _usernameController.text.trim(),
                                              _passwordController.text,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryButton,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: state is AuthLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('LOGIN'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primaryText.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 11,
                              ),
                          children: [
                            const TextSpan(text: 'Developed & Maintained by '),
                            TextSpan(
                              text: 'Quantbit Technologies Pvt Ltd',
                              style: const TextStyle(
                                color: AppColors.primaryButton,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  final url = Uri.parse('https://quantbit.io/');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                            ),
                            const TextSpan(
                              text: ' , 2026 All Rights Reserved V1.0.0',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Center(
                    //   child: Column(
                    //     children: [
                    //       Text(
                    //         'Team Quantbit',
                    //         style: Theme.of(context).textTheme.bodySmall
                    //             ?.copyWith(
                    //               color: AppColors.primaryText.withValues(
                    //                 alpha: 0.8,
                    //               ),
                    //               fontWeight: FontWeight.bold,
                    //               fontSize: 11,
                    //             ),
                    //       ),
                    //       const SizedBox(height: 2),
                    //       RichText(
                    //         textAlign: TextAlign.center,
                    //         text: TextSpan(
                    //           style: Theme.of(context).textTheme.bodySmall
                    //               ?.copyWith(
                    //                 color: AppColors.primaryText.withValues(
                    //                   alpha: 0.6,
                    //                 ),
                    //                 fontSize: 11,
                    //               ),
                    //           // children: [
                    //           //   const TextSpan(text: 'Phone: '),
                    //           //   TextSpan(
                    //           //     text: '+91 966 55 98 341',
                    //           //     style: const TextStyle(
                    //           //       color: AppColors.primaryButton,
                    //           //       decoration: TextDecoration.underline,
                    //           //     ),
                    //           //     recognizer: TapGestureRecognizer()
                    //           //       ..onTap = () async {
                    //           //         final url = Uri.parse('tel:+919665598341');
                    //           //         if (await canLaunchUrl(url)) {
                    //           //           await launchUrl(url);
                    //           //         }
                    //           //       },
                    //           //   ),
                    //           // ],
                    //           //   ),
                    //           // ),
                    //           // const SizedBox(height: 2),
                    //           // RichText(
                    //           //   textAlign: TextAlign.center,
                    //           //   text: TextSpan(
                    //           //     style: Theme.of(context).textTheme.bodySmall
                    //           //         ?.copyWith(
                    //           //           color: AppColors.primaryText.withValues(
                    //           //             alpha: 0.6,
                    //           //           ),
                    //           //           fontSize: 11,
                    //           //         ),
                    //           // children: [
                    //           //   const TextSpan(text: 'Web: '),
                    //           //   TextSpan(
                    //           //     text: 'www.quantbit.io',
                    //           //     style: const TextStyle(
                    //           //       color: AppColors.primaryButton,
                    //           //       decoration: TextDecoration.underline,
                    //           //     ),
                    //           //     recognizer: TapGestureRecognizer()
                    //           //       ..onTap = () async {
                    //           //         final url = Uri.parse(
                    //           //           'https://www.quantbit.io',
                    //           //         );
                    //           //         if (await canLaunchUrl(url)) {
                    //           //           await launchUrl(
                    //           //             url,
                    //           //             mode: LaunchMode.externalApplication,
                    //           //           );
                    //           //         }
                    //           //       },
                    //           //   ),
                    //           // ],
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
