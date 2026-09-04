import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cms/core/di/injection_container.dart' as di;
import 'package:cms/core/theme/app_theme.dart';
import 'package:cms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cms/features/auth/presentation/bloc/auth_event.dart';
import 'package:cms/features/auth/presentation/bloc/auth_state.dart';
import 'package:cms/features/auth/presentation/pages/login_page.dart';
import 'package:cms/features/home/presentation/pages/main_navigation_shell.dart';
import 'package:cms/features/projects/presentation/bloc/project_bloc.dart';
import 'package:cms/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:cms/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:cms/core/services/project_selection_service.dart';
import 'package:cms/core/error/session_manager.dart';
import 'package:cms/core/services/http_overrides.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = SessionTimeoutHttpOverrides();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
      child: MaterialApp(
        title: 'ConstructionMS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppContent(),
      ),
    );
  }
}

class AppContent extends StatefulWidget {
  const AppContent({super.key});

  @override
  State<AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<AppContent> {
  StreamSubscription? _logoutSubscription;

  @override
  void initState() {
    super.initState();
    _logoutSubscription = SessionManager.logoutStream.listen((message) {
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Permission Denied',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: const Text(
                  'You are not permitted to access this resource, or your session has expired. You will be logged out.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      context.read<AuthBloc>().add(SessionExpired(message));
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Color(0xFF4A8B5F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _logoutSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    di.sl<ProjectBloc>()..add(GetProjectsRequested()),
              ),
              BlocProvider(
                create: (context) => di.sl<ApprovalsBloc>()
                  ..add(LoadApprovals(
                    project: di.sl<ProjectSelectionService>().selectedProject,
                  )),
              ),
            ],
            child: const MainNavigationShell(),
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
