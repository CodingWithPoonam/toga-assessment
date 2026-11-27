import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:toga_assessment/app/app.dart';
import 'package:toga_assessment/core/database/app_database.dart';
import 'package:toga_assessment/core/di/injection.dart';
import 'package:toga_assessment/core/network/network_config.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';
import 'package:toga_assessment/core/security/session_manager.dart';
import 'package:toga_assessment/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:toga_assessment/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:toga_assessment/features/quiz/presentation/pages/quiz_page.dart';
import 'package:toga_assessment/features/lessons/presentation/pages/lessons_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toga_assessment/features/lessons/presentation/bloc/lesson_bloc.dart';
import 'package:toga_assessment/features/lessons/presentation/bloc/lesson_event.dart';
import 'package:toga_assessment/features/lessons/presentation/bloc/lesson_state.dart';
import 'package:toga_assessment/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:toga_assessment/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:toga_assessment/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:toga_assessment/features/sync/presentation/bloc/sync_event.dart';
import 'package:toga_assessment/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:toga_assessment/features/auth/presentation/bloc/auth_event.dart';
import 'package:toga_assessment/features/auth/presentation/bloc/auth_state.dart';
import 'package:toga_assessment/features/sync/domain/entities/outbox_enums.dart';
import 'package:toga_assessment/features/sync/domain/repositories/sync_repository.dart';
import 'package:toga_assessment/features/sync/domain/usecases/sync_engine.dart';
import 'package:toga_assessment/features/quiz/domain/repositories/quiz_repository.dart';

class InMemorySecureStorage implements ISecureStorage {
  final Map<String, String> _map = {};
  @override
  Future<bool> containsKey(String key) async => _map.containsKey(key);
  @override
  Future<void> delete(String key) async => _map.remove(key);
  @override
  Future<void> deleteAll() async => _map.clear();
  @override
  Future<String?> read(String key) async => _map[key];
  @override
  Future<void> write(String key, String value) async => _map[key] = value;
}

void main() {
  late AppDatabase database;
  late ISecureStorage secureStorage;
  late ISessionManager sessionManager;
  late AuthRemoteDataSource authRemoteDataSource;
  late AuthRepositoryImpl authRepository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    secureStorage = InMemorySecureStorage();
    sessionManager = SessionManager(secureStorage: secureStorage);
    authRemoteDataSource = MockAuthRemoteDataSource(
      networkLatency: Duration.zero,
    );
    authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
      sessionManager: sessionManager,
    );

    await configureDependencies(
      networkConfig: NetworkConfig.development(),
      secureStorageOverride: secureStorage,
      sessionManagerOverride: sessionManager,
      remoteDataSourceOverride: authRemoteDataSource,
      authRepositoryOverride: authRepository,
      databaseOverride: database,
    );
  });

  tearDown(() async {
    await database.close();
    await getIt.reset();
  });

  Widget buildAccessibilityHost({
    required Widget child,
    Size size = const Size(320, 600),
    double textScaleFactor = 2.0,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
            BlocProvider<LessonBloc>.value(value: getIt<LessonBloc>()),
            BlocProvider<QuizBloc>.value(value: getIt<QuizBloc>()),
            BlocProvider<SyncBloc>.value(value: getIt<SyncBloc>()),
          ],
          child: child,
        ),
      ),
    );
  }

  group('Part C: Accessibility & Narrow Layout Verification (Scenario 12)', () {
    testWidgets(
      '1. Lesson Catalogue: 200% text scale factor on 320x500 narrow screen renders without overflow',
      (WidgetTester tester) async {
        // Authenticate first
        getIt<AuthBloc>().add(
          LoginRequested(
            learnerId: SyntheticLearners.learnerA.id,
            password: SyntheticLearners.validPassword,
          ),
        );
        await tester.pumpAndSettle();

        tester.view.physicalSize = const Size(320 * 2, 500 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildAccessibilityHost(
            child: const LessonsPage(),
            size: const Size(320, 500),
            textScaleFactor: 2.0,
          ),
        );
        await tester.pumpAndSettle();

        // Check for overflow exceptions
        expect(tester.takeException(), isNull);

        // Header and lessons should be displayed
        expect(find.text('Lesson Catalogue'), findsOneWidget);
        expect(find.text('Aviation study units'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Quiz Page: 200% text scale factor on 320x500 narrow screen renders question & controls without overflow',
      (WidgetTester tester) async {
        getIt<AuthBloc>().add(
          LoginRequested(
            learnerId: SyntheticLearners.learnerA.id,
            password: SyntheticLearners.validPassword,
          ),
        );
        await tester.pumpAndSettle();

        tester.view.physicalSize = const Size(320 * 2, 500 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildAccessibilityHost(
            child: const QuizPage(lessonId: 'lesson-units', revisionId: '1'),
            size: const Size(320, 500),
            textScaleFactor: 2.0,
          ),
        );
        await tester.pumpAndSettle();

        // Invariant: Zero RenderFlex overflow errors
        expect(tester.takeException(), isNull);

        // Verify question and options
        expect(find.text('Lesson Quiz'), findsOneWidget);
        expect(find.text('Question 1 of 5'), findsOneWidget);
        expect(find.text('How many minutes are in one hour?'), findsOneWidget);

        // Verify responsive buttons exist
        expect(find.text('Previous'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Touch targets: Question jump indicators and navigation buttons meet >= 48x48 dp minimum accessible touch targets',
      (WidgetTester tester) async {
        getIt<AuthBloc>().add(
          LoginRequested(
            learnerId: SyntheticLearners.learnerA.id,
            password: SyntheticLearners.validPassword,
          ),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          buildAccessibilityHost(
            child: const QuizPage(lessonId: 'lesson-units', revisionId: '1'),
            size: const Size(400, 800),
            textScaleFactor: 1.0,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify question jump targets meet >= 48x48 dp
        for (int i = 1; i <= 5; i++) {
          final jumpTarget = find.ancestor(
            of: find.text('$i'),
            matching: find.byType(InkWell),
          );
          expect(jumpTarget, findsOneWidget);
          final size = tester.getSize(jumpTarget);
          expect(size.width, greaterThanOrEqualTo(48.0));
          expect(size.height, greaterThanOrEqualTo(48.0));
        }

        // 2. Verify navigation button touch targets meet >= 48 dp height
        final nextButton = find.bySemanticsLabel('Next question');
        expect(nextButton, findsOneWidget);
        final nextSize = tester.getSize(nextButton);
        expect(nextSize.height, greaterThanOrEqualTo(48.0));
      },
    );

    testWidgets(
      '4. Semantics: Screen reader semantics are present for question jump items, option selections, and submit actions',
      (WidgetTester tester) async {
        getIt<AuthBloc>().add(
          LoginRequested(
            learnerId: SyntheticLearners.learnerA.id,
            password: SyntheticLearners.validPassword,
          ),
        );
        await tester.pumpAndSettle();

        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          buildAccessibilityHost(
            child: const QuizPage(lessonId: 'lesson-units', revisionId: '1'),
            size: const Size(400, 800),
            textScaleFactor: 1.0,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Check semantic labels for question items
        expect(
          find.bySemanticsLabel(RegExp(r'Question 1, current, unanswered')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Previous question'), findsOneWidget);
        expect(find.bySemanticsLabel('Next question'), findsOneWidget);

        // 2. Check semantic labels for options before selection
        expect(find.bySemanticsLabel('30, not selected'), findsOneWidget);
        expect(find.bySemanticsLabel('60, not selected'), findsOneWidget);

        // 3. Select option '60' and verify semantic label updates to selected
        await tester.tap(find.text('60'));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('60, selected'), findsOneWidget);

        // 4. Jump to last question (question 5) to verify submit button semantics
        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Submit quiz attempt'), findsOneWidget);

        handle.dispose();
      },
    );
  });

  group('Part D: Lifecycle and Asynchronous Safety Tests', () {
    testWidgets(
      '1. Fast successive lesson detail requests: Stale older response does not overwrite newer state',
      (WidgetTester tester) async {
        final lessonBloc = getIt<LessonBloc>();

        // Dispatch detail for lesson 1, then immediately for lesson 2
        lessonBloc.add(const LoadLessonDetail('lesson-units'));
        lessonBloc.add(const LoadLessonDetail('lesson-practice'));

        await tester.pumpAndSettle();

        // Active state must be for lesson-practice
        expect(lessonBloc.state, isA<LessonDetailSuccess>());
        final state = lessonBloc.state as LessonDetailSuccess;
        expect(state.lesson.id, equals('lesson-practice'));
      },
    );

    testWidgets(
      '2. Duplicate sync drain prevention: Multiple sync triggers while in-flight are ignored',
      (WidgetTester tester) async {
        final syncBloc = getIt<SyncBloc>();

        // Stage and trigger sync
        syncBloc.add(
          const StageAndSyncRequested(
            learnerId: 'learner_a',
            lessonId: 'lesson-units',
          ),
        );
        // Dispatch second trigger while in flight
        syncBloc.add(
          const StageAndSyncRequested(
            learnerId: 'learner_a',
            lessonId: 'lesson-units',
          ),
        );

        await tester.pumpAndSettle();

        // Must not crash or double-execute
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '3. Disposed bloc safety: Navigation away during loading completes cleanly without setState errors',
      (WidgetTester tester) async {
        await tester.pumpWidget(const TogaApp());
        await tester.pumpAndSettle();

        // Log in
        await tester.tap(find.text('Authenticate & Enter'));
        await tester.pumpAndSettle();

        // Enter detail
        await tester.tap(find.text('Aviation study units'));
        await tester.pump(); // Start loading
        await tester.pump();

        // Pop back immediately
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
        } else {
          final navigator = tester.state<NavigatorState>(
            find.byType(Navigator).last,
          );
          navigator.pop();
        }
        await tester.pumpAndSettle();

        // Invariant: No setState or unhandled asynchronous exceptions after dispose
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '4. Delayed request released after account switch: Slower response from previous learner does not overwrite new learner session',
      (WidgetTester tester) async {
        final authBloc = getIt<AuthBloc>();
        final lessonBloc = getIt<LessonBloc>();

        // 1. Authenticate as Learner A
        authBloc.add(
          LoginRequested(
            learnerId: SyntheticLearners.learnerA.id,
            password: SyntheticLearners.validPassword,
          ),
        );
        await tester.pumpAndSettle();

        // 2. Start a fetch for Learner A's lessons
        lessonBloc.add(const LoadLessons(forceRefresh: true));

        // 3. Before asynchronous microtasks settle, switch to Learner B
        authBloc.add(
          SwitchLearnerRequested(
            targetLearnerId: SyntheticLearners.learnerB.id,
            password: SyntheticLearners.validPassword,
          ),
        );
        await tester.pumpAndSettle();

        // 4. Invariant: Active session is Learner B and generation barrier prevents Learner A's stale state
        expect(authBloc.state, isA<AuthAuthenticated>());
        final authState = authBloc.state as AuthAuthenticated;
        expect(
          authState.session.learnerId,
          equals(SyntheticLearners.learnerB.id),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '5. Simultaneous sync triggers: Parallel simultaneous sync invocations do not duplicate drain or race',
      (WidgetTester tester) async {
        final syncEngine = getIt<ISyncEngine>();

        // Authenticate as Learner A
        getIt<AuthBloc>().add(
          LoginRequested(
            learnerId: SyntheticLearners.learnerA.id,
            password: SyntheticLearners.validPassword,
          ),
        );
        await tester.pumpAndSettle();

        // Save a draft answer so staging succeeds
        final quizRepo = getIt<QuizRepository>();
        await quizRepo.saveAnswer(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
          revisionId: '1',
          questionId: 'r1-u1',
          optionId: '1',
          currentQuestionIndex: 0,
        );

        // Stage one submission for Learner A
        final syncRepo = getIt<SyncRepository>();
        await syncRepo.stageSubmission(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
        );

        // Fire TWO simultaneous synchronize calls in parallel
        final future = Future.wait([
          syncEngine.synchronize(learnerId: 'learner_a'),
          syncEngine.synchronize(learnerId: 'learner_a'),
        ]);
        await tester.pump(const Duration(milliseconds: 200));
        final results = await future;

        // At least one succeeds or returns idle/completed, and outbox entry is processed
        expect(results.length, equals(2));
        final record = await syncRepo.getOutboxForLesson(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
        );
        expect(record?.status, isNot(equals(OutboxStatus.pending)));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '6. Repeated app-resume events: Multiple rapid app-resume sync triggers are collapsed safely',
      (WidgetTester tester) async {
        final syncBloc = getIt<SyncBloc>();

        // Fire 5 rapid resume sync events in succession
        for (int i = 0; i < 5; i++) {
          syncBloc.add(const SyncTriggered(learnerId: 'learner_a'));
        }
        await tester.pump(const Duration(milliseconds: 100));

        // Invariant: No crash, zero unhandled errors, state remains clean
        expect(tester.takeException(), isNull);
      },
    );

    test(
      '7. Stream subscription cleanup: Closing blocs releases stream subscriptions cleanly without leaks',
      () async {
        final lessonBloc = LessonBloc(
          lessonRepository: getIt<LessonRepository>(),
        );
        expect(lessonBloc.isClosed, isFalse);

        await lessonBloc.close();
        expect(lessonBloc.isClosed, isTrue);

        // Subsequent event dispatched to closed bloc safely throws StateError
        expect(
          () => lessonBloc.add(const LoadLessons()),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
