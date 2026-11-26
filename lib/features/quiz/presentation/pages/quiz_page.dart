import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/quiz_bloc.dart';
import '../bloc/quiz_event.dart';
import '../bloc/quiz_state.dart';

/// Multiple-choice quiz screen with revision pinning and atomic draft auto-saving
class QuizPage extends StatefulWidget {
  final String lessonId;
  final String revisionId;

  const QuizPage({
    super.key,
    required this.lessonId,
    this.revisionId = 'rev_1_0',
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  @override
  void initState() {
    super.initState();
    context.read<QuizBloc>().add(
      StartQuiz(lessonId: widget.lessonId, revisionId: widget.revisionId),
    );
  }

  void _showRevisionMismatchDialog(
    BuildContext context,
    QuizRevisionMismatch mismatch,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lesson Revision Changed'),
        content: Text(
          'A newer lesson revision (${mismatch.currentRevisionId}) is available. '
          'Your existing saved draft is associated with ${mismatch.draftRevisionId}.\n\n'
          'Would you like to reset your draft to start the new revision, or continue your saved draft?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<QuizBloc>().add(
                const RevisionMismatchResolved(resetDraft: false),
              );
            },
            child: const Text('Keep Draft'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<QuizBloc>().add(
                const RevisionMismatchResolved(resetDraft: true),
              );
            },
            child: const Text('Start Fresh'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<QuizBloc, QuizState>(
      listener: (context, state) {
        if (state is QuizRevisionMismatch) {
          _showRevisionMismatchDialog(context, state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Lesson Quiz'),
            actions: [
              if (state is QuizInProgress) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.isSaving
                            ? Icons.sync
                            : (state.isSavedOffline
                                  ? Icons.cloud_done_outlined
                                  : Icons.cloud_off_outlined),
                        size: 18,
                        color: state.isSaving
                            ? colorScheme.primary
                            : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        state.isSaving
                            ? 'Saving...'
                            : (state.isSavedOffline
                                  ? 'Draft saved'
                                  : 'Unsaved'),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, QuizState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state is QuizLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is QuizError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            state.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      );
    }

    if (state is QuizInProgress) {
      final currentQuestion = state.currentQuestion;
      final selectedOptionId = state.answers[currentQuestion.id];

      return SafeArea(
        child: Column(
          children: [
            // Question Progress Header & Chips
            Container(
              padding: const EdgeInsets.all(16.0),
              color: colorScheme.surfaceContainerHighest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${state.currentIndex + 1} of ${state.totalQuestions}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Answered: ${state.answeredCount}/${state.totalQuestions}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(state.totalQuestions, (index) {
                      final isCurrent = index == state.currentIndex;
                      final isAnswered = state.isQuestionAnswered(index);

                      return GestureDetector(
                        onTap: () {
                          context.read<QuizBloc>().add(JumpToQuestion(index));
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? colorScheme.primary
                                : (isAnswered
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surface),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCurrent
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? colorScheme.onPrimary
                                  : (isAnswered
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurface),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Question Text and Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text(
                    currentQuestion.text,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...currentQuestion.options.map((option) {
                    final isSelected = selectedOptionId == option.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: isSelected ? 2 : 0,
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          context.read<QuizBloc>().add(
                            AnswerSelected(
                              questionId: currentQuestion.id,
                              optionId: option.id,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option.text,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Bottom Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: state.currentIndex > 0
                        ? () => context.read<QuizBloc>().add(
                            const PreviousQuestion(),
                          )
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                  if (state.currentIndex < state.totalQuestions - 1)
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<QuizBloc>().add(const NextQuestion()),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    )
                  else
                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Quiz progress saved offline. Final submission sync will be enabled in Phase 3B.',
                            ),
                          ),
                        );
                      },
                      child: const Text('Review & Save'),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
