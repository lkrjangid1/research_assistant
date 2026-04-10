import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final bool isLoading;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.isLoading = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = SearchController();
  final _debounce = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _debounce.addListener(_onDebounced);
  }

  void _onDebounced() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_debounce.value.length >= 3) {
        widget.onSearch(_debounce.value);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SearchBar(
        controller: _controller,
        hintText: 'Search arXiv papers…',
        leading: widget.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.search),
        trailing: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                _debounce.value = '';
              },
            ),
        ],
        onChanged: (value) => _debounce.value = value,
        onSubmitted: (value) {
          if (value.isNotEmpty) widget.onSearch(value);
        },
      ),
    );
  }
}
