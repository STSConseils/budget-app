import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budget_app/core/pb.dart';
import 'package:budget_app/repositories/auth_repository.dart';
import 'package:budget_app/models/category.dart';
import 'package:budget_app/models/epargne.dart';
import 'package:budget_app/models/household.dart';
import 'package:budget_app/models/perso_entry.dart';
import 'package:budget_app/models/recurrent.dart';
import 'package:budget_app/models/transaction.dart';
import 'package:budget_app/models/user_brief.dart';
import 'package:budget_app/repositories/categories_repository.dart';
import 'package:budget_app/repositories/epargne_repository.dart';
import 'package:budget_app/repositories/households_repository.dart';
import 'package:budget_app/repositories/perso_ledger_repository.dart';
import 'package:budget_app/repositories/recurrents_repository.dart';
import 'package:budget_app/repositories/transactions_repository.dart';
import 'package:budget_app/repositories/users_repository.dart';

// ─── Repository singletons ───────────────────────────────────────────────────

final authRepoProvider =
    Provider<AuthRepository>((_) => AuthRepository());

final categoriesRepoProvider =
    Provider<CategoriesRepository>((_) => CategoriesRepository());

final transactionsRepoProvider =
    Provider<TransactionsRepository>((_) => TransactionsRepository());

final recurrentsRepoProvider =
    Provider<RecurrentsRepository>((_) => RecurrentsRepository());

final epargneRepoProvider =
    Provider<EpargneRepository>((_) => EpargneRepository());

final persoLedgerRepoProvider =
    Provider<PersoLedgerRepository>((_) => PersoLedgerRepository());

final householdsRepoProvider =
    Provider<HouseholdsRepository>((_) => HouseholdsRepository());

final usersRepoProvider =
    Provider<UsersRepository>((_) => UsersRepository());

// ─── Auth & household ────────────────────────────────────────────────────────

/// Reads the current PocketBase auth record synchronously.
/// Call ref.invalidate(currentUserProvider) after login/logout.
final currentUserProvider = Provider<UserBrief?>((ref) {
  final record = pb.authStore.record;
  if (record == null) return null;
  return UserBrief.fromRecord(record);
});

/// Resolves the first household the current user belongs to.
final currentHouseholdProvider = FutureProvider<Household?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(householdsRepoProvider).current(user.id);
});

// ─── Realtime stream providers ────────────────────────────────────────────────
//
// Pattern: yield initial snapshot, open subscription, re-yield on each event.
// ref.onDispose unsubscribes and closes the controller (fire-and-forget is
// acceptable for cleanup futures).

final categoriesStreamProvider =
    StreamProvider<List<Category>>((ref) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield [];
    return;
  }
  final repo = ref.read(categoriesRepoProvider);

  yield await repo.list(household.id);

  final controller = StreamController<List<Category>>();
  final unsub = await repo.subscribe(household.id, () async {
    controller.add(await repo.list(household.id));
  });
  ref.onDispose(() {
    unsub();
    controller.close();
  });

  yield* controller.stream;
});

final transactionsStreamProvider =
    StreamProvider<List<TransactionModel>>((ref) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield [];
    return;
  }
  final repo = ref.read(transactionsRepoProvider);

  final now = DateTime.now();
  yield await repo.listForMonth(household.id, now);

  final controller = StreamController<List<TransactionModel>>();
  final unsub = await repo.subscribe(household.id, () async {
    controller.add(await repo.listForMonth(household.id, DateTime.now()));
  });
  ref.onDispose(() {
    unsub();
    controller.close();
  });

  yield* controller.stream;
});

final recurrentsStreamProvider =
    StreamProvider<List<Recurrent>>((ref) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield [];
    return;
  }
  final repo = ref.read(recurrentsRepoProvider);

  yield await repo.listActive(household.id);

  final controller = StreamController<List<Recurrent>>();
  final unsub = await repo.subscribe(household.id, () async {
    controller.add(await repo.listActive(household.id));
  });
  ref.onDispose(() {
    unsub();
    controller.close();
  });

  yield* controller.stream;
});

final epargneLatestProvider = StreamProvider<Epargne?>((ref) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield null;
    return;
  }
  final repo = ref.read(epargneRepoProvider);

  yield await repo.latest(household.id);

  final controller = StreamController<Epargne?>();
  final unsub = await repo.subscribe(household.id, () async {
    controller.add(await repo.latest(household.id));
  });
  ref.onDispose(() {
    unsub();
    controller.close();
  });

  yield* controller.stream;
});

final transactionsAnneeProvider =
    StreamProvider<List<TransactionModel>>((ref) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield [];
    return;
  }
  final repo = ref.read(transactionsRepoProvider);

  yield await repo.listForYear(household.id, DateTime.now().year);

  final controller = StreamController<List<TransactionModel>>();
  final unsub = await repo.subscribe(household.id, () async {
    controller.add(await repo.listForYear(household.id, DateTime.now().year));
  });
  ref.onDispose(() {
    unsub();
    controller.close();
  });

  yield* controller.stream;
});

final persoLedgerStreamProvider =
    StreamProvider<List<PersoEntry>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }
  final repo = ref.read(persoLedgerRepoProvider);

  yield await repo.listForUser(user.id);

  final controller = StreamController<List<PersoEntry>>();
  final unsub = await repo.subscribe(() async {
    controller.add(await repo.listForUser(user.id));
  });
  ref.onDispose(() {
    unsub();
    controller.close();
  });

  yield* controller.stream;
});
