import 'package:feynman/core/providers/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feynman/core/providers/supabase_provider.dart';
import 'package:feynman/core/providers/database_provider.dart';
import 'package:feynman/features/auth/domain/repositories/profile_repository.dart';
import 'package:feynman/features/auth/data/datasources/profile_local_datasource.dart';
import 'package:feynman/features/auth/data/datasources/profile_remote_datasource.dart';
import 'package:feynman/features/auth/data/repositories/profile_repository_impl.dart';

part 'profile_provider.g.dart';

@riverpod
// ignore: deprecated_member_use_from_same_package
ProfileLocalDatasource profileLocalDatasource(ProfileLocalDatasourceRef ref) {
  final db = ref.watch(databaseProvider);
  return ProfileLocalDatasourceImpl(db);
}

@riverpod
// ignore: deprecated_member_use_from_same_package
ProfileRemoteDatasource profileRemoteDatasource(
  // ignore: deprecated_member_use_from_same_package
  ProfileRemoteDatasourceRef ref,
) {
  final supabase = ref.watch(supabaseProvider);
  if (supabase == null) throw Exception('Supabase not initialized');
  return ProfileRemoteDatasourceImpl(supabase);
}

@riverpod
// ignore: deprecated_member_use_from_same_package
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepositoryImpl(
    localDatasource: ref.watch(profileLocalDatasourceProvider),
    remoteDatasource: ref.watch(profileRemoteDatasourceProvider),
    supabaseClient: ref.watch(supabaseProvider)!,
    logger: ref.watch(loggerProvider),
  );
}
