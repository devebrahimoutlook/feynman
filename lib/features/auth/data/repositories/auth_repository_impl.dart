import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:feynman/core/error/app_exception.dart';
import 'package:feynman/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:feynman/features/auth/domain/entities/auth_state.dart'
    as entity;
import 'package:feynman/features/auth/domain/entities/user_profile.dart';
import 'package:feynman/features/auth/domain/repositories/auth_repository.dart';
import 'package:feynman/core/logging/app_logger.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;
  final AppLogger logger;

  AuthRepositoryImpl(this.remoteDatasource, this.logger);

  @override
  Stream<entity.AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final profile = await remoteDatasource.signInWithEmail(
        email: email,
        password: password,
      );
      logger.info('AuthRepository', 'User signed in with email', {
        'id': profile.id,
      });
      return profile;
    } on supa.AuthException catch (e, st) {
      logger.error('AuthRepository', 'Sign in failed', e, st);
      throw AuthException(message: e.message);
    } catch (e, st) {
      logger.error('AuthRepository', 'Sign in failed unexpectedly', e, st);
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final profile = await remoteDatasource.signUpWithEmail(
        email: email,
        password: password,
      );
      logger.info('AuthRepository', 'User registered with email', {
        'id': profile.id,
      });
      return profile;
    } on supa.AuthException catch (e, st) {
      // T017a [US1] Handle EC-001 "User already registered" error
      if (e.message.contains('User already registered') ||
          e.message.contains('already exists')) {
        logger.warning(
          'AuthRepository',
          'Registration blocked: account exists',
        );
        throw const AuthException(message: 'Account exists — please log in');
      }
      logger.error('AuthRepository', 'Registration failed', e, st);
      throw AuthException(message: e.message);
    } catch (e, st) {
      logger.error('AuthRepository', 'Registration failed unexpectedly', e, st);
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    try {
      final profile = await remoteDatasource.signInWithGoogle();
      logger.info('AuthRepository', 'User signed in with Google', {
        'id': profile.id,
      });
      return profile;
    } on supa.AuthException catch (e, st) {
      logger.error('AuthRepository', 'Google sign in failed', e, st);
      throw AuthException(message: e.message);
    } catch (e, st) {
      logger.error(
        'AuthRepository',
        'Google sign in failed unexpectedly',
        e,
        st,
      );
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await remoteDatasource.resetPassword(email: email);
      logger.info('AuthRepository', 'Password reset requested');
    } on supa.AuthException catch (e, st) {
      logger.error('AuthRepository', 'Password reset failed', e, st);
      throw AuthException(message: e.message);
    } catch (e, st) {
      logger.error(
        'AuthRepository',
        'Password reset failed unexpectedly',
        e,
        st,
      );
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    return remoteDatasource.getCurrentUser();
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDatasource.signOut();
      logger.info('AuthRepository', 'User signed out');
    } catch (e, st) {
      logger.error('AuthRepository', 'Sign out failed', e, st);
      rethrow;
    }
  }
}
