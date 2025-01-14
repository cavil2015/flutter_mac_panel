import 'package:flutter/material.dart';
import 'dart:math';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock<IconData>(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e, scale) {
              return AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 48),
                  height: 48,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color:
                        Colors.primaries[e.hashCode % Colors.primaries.length],
                  ),
                  child: Center(child: Icon(e, color: Colors.white)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item with a scale factor.
  final Widget Function(T, double scale) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  /// Track the index of the item being hovered over.
  int? _hoveredIndex;

  /// Track the index of the item being dragged.
  int? _draggedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_items.length, (index) {
          final item = _items[index];

          // Calculate scale based on hover proximity.
          final scale = _calculateScale(index);

          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredIndex = index),
            onExit: (_) => setState(() => _hoveredIndex = null),
            child: Draggable<T>(
              data: item,
              feedback: Material(
                color: Colors.transparent,
                child: widget.builder(item, 1.2),
              ),
              childWhenDragging: Opacity(
                opacity: 0.1,
                child: widget.builder(item, 1.0),
              ),
              onDragStarted: () => setState(() => _draggedIndex = index),
              onDragEnd: (_) => setState(() => _draggedIndex = null),
              child: DragTarget<T>(
                onAccept: (receivedItem) {
                  setState(() {
                    final oldIndex = _items.indexOf(receivedItem);
                    _items.removeAt(oldIndex);
                    _items.insert(index, receivedItem);
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: Transform.scale(
                      key: ValueKey(item), // Ensure unique keys for animation
                      scale: scale, // Apply scaling
                      alignment: Alignment.bottomCenter,
                      child: widget.builder(item, scale),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Calculate scale for an item based on its distance from the hovered item.
  double _calculateScale(int index) {
    if (_hoveredIndex == null) return 1.0; // No scaling when no hover
    final distance = (_hoveredIndex! - index).abs();

    // Ensure that the scaling does not go below 1.0
    return max(1.0, 1.1 - (0.05 * distance));
  }
}
