import 'package:flutter/material.dart';
import '../models/package.dart';
import '../repositories/packages_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
                // petit card => on limite le texte
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
                      // ===== HEADER (PAS DE HAUTEUR FIXE) =====
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // badge à gauche — Expanded pour qu’il prenne juste ce qu’il faut
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _Badge(text: p.badge),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // à droite : durée (ligne 1) puis icônes admin (ligne 2)
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: Colors.black87),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              StreamBuilder<User?>(
                                stream:
                                    FirebaseAuth.instance.authStateChanges(),
                                builder: (context, snap) {
                                  if (!snap.hasData) {
                                    return const SizedBox.shrink();
                                  }
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
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
                                          horizontal: -4, vertical: -4),
                                        constraints: const BoxConstraints
                                            .tightFor(width: 28, height: 28),
                                        onPressed: () async {
                                          final newValue = !p.isActive;
                                          try {
                                            await _repo.setActive(p.id, newValue);
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(newValue
                                                  ? 'Package enabled'
                                                  : 'Package disabled'),
                                            ));
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Error updating status: $e'),
                                            ));
                                          }
                                        },
                                      ),
                                      if (widget.showAdminActions)
                                        IconButton(
                                          tooltip: 'Delete package',
                                          icon: const Icon(
                                              Icons.delete_outline, size: 18),
                                          padding: EdgeInsets.zero,
                                          visualDensity: const VisualDensity(
                                              horizontal: -4, vertical: -4),
                                          constraints: const BoxConstraints
                                              .tightFor(width: 28, height: 28),
                                          onPressed: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title:
                                                    const Text('Delete package?'),
                                                content: Text(
                                                    'This will permanently delete "${p.name}".'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child:
                                                        const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              try {
                                                if (widget.onDelete != null) {
                                                  widget.onDelete!();
                                                } else {
                                                  await _repo.deletePackage(p.id);
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Deleted "${p.name}"'),
                                                  ));
                                                }
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Delete failed: $e'),
                                                ));
                                              }
                                            }
                                          },
                                        ),
                                    ],
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

                      // ===== DESCRIPTION (EXPANDED pour absorber la hauteur) =====
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

                      // ===== HIGHLIGHTS (optionnel) =====
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

                      // ===== PRICE PILL (toujours en bas) =====
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: const Color(0xFFFFC107)
                                  .withValues(alpha: 0.6),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            p.priceLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
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
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150), // évite d’empiéter
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
          color: theme.colorScheme.surface.withValues(alpha: 0.7),
        ),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
