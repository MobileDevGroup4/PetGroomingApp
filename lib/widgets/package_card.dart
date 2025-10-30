import 'package:flutter/material.dart';
import '../models/package.dart';
import '../repositories/packages_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart'; // 👈 assure-toi que ce chemin est correct

class PackageCard extends StatefulWidget {
  final Package pack;
  final VoidCallback? onTap;
  final String? highlightsText;
  final bool showAdminActions;
  final VoidCallback? onDelete;

  const PackageCard({
    super.key,
    required this.pack,
    this.onTap,
    this.highlightsText,
    this.showAdminActions = false,
    this.onDelete,
  });

  @override
  State<PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<PackageCard> {
  double _scale = 1.0;
  final _repo = PackagesRepository();

  @override
  Widget build(BuildContext context) {
    final p = widget.pack;
    final theme = Theme.of(context);

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _scale,
      child: Opacity(
        opacity: p.isActive ? 1.0 : 0.55,
        child: Card(
          clipBehavior: Clip.hardEdge,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: InkWell(
            onTap: () {
              setState(() => _scale = 0.98);
              Future.delayed(const Duration(milliseconds: 120), () {
                if (!mounted) return;
                setState(() => _scale = 1.0);
                widget.onTap?.call();
              });
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 230;

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.surface.withValues(alpha: 0.98),
                        theme.colorScheme.surface.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== HEADER =====
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // à gauche : chips
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  if (p.hasDiscount)
                                    _Chip(
                                      text: 'Top sales',
                                      foreground: Colors.red.shade800,
                                      border: Colors.red.withValues(
                                        alpha: 0.35,
                                      ),
                                      background: Colors.red.withValues(
                                        alpha: 0.06,
                                      ),
                                    ),
                                  if (p.badge.trim().isNotEmpty)
                                    _Chip(
                                      text: p.badge,
                                      foreground: Colors.black87,
                                      border: Colors.black12,
                                      background: theme.colorScheme.surface
                                          .withValues(alpha: 0.7),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // à droite : durée + actions admin
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.schedule, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${p.durationMinutes} min',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // ===== ADMIN ACTIONS =====
                              StreamBuilder<User?>(
                                stream: FirebaseAuth.instance
                                    .authStateChanges(),
                                builder: (context, snap) {
                                  if (!snap.hasData) {
                                    return const SizedBox.shrink();
                                  }

                                  return FutureBuilder<bool>(
                                    future: AuthService().isAdmin(),
                                    builder: (context, adminSnap) {
                                      final isAdmin = adminSnap.data ?? false;

                                      if (!isAdmin ||
                                          !widget.showAdminActions) {
                                        return const SizedBox.shrink();
                                      }

                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // ✅ Enable/Disable
                                          IconButton(
                                            tooltip: p.isActive
                                                ? 'Disable package'
                                                : 'Enable package',
                                            icon: Icon(
                                              p.isActive
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              size: 18,
                                            ),
                                            padding: EdgeInsets.zero,
                                            visualDensity: const VisualDensity(
                                              horizontal: -4,
                                              vertical: -4,
                                            ),
                                            constraints:
                                                const BoxConstraints.tightFor(
                                                  width: 28,
                                                  height: 28,
                                                ),
                                            onPressed: () async {
                                              final isAdminConfirmed =
                                                  await AuthService().isAdmin();
                                              if (!isAdminConfirmed) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Admin rights required',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              final newValue = !p.isActive;
                                              try {
                                                await _repo.setActive(
                                                  p.id,
                                                  newValue,
                                                );
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      newValue
                                                          ? 'Package enabled'
                                                          : 'Package disabled',
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error updating status: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),

                                          // ✅ Discount
                                          IconButton(
                                            tooltip: p.hasDiscount
                                                ? 'Edit discount (${p.discountPercent}%)'
                                                : 'Add discount',
                                            icon: const Icon(
                                              Icons.percent,
                                              size: 18,
                                            ),
                                            padding: EdgeInsets.zero,
                                            visualDensity: const VisualDensity(
                                              horizontal: -4,
                                              vertical: -4,
                                            ),
                                            constraints:
                                                const BoxConstraints.tightFor(
                                                  width: 28,
                                                  height: 28,
                                                ),
                                            onPressed: () async {
                                              final isAdminConfirmed =
                                                  await AuthService().isAdmin();
                                              if (!isAdminConfirmed) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Admin rights required',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              if (!context.mounted) return;
                                              _showDiscountDialog(p);
                                            },
                                          ),

                                          // ✅ Delete
                                          IconButton(
                                            tooltip: 'Delete package',
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                            ),
                                            padding: EdgeInsets.zero,
                                            visualDensity: const VisualDensity(
                                              horizontal: -4,
                                              vertical: -4,
                                            ),
                                            constraints:
                                                const BoxConstraints.tightFor(
                                                  width: 28,
                                                  height: 28,
                                                ),
                                            onPressed: () async {
                                              final isAdminConfirmed =
                                                  await AuthService().isAdmin();
                                              if (!isAdminConfirmed) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Admin rights required',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              if (!context.mounted) return;
                                              final confirm =
                                                  await showDialog<bool>(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      title: const Text(
                                                        'Delete package?',
                                                      ),
                                                      content: Text(
                                                        'This will permanently delete "${p.name}".',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                false,
                                                              ),
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        FilledButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                true,
                                                              ),
                                                          child: const Text(
                                                            'Delete',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                              if (confirm == true) {
                                                try {
                                                  if (widget.onDelete != null) {
                                                    widget.onDelete!();
                                                  } else {
                                                    await _repo.deletePackage(
                                                      p.id,
                                                    );
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Deleted "${p.name}"',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Delete failed: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ===== TITLE =====
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ===== DESCRIPTION =====
                      Expanded(
                        child: Text(
                          p.shortDescription,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                            height: 1.2,
                          ),
                        ),
                      ),

                      // ===== HIGHLIGHTS =====
                      if (!compact &&
                          widget.highlightsText != null &&
                          widget.highlightsText!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.add_circle_outline, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.highlightsText!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 8),

                      // ===== PRICE =====
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: _PricePill(pack: p),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Dialog rabais + date de fin ----------
  Future<void> _showDiscountDialog(Package p) async {
    final repo = _repo;
    int percent = p.discountPercent ?? 0;
    DateTime? endAt = p.discountEndAt;

    final result = await showDialog<({int percent, DateTime? endAt})>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Set discount (%)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text('$percent', textAlign: TextAlign.right),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: percent.toDouble(),
                          min: 0,
                          max: 90,
                          divisions: 90,
                          label: '$percent%',
                          onChanged: (v) => setState(() => percent = v.round()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'End date (optional)',
                      style: Theme.of(ctx).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event),
                          label: Text(
                            endAt == null ? 'No end date' : _formatDate(endAt!),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () async {
                            final now = DateTime.now();
                            final d = await showDatePicker(
                              context: ctx,
                              firstDate: DateTime(now.year - 1),
                              lastDate: DateTime(now.year + 3),
                              initialDate: endAt ?? now,
                            );
                            if (d == null) return;
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: endAt != null
                                  ? TimeOfDay(
                                      hour: endAt!.hour,
                                      minute: endAt!.minute,
                                    )
                                  : const TimeOfDay(hour: 23, minute: 59),
                            );
                            setState(() {
                              endAt = DateTime(
                                d.year,
                                d.month,
                                d.day,
                                t?.hour ?? 23,
                                t?.minute ?? 59,
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Clear date',
                        onPressed: () => setState(() => endAt = null),
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Enter 0 to remove discount',
                      style: Theme.of(
                        ctx,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(ctx, (percent: percent, endAt: endAt)),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    try {
      if (result.percent <= 0) {
        await repo.clearDiscount(p.id);
      } else {
        await repo.setDiscount(
          p.id,
          percent: result.percent,
          endAt: result.endAt,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Discount updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

// ---------------- UI helpers ----------------
class _Chip extends StatelessWidget {
  final String text;
  final Color foreground;
  final Color border;
  final Color background;
  const _Chip({
    required this.text,
    required this.foreground,
    required this.border,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        color: background,
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: foreground,
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final Package pack;
  const _PricePill({required this.pack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount =
        pack.hasDiscount && pack.basePrice != null && pack.basePrice! > 0;

    String suffix() {
      final m = RegExp(r'^\s*([\d.,]+)\s*(.*)$').firstMatch(pack.priceLabel);
      return (m != null ? m.group(2) : '')?.trim().replaceAll(
            RegExp(r'\s+'),
            ' ',
          ) ??
          '';
    }

    String fmt(double v) {
      final sfx = suffix();
      final value = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
      return sfx.isEmpty ? value : '$value $sfx';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFC107).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: const Color(0xFFFFC107).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: hasDiscount
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fmt(pack.basePrice!),
                    style: theme.textTheme.labelLarge?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          fmt(pack.discountedPrice!),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '-${pack.discountPercent}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Text(
                pack.priceLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
