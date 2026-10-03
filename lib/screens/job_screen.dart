import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../models/convert_options.dart';
import '../models/job.dart';
import '../models/media_item.dart';
import '../providers/queue_provider.dart';
import '../utils/format_utils.dart';
import '../widgets/pressable.dart';
import '../widgets/section_card.dart';

/// Conversion progress screen — shows one or many [Job] cards with live
/// progress bars, a cancel button, and a done state with share/open actions.
///
/// Navigation: pushed by StudioScreen / BatchStudioScreen after calling
/// `QueueProvider.start(items, options)`.
class JobScreen extends StatefulWidget {
  const JobScreen({
    super.key,
    required this.items,
    required this.options,
  });

  final List<MediaItem> items;
  final ConvertOptions options;

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Start conversion on first frame so the provider is available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    await context.read<QueueProvider>().start(widget.items, widget.options);
  }

  @override
  Widget build(BuildContext context) {
    final peel = context.peel;
    final queue = context.watch<QueueProvider>();
    final jobs = queue.jobs;
    final allDone = queue.allFinished;

    return Scaffold(
      backgroundColor: peel.canvas,
      appBar: AppBar(
        backgroundColor: peel.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: peel.ink),
        title: Text(
          allDone ? 'Conversion Done' : 'Converting…',
          style: TextStyle(
            fontFamily: Fonts.sans,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: peel.ink,
          ),
        ),
        actions: [
          if (!allDone && queue.isRunning)
            TextButton(
              onPressed: () {
                Haptics.warn();
                queue.cancelAll();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: peel.danger),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Overall progress bar ─────────────────────────────────
          if (!allDone)
            LinearProgressIndicator(
              value: queue.overallProgress,
              backgroundColor: peel.surfaceHi,
              valueColor: AlwaysStoppedAnimation<Color>(peel.peel),
              minHeight: 3,
            ),

          // ── Job list ─────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.lg,
                Space.gutter,
                Space.xxl,
              ),
              itemCount: jobs.isEmpty ? 1 : jobs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: Space.sm),
              itemBuilder: (context, i) {
                if (jobs.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(color: peel.peel),
                  );
                }
                return _JobCard(job: jobs[i]);
              },
            ),
          ),

          // ── Done CTA ─────────────────────────────────────────────
          if (allDone)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.sm,
                  Space.gutter,
                  Space.lg,
                ),
                child: Pressable(
                  onTap: () {
                    Haptics.success();
                    queue.clear();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: peel.peelGradient,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontFamily: Fonts.sans,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: peel.onPeel,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Individual job card ───────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final peel = context.peel;
    final isDone = job.status == JobStatus.done;
    final isFailed = job.status == JobStatus.failed;
    final isCancelled = job.status == JobStatus.cancelled;
    final isRunning = job.status == JobStatus.running;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (isDone) {
      statusColor = peel.groove;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Done';
    } else if (isFailed) {
      statusColor = peel.danger;
      statusIcon = Icons.error_rounded;
      statusLabel = job.error ?? 'Failed';
    } else if (isCancelled) {
      statusColor = peel.inkMuted;
      statusIcon = Icons.cancel_rounded;
      statusLabel = 'Cancelled';
    } else if (isRunning) {
      statusColor = peel.peel;
      statusIcon = Icons.pending_rounded;
      statusLabel =
          '${(job.progress * 100).toStringAsFixed(0)}%';
    } else {
      statusColor = peel.inkFaint;
      statusIcon = Icons.hourglass_empty_rounded;
      statusLabel = 'Queued';
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── File name + status icon ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  job.outputName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: Fonts.sans,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: peel.ink,
                  ),
                ),
              ),
              const SizedBox(width: Space.xs),
              Icon(statusIcon, size: 18, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusLabel,
                style: TextStyle(
                  fontFamily: Fonts.sans,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: statusColor,
                ),
              ),
            ],
          ),

          // ── Progress bar ─────────────────────────────────────────
          if (isRunning) ...[
            const SizedBox(height: Space.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: LinearProgressIndicator(
                value: job.progress,
                backgroundColor: peel.surfaceHi,
                valueColor: AlwaysStoppedAnimation<Color>(peel.peel),
                minHeight: 6,
              ),
            ),
          ],

          // ── Done: result info ────────────────────────────────────
          if (isDone && job.result != null) ...[
            const SizedBox(height: Space.xs),
            Text(
              '${job.result!.displayPath}  ·  '
              '${FormatUtils.fileSize(job.result!.sizeBytes)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: Fonts.mono,
                fontSize: 11,
                color: peel.inkMuted,
              ),
            ),
          ],

          // ── Error message ────────────────────────────────────────
          if (isFailed && job.error != null) ...[
            const SizedBox(height: Space.xs),
            Text(
              job.error!,
              style: TextStyle(
                fontFamily: Fonts.sans,
                fontSize: 12,
                color: peel.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
