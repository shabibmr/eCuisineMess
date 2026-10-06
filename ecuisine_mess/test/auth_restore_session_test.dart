import 'package:bloc_test/bloc_test.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/network/session_token_holder.dart';
import 'package:ecuisine_mess/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ecuisine_mess/features/auth/data/datasources/session_local_datasource.dart';
import 'package:ecuisine_mess/features/auth/data/models/user_model.dart';
import 'package:ecuisine_mess/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ecuisine_mess/features/auth/domain/entities/app_user.dart';
import 'package:ecuisine_mess/features/auth/domain/repositories/auth_repository.dart';
import 'package:ecuisine_mess/features/auth/domain/usecases/login.dart';
import 'package:ecuisine_mess/features/auth/domain/usecases/logout.dart';
import 'package:ecuisine_mess/features/auth/domain/usecases/restore_session.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements AuthRemoteDataSource {}

class MockLocal extends Mock implements SessionLocalDataSource {}

class MockRepository extends Mock implements AuthRepository {}

const _user = AppUser(id: '1', username: 'admin', displayName: 'Admin');

void main() {
  group('AuthRepositoryImpl.restoreSession', () {
    late MockRemote remote;
    late MockLocal local;
    late SessionTokenHolder holder;
    late AuthRepositoryImpl repo;

    setUp(() {
      remote = MockRemote();
      local = MockLocal();
      holder = SessionTokenHolder();
      repo = AuthRepositoryImpl(
        remote: remote,
        local: local,
        sessionTokenHolder: holder,
      );
      when(() => local.readToken()).thenAnswer((_) async => 'tok');
      when(() => local.clearToken()).thenAnswer((_) async {});
    });

    test('returns user and keeps token on success', () async {
      when(() => remote.fetchMe('tok')).thenAnswer(
        (_) async => const UserModel(
          id: '1',
          username: 'admin',
          displayName: 'Admin',
        ),
      );

      expect(await repo.restoreSession(), _user);
      expect(holder.token, 'tok');
      verifyNever(() => local.clearToken());
    });

    test('clears saved token when server says 401', () async {
      when(() => remote.fetchMe('tok'))
          .thenThrow(const UnauthorizedException());

      expect(await repo.restoreSession(), isNull);
      expect(holder.token, isNull);
      verify(() => local.clearToken()).called(1);
    });

    test('keeps saved token when server is unreachable', () async {
      when(() => remote.fetchMe('tok')).thenThrow(const NetworkException());

      await expectLater(
        repo.restoreSession(),
        throwsA(isA<NetworkFailure>()),
      );
      expect(holder.token, isNull);
      verifyNever(() => local.clearToken());
    });

    test('keeps saved token on 5xx', () async {
      when(() => remote.fetchMe('tok'))
          .thenThrow(const ServerException('boom', 503));

      await expectLater(
        repo.restoreSession(),
        throwsA(isA<ServerFailure>()),
      );
      verifyNever(() => local.clearToken());
    });

    test('returns null without calling server when no saved token', () async {
      when(() => local.readToken()).thenAnswer((_) async => null);

      expect(await repo.restoreSession(), isNull);
      verifyNever(() => remote.fetchMe(any()));
    });
  });

  group('AuthBloc AuthStarted', () {
    late MockRepository repository;
    late SessionTokenHolder holder;

    AuthBloc build() => AuthBloc(
          restoreSession: RestoreSession(repository),
          login: Login(repository),
          logout: Logout(repository),
          authRepository: repository,
          sessionTokenHolder: holder,
        );

    setUp(() {
      repository = MockRepository();
      holder = SessionTokenHolder();
    });

    blocTest<AuthBloc, AuthState>(
      'emits Authenticated when session restores',
      build: () {
        when(() => repository.restoreSession()).thenAnswer((_) async => _user);
        when(() => repository.currentToken).thenReturn('tok');
        return build();
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [
        const AuthUnknown(),
        const Authenticated(user: _user, token: 'tok'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits Unauthenticated with message when server is unreachable',
      build: () {
        when(() => repository.restoreSession())
            .thenThrow(const NetworkFailure());
        return build();
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [
        const AuthUnknown(),
        const Unauthenticated(message: 'Server unreachable'),
      ],
      verify: (_) {
        expect(holder.token, isNull);
        verifyNever(() => repository.clearLocalSession());
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits Unauthenticated without message when no session',
      build: () {
        when(() => repository.restoreSession()).thenAnswer((_) async => null);
        when(() => repository.currentToken).thenReturn(null);
        return build();
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthUnknown(), const Unauthenticated()],
    );
  });
}
