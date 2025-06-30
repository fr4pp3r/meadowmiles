import 'package:flutter/material.dart';
import 'package:meadowmiles/models/vehicle_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double? maxWidth;

  const ScrollingText({
    super.key,
    required this.text,
    this.style,
    this.maxWidth,
  });

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isOverflowing = false;
  double _textWidth = 0;
  double _containerWidth = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Create animation with pauses at start and end
    _animation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0),
        weight: 20, // Pause at start
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60, // Main animation
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1),
        weight: 20, // Pause at end
      ),
    ]).animate(_controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverflow();
    });
  }

  void _checkOverflow() {
    if (!mounted) return;

    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    _textWidth = textPainter.width;
    _containerWidth =
        widget.maxWidth ?? MediaQuery.of(context).size.width * 0.5;

    if (_textWidth > _containerWidth) {
      setState(() {
        _isOverflowing = true;
      });
      _startAnimation();
    }
  }

  void _startAnimation() {
    // Start animation after a delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOverflowing) {
      return Text(
        widget.text,
        style: widget.style,
        overflow: TextOverflow.ellipsis,
      );
    }

    final scrollDistance = _textWidth - _containerWidth + 20; // Extra padding

    return SizedBox(
      width: _containerWidth,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ClipRect(
            child: Transform.translate(
              offset: Offset(-_animation.value * scrollDistance, 0),
              child: Text(
                widget.text,
                style: widget.style,
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            ),
          );
        },
      ),
    );
  }
}

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;

  const VehicleCard({super.key, required this.vehicle, this.onTap});

  Future<double> _fetchAverageRating() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicle.id)
        .get();
    if (snapshot.docs.isEmpty) return 0.0;
    double total = 0;
    int count = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rate = (data['rate'] is int)
          ? (data['rate'] as int).toDouble()
          : (data['rate'] ?? 0).toDouble();
      if (rate > 0) {
        total += rate;
        count++;
      }
    }
    if (count == 0) return 0.0;
    return total / count;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _fetchAverageRating(),
      builder: (context, snapshot) {
        final avgRating = snapshot.data ?? 0.0;
        return Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
          child: Card(
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ScrollingText(
                                text: vehicle.make,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxWidth: 120,
                              ),
                            ),
                            Text(
                              vehicle.vehicleType
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase(),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        ScrollingText(
                          text: vehicle.model,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxWidth: 160,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              '₱',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              vehicle.pricePerDay.toStringAsFixed(0),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              ' | day',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ScrollingText(
                          text: vehicle.location,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          maxWidth: 160,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < avgRating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                            const SizedBox(width: 4),
                            Text(
                              avgRating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: onTap,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('View'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right: Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: vehicle.imageUrl.isNotEmpty
                          ? Image.network(
                              vehicle.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.car_repair),
                                  ),
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.car_repair),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
