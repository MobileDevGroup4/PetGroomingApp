import 'package:flutter/material.dart';
import '../models/package.dart';
import '../repositories/packages_repository.dart'; // Firestore toggle repo
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

  // Firestore repository
  final _repo = PackagesRepository();

  @override
  Widget build(BuildContext context) {
    final p = widget.pack;
    final theme = Theme.of(context);



    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _scale,

      // Dim the whole card if the package is inactive
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
                setState(() => _scale = 1.0);
                widget.onTap?.call();
              });
            },

            // LayoutBuilder ensures responsive height (no overflow)
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Compact mode if the card is short
                final compact = constraints.maxHeight < 230;

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.surface.withValues(alpha : 0.98),
                        theme.colorScheme.surface.withValues(alpha : 0.92),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // keeps price at bottom
                    children: [
                      //  Header: badge + duration + toggle 
                     
// ===== Header: badge + duration + eye + trash (admin only) =====
Row(
  children: [
    _Badge(text: p.badge),
    const SizedBox(width: 8),
    Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 16),
            Text(
              '${p.durationMinutes} min',
              overflow: TextOverflow.fade,
              softWrap: false,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.black87,
                  ),
            ),

            // 👇 Icônes admin (œil + poubelle) visibles SEULEMENT si connecté
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  // signed out -> rien
                  return const SizedBox.shrink();
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ŒIL: activer/désactiver le package
                    IconButton(
                      tooltip: p.isActive ? 'Disable package' : 'Enable package',
                      icon: Icon(
                        p.isActive ? Icons.visibility : Icons.visibility_off,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                      onPressed: () async {
                        final newValue = !p.isActive;
                        try {
                          await _repo.setActive(p.id, newValue);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(newValue ? 'Package enabled' : 'Package disabled')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating status: $e')),
                          );
                        }
                      },
                    ),

                    // Poubelle: SUPPRIMER définitivement (uniquement si showAdminActions = true)
                    if (widget.showAdminActions)
                      IconButton(
                        tooltip: 'Delete package',
                        icon: const Icon(Icons.delete_outline, size: 18),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                        onPressed: () async {
                          // Demande de confirmation
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete package?'),
                              content: Text('This will permanently delete "${p.name}".'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              // Si un callback est fourni par Home, on l’utilise
                              if (widget.onDelete != null) {
                                widget.onDelete!.call();
                              } else {
                                // Fallback: supprimer directement ici via le repo
                                await _repo.deletePackage(p.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Deleted "${p.name}"')),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Delete failed: $e')),
                              );
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
      ),
    ),
  ],
),


                      SizedBox(height: compact ? 8 : 12),

                      // ===== Title =====
                      Text(
                        p.name,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      SizedBox(height: compact ? 4 : 8),

                      // ===== Short description =====
                      Flexible(
                        fit: FlexFit.loose,
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

                      // ===== Highlights (only if room available) =====
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
                                style:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ===== Price pill (bottom aligned) =====
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFFC107).withValues(alpha : 0.15),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color:
                                  const Color(0xFFFFC107).withValues(alpha : 0.6),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        color: theme.colorScheme.surface.withValues(alpha : 0.7),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
