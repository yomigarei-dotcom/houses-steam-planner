import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginRequested extends AuthEvent {}

class AuthCallbackReceived extends AuthEvent {
  final String token;
  AuthCallbackReceived(this.token);

  @override
  List<Object?> get props => [token];
}

class LogoutRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class LoginUrlReady extends AuthState {
  final String url;
  LoginUrlReady(this.url);

  @override
  List<Object?> get props => [url];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<AuthCallbackReceived>(_onAuthCallbackReceived);
    on<LogoutRequested>(_onLogoutRequested);
  }

  User? get currentUser => _authRepository.currentUser;

  Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.checkExistingSession();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final url = await _authRepository.getLoginUrl();
      emit(LoginUrlReady(url));
    } catch (e) {
      emit(AuthError('Failed to get login URL: ${e.toString()}'));
    }
  }

  Future<void> _onAuthCallbackReceived(AuthCallbackReceived event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.handleAuthCallback(event.token);
      final user = _authRepository.currentUser;
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(AuthError('Failed to fetch user'));
      }
    } catch (e) {
      emit(AuthError('Auth callback failed: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(Unauthenticated());
  }
}
