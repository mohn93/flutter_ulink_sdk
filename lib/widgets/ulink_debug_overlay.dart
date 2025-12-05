import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../flutter_ulink_sdk.dart';

/// A debug overlay widget that displays SDK logs in a floating panel
///
/// By default, the overlay is hidden in release mode. Use [showInRelease]
/// to override this behavior for debugging production builds.
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     YourApp(),
///     ULinkDebugOverlay(),  // Hidden in release by default
///   ],
/// )
/// ```
class ULinkDebugOverlay extends StatefulWidget {
  /// Initial position of the floating button
  final Offset initialPosition;

  /// Maximum number of logs to keep in memory
  final int maxLogs;

  /// Whether to show the overlay in release mode (default: false)
  /// Set to true to debug production builds
  final bool showInRelease;

  const ULinkDebugOverlay({
    super.key,
    this.initialPosition = const Offset(20, 100),
    this.maxLogs = 200,
    this.showInRelease = false,
  });

  @override
  State<ULinkDebugOverlay> createState() => _ULinkDebugOverlayState();
}

class _ULinkDebugOverlayState extends State<ULinkDebugOverlay> {
  final List<ULinkLogEntry> _logs = [];
  StreamSubscription<ULinkLogEntry>? _subscription;
  bool _isExpanded = false;
  late Offset _position;
  String _filterLevel = 'all';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _subscription = ULink.instance.onLog.listen((entry) {
      setState(() {
        _logs.add(entry);
        if (_logs.length > widget.maxLogs) {
          _logs.removeAt(0);
        }
      });
      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && _isExpanded) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  List<ULinkLogEntry> get _filteredLogs {
    if (_filterLevel == 'all') return _logs;
    return _logs.where((log) => log.level == _filterLevel).toList();
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'debug':
      default:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'debug':
      default:
        return Icons.bug_report;
    }
  }

  void _copyLogsToClipboard() {
    final text = _filteredLogs.map((e) => e.toString()).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hide in release mode unless explicitly enabled
    if (kReleaseMode && !widget.showInRelease) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Expanded log panel
        if (_isExpanded)
          Positioned(
            left: 16,
            right: 16,
            top: 60,
            bottom: 100,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.terminal,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'ULink Logs (${_filteredLogs.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Filter dropdown
                          SizedBox(
                            width: 80,
                            child: DropdownButton<String>(
                              value: _filterLevel,
                              dropdownColor: Colors.grey[800],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              underline: const SizedBox(),
                              isExpanded: true,
                              isDense: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All'),
                                ),
                                DropdownMenuItem(
                                  value: 'debug',
                                  child: Text('Debug'),
                                ),
                                DropdownMenuItem(
                                  value: 'info',
                                  child: Text('Info'),
                                ),
                                DropdownMenuItem(
                                  value: 'warning',
                                  child: Text('Warn'),
                                ),
                                DropdownMenuItem(
                                  value: 'error',
                                  child: Text('Error'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _filterLevel = value ?? 'all';
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.copy,
                                color: Colors.white70,
                                size: 18,
                              ),
                              onPressed: _copyLogsToClipboard,
                              tooltip: 'Copy',
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.white70,
                                size: 18,
                              ),
                              onPressed: _clearLogs,
                              tooltip: 'Clear',
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isExpanded = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Log list
                    Expanded(
                      child: _filteredLogs.isEmpty
                          ? const Center(
                              child: Text(
                                'No logs yet...\nMake sure debug: true is set in ULinkConfig',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8),
                              itemCount: _filteredLogs.length,
                              itemBuilder: (context, index) {
                                final log = _filteredLogs[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _getLevelIcon(log.level),
                                        color: _getLevelColor(log.level),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        log.formattedTime,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          log.message,
                                          style: TextStyle(
                                            color: _getLevelColor(log.level),
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Floating button
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position = Offset(
                  _position.dx + details.delta.dx,
                  _position.dy + details.delta.dy,
                );
              });
            },
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _logs.any((l) => l.level == 'error')
                      ? Colors.red
                      : Colors.deepPurple,
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.bug_report,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    if (_logs.isNotEmpty)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _logs.length > 99 ? '99+' : '${_logs.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
