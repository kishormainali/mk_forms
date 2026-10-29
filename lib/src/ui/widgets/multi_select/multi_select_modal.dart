import 'package:flutter/material.dart';

/// Selection display mode for [MkMultiSelectSearchDropdown].
enum MkMultiSelectModalType {
  /// Opens a modal bottom sheet.
  bottomSheet,

  /// Opens a centered dialog.
  dialog,
}

/// The modal dialog/bottomsheet contents for searching and selecting multiple items.
class MkMultiSelectModalContent<T> extends StatefulWidget {
  const MkMultiSelectModalContent({
    super.key,
    required this.items,
    required this.currentSelection,
    required this.itemToString,
    required this.searchHint,
    required this.modalTitle,
    required this.searchPredicate,
    required this.onSelectionChanged,
    this.itemTitleBuilder,
    this.doneLabel = 'Done',
    this.selectAllLabel = 'Select All',
    this.clearAllLabel = 'Clear All',
    this.showSelectAll = true,
  });

  final List<T> items;
  final List<T> currentSelection;
  final String Function(T item) itemToString;
  final String searchHint;
  final String modalTitle;
  final bool Function(T item, String query) searchPredicate;
  final ValueChanged<List<T>> onSelectionChanged;
  final Widget Function(BuildContext context, T item, bool isSelected)?
  itemTitleBuilder;
  final String doneLabel;
  final String selectAllLabel;
  final String clearAllLabel;
  final bool showSelectAll;

  @override
  State<MkMultiSelectModalContent<T>> createState() =>
      _MkMultiSelectModalContentState<T>();
}

class _MkMultiSelectModalContentState<T>
    extends State<MkMultiSelectModalContent<T>> {
  late List<T> _selected;
  // Mirrors [_selected] for O(1) "is this row selected" lookups; [_selected]
  // stays a list because its order is what gets reported.
  late Set<T> _selectedSet;
  // The items matching the search query. Recomputed when the query or the
  // inputs change, not on every build (a checkbox tap rebuilds the modal).
  late List<T> _filteredItems;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List<T>.from(widget.currentSelection);
    _selectedSet = _selected.toSet();
    _applyFilter();
  }

  @override
  void didUpdateWidget(MkMultiSelectModalContent<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items) ||
        !identical(oldWidget.searchPredicate, widget.searchPredicate)) {
      _applyFilter();
    }
  }

  void _applyFilter() {
    _filteredItems = widget.items
        .where((item) => widget.searchPredicate(item, _searchQuery))
        .toList();
  }

  /// Reports a snapshot of the selection. The modal keeps mutating [_selected],
  /// so handing out the live list would alias the value already stored in the
  /// field state and make later changes look like no-ops to the bloc.
  void _notifySelectionChanged() {
    widget.onSelectionChanged(List<T>.of(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.modalTitle,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(widget.doneLabel),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applyFilter();
                });
              },
            ),
          ),
          if (widget.showSelectAll)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected = List<T>.from(widget.items);
                      _selectedSet = _selected.toSet();
                    });
                    _notifySelectionChanged();
                  },
                  child: Text(widget.selectAllLabel),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected.clear();
                      _selectedSet.clear();
                    });
                    _notifySelectionChanged();
                  },
                  child: Text(widget.clearAllLabel),
                ),
                const SizedBox(width: 8),
              ],
            ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final isSelected = _selectedSet.contains(item);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selected.add(item);
                        _selectedSet.add(item);
                      } else {
                        _selected.remove(item);
                        _selectedSet.remove(item);
                      }
                    });
                    _notifySelectionChanged();
                  },
                  title: widget.itemTitleBuilder != null
                      ? widget.itemTitleBuilder!(context, item, isSelected)
                      : Text(widget.itemToString(item)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
