import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:emap_hangzhou/core/services/amap_search_result.dart';
import 'package:emap_hangzhou/core/services/amap_search_service.dart';
import 'package:emap_hangzhou/core/utils/coordinate_utils.dart';

/// A search bar for AMap location search with autocomplete suggestions.
///
/// Calls AMap Input Tips API on each keystroke (debounced 300ms).
/// Displays suggestions in a dropdown overlay.
class MapSearchBar extends StatefulWidget {
  const MapSearchBar({super.key, required this.onPlaceSelected});

  /// Called when the user taps a suggestion. Coordinates are WGS-84.
  final void Function(String name, LatLng wgsPosition) onPlaceSelected;

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<AmapSearchResult> _results = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
        setState(() => _showResults = true);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      final results = await AmapSearchService.search(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
          _showResults = true;
        });
      }
    });
  }

  void _onResultTap(AmapSearchResult result) {
    // AMap API returns GCJ-02 → convert to WGS-84
    final gcj = LatLng(result.latitude, result.longitude);
    final wgs = CoordinateUtils.gcj02ToWgs84(gcj);

    _controller.text = result.name;
    _focusNode.unfocus();
    setState(() => _showResults = false);

    widget.onPlaceSelected(result.name, wgs);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search input
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Search places...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _results = [];
                          _showResults = false;
                        });
                      },
                    )
                  : _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _onChanged,
            onTap: () {
              if (_results.isNotEmpty) {
                setState(() => _showResults = true);
              }
            },
          ),
        ),
        // Suggestions dropdown
        if (_showResults && _results.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = _results[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 20,
                  ),
                  title: Text(r.name, style: const TextStyle(fontSize: 14)),
                  subtitle: r.district.isNotEmpty
                      ? Text(r.district, style: const TextStyle(fontSize: 12))
                      : null,
                  onTap: () => _onResultTap(r),
                );
              },
            ),
          ),
      ],
    );
  }
}
