import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String url;
  final String username;
  final String password;

  const LoginSubmitted(this.url, this.username, this.password);

  @override
  List<Object?> get props => [url, username, password];
}

class LogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class SessionExpired extends AuthEvent {
  final String message;
  const SessionExpired(this.message);

  @override
  List<Object?> get props => [message];
}
