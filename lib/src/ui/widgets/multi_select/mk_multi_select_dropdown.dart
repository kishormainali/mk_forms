import 'package:flutter/material.dart';
import '../../../blocs/field_bloc.dart';
import '../../field_builder.dart';
import '../../form_scope.dart';
import 'multi_select_modal.dart';

export 'multi_select_modal.dart';

/// A reactive multi-select dropdown field with built-in instant search.
class MkMultiSelectSearchDropdown<T> extends StatelessWidget {
  const MkMultiSelectSearchDropdown({
    super.key,
    this.fieldBloc,
    this.name,
    required this.items,
    required this.itemToString,
    this.decoration = const InputDecoration(),
    this.hintText = 'Select items...',
    this.searchHint = 'Search...',
    this.modalTitle = 'Select Options',
    this.modalType = MkMultiSelectModalType.bottomSheet,
    this.chipBuilder,
    this.itemTitleBuilder,
    this.searchFilter,
    this.maxChipsDisplayed = 4,
    this.autovalidateMode,
  }) : assert(
         fieldBloc != null || name != null,
         'Either fieldBloc or name must be provided',
       );

  final MkFieldBloc<List<T>>? fieldBloc;
  final String? name;
  final List<T> items;
  final String Function(T item) itemToString;
  final InputDecoration decoration;
  final String hintText;
  final String searchHint;
  final String modalTitle;
  final MkMultiSelectModalType modalType;
  final int maxChipsDisplayed;
  final AutovalidateMode? autovalidateMode;

  /// Custom chip builder for selected items.
  final Widget Function(BuildContext context, T item, VoidCallback onRemove)?
      chipBuilder;

  /// Custom list item widget builder in the search modal.
  final Widget Function(BuildContext context, T item, bool isSelected)?
      itemTitleBuilder;

  /// Custom predicate to filter items by search query.
  final bool Function(T item, String query)? searchFilter;

  @override
  Widget build(BuildContext context) {
    return MkFieldBuilder<List<T>>(
      fieldBloc: fieldBloc,
      name: name,
      builder: (context, state, bloc) {
        final selectedItems = state.value ?? <T>[];

        final effectiveMode = autovalidateMode ??
            MkFormScope.maybeAutovalidateModeOf(context) ??
            AutovalidateMode.onUserInteraction;
        final isErrorVisible = state.shouldShowError(effectiveMode);

        final effectiveDecoration = decoration.copyWith(
          errorText: isErrorVisible ? state.getLocalizedError(context) : null,
          suffixIcon: const Icon(Icons.arrow_drop_down),
          enabled: state.isEnabled,
        );

        return InkWell(
          onTap: state.isEnabled
              ? () async {
                  bloc.touch();
                  await _openSelectionModal(
                    context: context,
                    currentSelection: selectedItems,
                    onSelectionChanged: (updated) {
                      bloc.changeValue(updated);
                    },
                  );
                }
              : null,
          child: InputDecorator(
            decoration: effectiveDecoration,
            child: selectedItems.isEmpty
                ? Text(
                    hintText,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...selectedItems.take(maxChipsDisplayed).map((item) {
                        if (chipBuilder != null) {
                          return chipBuilder!(context, item, () {
                            final updated = List<T>.from(selectedItems)
                              ..remove(item);
                            bloc.changeValue(updated);
                          });
                        }
                        return InputChip(
                          label: Text(
                            itemToString(item),
                            style: const TextStyle(fontSize: 12),
                          ),
                          onDeleted: state.isEnabled
                              ? () {
                                  final updated = List<T>.from(selectedItems)
                                    ..remove(item);
                                  bloc.changeValue(updated);
                                }
                              : null,
                        );
                      }),
                      if (selectedItems.length > maxChipsDisplayed)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '+${selectedItems.length - maxChipsDisplayed} more',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Future<void> _openSelectionModal({
    required BuildContext context,
    required List<T> currentSelection,
    required ValueChanged<List<T>> onSelectionChanged,
  }) async {
    final searchPredicate =
        searchFilter ??
        (T item, String query) =>
            itemToString(item).toLowerCase().contains(query.toLowerCase());

    Widget modalContent(BuildContext modalContext, StateSetter modalSetState) {
      return MkMultiSelectModalContent<T>(
        items: items,
        currentSelection: currentSelection,
        itemToString: itemToString,
        searchHint: searchHint,
        modalTitle: modalTitle,
        itemTitleBuilder: itemTitleBuilder,
        searchPredicate: searchPredicate,
        onSelectionChanged: onSelectionChanged,
      );
    }

    if (modalType == MkMultiSelectModalType.bottomSheet) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => StatefulBuilder(builder: modalContent),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (dialogCtx, modalSetState) {
            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
                child: modalContent(dialogCtx, modalSetState),
              ),
            );
          },
        ),
      );
    }
  }
}
