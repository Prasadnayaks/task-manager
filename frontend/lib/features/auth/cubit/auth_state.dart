part of "auth_cubit.dart";

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthSignUp extends AuthState {}

final class AuthLoggedIn extends AuthState {
  final UserModel user;
  AuthLoggedIn(this.user);
}

final class AuthError extends AuthState {
  final String error;
  AuthError(this.error);
}

// Add this new state
final class AuthLoggedOut extends AuthState {}