import 'package:flutter/material.dart';
import '../../../blocs/field_bloc.dart';
import '../../field_builder.dart';
import '../../form_scope.dart';
import 'multi_select_modal.dart';

export 'multi_select_modal.dart';

/// A reactive multi-select dropdown field with built-in instant search.
///
/// Tapping the field opens a searchable list in a bottom sheet or dialog
/// ([modalType]). Selected items are shown as [InputChip]s.
///
/// Customization is grouped by the Flutter widget each part is built from:
/// - the field itself: [decoration], [icon], [hintStyle], and the [InkWell]
///   parameters ([borderRadius], [mouseCursor], [focusNode], [autofocus],
///   [onFocusChange], [focusColor], [hoverColor], [splashColor],
///   [highlightColor], [overlayColor], [splashFactory], [enableFeedback],
///   [canRequestFocus]);
/// - the chips: `chip*` parameters mirror [InputChip], or take over entirely
///   with [chipBuilder];
/// - the bottom sheet: `sheet*` parameters mirror [showModalBottomSheet];
/// - the dialog: `dialog*` parameters mirror [Dialog] / [showDialog];
/// - all texts: [hintText], [searchHint], [modalTitle], [doneLabel],
///   [selectAllLabel], [clearAllLabel] and [moreLabelBuilder], so they can be
///   localized.
class MkMultiSelectSearchDropdown<T> extends StatelessWidget {
  const MkMultiSelectSearchDropdown({
    super.key,
    this.fieldBloc,
    this.name,
    required this.items,
    required this.itemToString,
    this.decoration = const InputDecoration(),
    this.hintText = 'Select items...',
    this.hintStyle,
    this.icon = const Icon(Icons.arrow_drop_down),
    this.searchHint = 'Search...',
    this.modalTitle = 'Select Options',
    this.doneLabel = 'Done',
    this.selectAllLabel = 'Select All',
    this.clearAllLabel = 'Clear All',
    this.showSelectAll = true,
    this.moreLabelBuilder,
    this.moreLabelStyle,
    this.modalType = MkMultiSelectModalType.bottomSheet,
    this.chipBuilder,
    this.itemTitleBuilder,
    this.searchFilter,
    this.maxChipsDisplayed = 4,
    this.onChanged,
    this.enabled,
    this.autovalidateMode,
    // InkWell
    this.borderRadius,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.highlightColor,
    this.overlayColor,
    this.splashFactory,
    this.enableFeedback = true,
    this.canRequestFocus = true,
    // InputChip
    this.chipSpacing = 6,
    this.chipRunSpacing = 4,
    this.chipLabelStyle = const TextStyle(fontSize: 12),
    this.chipBackgroundColor,
    this.chipPadding,
    this.chipShape,
    this.chipSide,
    this.chipVisualDensity,
    this.chipMaterialTapTargetSize,
    this.chipDeleteIcon,
    this.chipDeleteIconColor,
    // Bottom sheet
    this.sheetBackgroundColor,
    this.sheetElevation,
    this.sheetShape,
    this.sheetClipBehavior,
    this.sheetConstraints,
    this.sheetBarrierColor,
    this.sheetShowDragHandle,
    this.sheetEnableDrag = true,
    this.sheetIsDismissible = true,
    this.sheetUseSafeArea = true,
    this.sheetUseRootNavigator = false,
    // Dialog
    this.dialogBackgroundColor,
    this.dialogElevation,
    this.dialogShape,
    this.dialogInsetPadding,
    this.dialogConstraints = const BoxConstraints(
      maxWidth: 450,
      maxHeight: 600,
    ),
    this.dialogBarrierColor,
    this.dialogBarrierDismissible = true,
    this.dialogUseRootNavigator = true,
  }) : assert(
         fieldBloc != null || name != null,
         'Either fieldBloc or name must be provided',
       );

  /// The field bloc to bind to. If null, [name] is looked up in the nearest [MkFormScope].
  final MkFieldBloc<List<T>>? fieldBloc;

  /// Name of the field in the nearest [MkFormScope], used when [fieldBloc] is null.
  final String? name;

  /// All selectable items.
  final List<T> items;

  /// Text shown for an item in chips and in the list.
  final String Function(T item) itemToString;

  /// Decoration of the field. `errorText`, the [icon] suffix and `enabled` are filled in.
  final InputDecoration decoration;

  /// Placeholder shown while nothing is selected.
  final String hintText;

  /// Style of [hintText]. Defaults to the theme's hint color.
  final TextStyle? hintStyle;

  /// Trailing icon of the field.
  final Widget icon;

  /// Hint of the search box in the modal.
  final String searchHint;

  /// Title shown at the top of the modal.
  final String modalTitle;

  /// Label of the button that closes the modal.
  final String doneLabel;

  /// Label of the "select all" button in the modal.
  final String selectAllLabel;

  /// Label of the "clear all" button in the modal.
  final String clearAllLabel;

  /// Whether the modal shows the select-all / clear-all buttons.
  final bool showSelectAll;

  /// Builds the "+N more" label from the number of hidden chips.
  final String Function(int hiddenCount)? moreLabelBuilder;

  /// Style of the "+N more" label. Defaults to bold, primary color, size 12.
  final TextStyle? moreLabelStyle;

  /// Whether the picker opens as a bottom sheet or a dialog.
  final MkMultiSelectModalType modalType;

  /// Maximum number of chips shown before collapsing into "+N more".
  final int maxChipsDisplayed;

  /// Overrides the [AutovalidateMode] of the enclosing [MkFormScope].
  final AutovalidateMode? autovalidateMode;

  /// Called with the new selection after the bloc has been updated.
  final ValueChanged<List<T>>? onChanged;

  /// Set to `false` to disable the field regardless of the bloc.
  final bool? enabled;

  /// Custom chip builder for selected items.
  final Widget Function(BuildContext context, T item, VoidCallback onRemove)?
  chipBuilder;

  /// Custom list item widget builder in the search modal.
  final Widget Function(BuildContext context, T item, bool isSelected)?
  itemTitleBuilder;

  /// Custom predicate to filter items by search query.
  final bool Function(T item, String query)? searchFilter;

  /// See [InkWell.borderRadius]. Also clips the field's ripple.
  final BorderRadius? borderRadius;

  /// See [InkWell.mouseCursor].
  final MouseCursor? mouseCursor;

  /// See [InkWell.focusNode].
  final FocusNode? focusNode;

  /// See [InkWell.autofocus].
  final bool autofocus;

  /// See [InkWell.onFocusChange].
  final ValueChanged<bool>? onFocusChange;

  /// See [InkWell.focusColor].
  final Color? focusColor;

  /// See [InkWell.hoverColor].
  final Color? hoverColor;

  /// See [InkWell.splashColor].
  final Color? splashColor;

  /// See [InkWell.highlightColor].
  final Color? highlightColor;

  /// See [InkWell.overlayColor].
  final WidgetStateProperty<Color?>? overlayColor;

  /// See [InkWell.splashFactory].
  final InteractiveInkFeatureFactory? splashFactory;

  /// See [InkWell.enableFeedback].
  final bool enableFeedback;

  /// See [InkWell.canRequestFocus].
  final bool canRequestFocus;

  /// Horizontal gap between chips ([Wrap.spacing]).
  final double chipSpacing;

  /// Vertical gap between chip rows ([Wrap.runSpacing]).
  final double chipRunSpacing;

  /// See [InputChip.labelStyle].
  final TextStyle? chipLabelStyle;

  /// See [InputChip.backgroundColor].
  final Color? chipBackgroundColor;

  /// See [InputChip.padding].
  final EdgeInsetsGeometry? chipPadding;

  /// See [InputChip.shape].
  final OutlinedBorder? chipShape;

  /// See [InputChip.side].
  final BorderSide? chipSide;

  /// See [InputChip.visualDensity].
  final VisualDensity? chipVisualDensity;

  /// See [InputChip.materialTapTargetSize].
  final MaterialTapTargetSize? chipMaterialTapTargetSize;

  /// See [InputChip.deleteIcon].
  final Widget? chipDeleteIcon;

  /// See [InputChip.deleteIconColor].
  final Color? chipDeleteIconColor;

  /// See [showModalBottomSheet.backgroundColor].
  final Color? sheetBackgroundColor;

  /// See [showModalBottomSheet.elevation].
  final double? sheetElevation;

  /// See [showModalBottomSheet.shape].
  final ShapeBorder? sheetShape;

  /// See [showModalBottomSheet.clipBehavior].
  final Clip? sheetClipBehavior;

  /// See [showModalBottomSheet.constraints].
  final BoxConstraints? sheetConstraints;

  /// See [showModalBottomSheet.barrierColor].
  final Color? sheetBarrierColor;

  /// See [showModalBottomSheet.showDragHandle].
  final bool? sheetShowDragHandle;

  /// See [showModalBottomSheet.enableDrag].
  final bool sheetEnableDrag;

  /// See [showModalBottomSheet.isDismissible].
  final bool sheetIsDismissible;

  /// See [showModalBottomSheet.useSafeArea].
  final bool sheetUseSafeArea;

  /// See [showModalBottomSheet.useRootNavigator].
  final bool sheetUseRootNavigator;

  /// See [Dialog.backgroundColor].
  final Color? dialogBackgroundColor;

  /// See [Dialog.elevation].
  final double? dialogElevation;

  /// See [Dialog.shape].
  final ShapeBorder? dialogShape;

  /// See [Dialog.insetPadding].
  final EdgeInsets? dialogInsetPadding;

  /// Constraints of the dialog content. Defaults to at most 450 x 600.
  final BoxConstraints dialogConstraints;

  /// See [showDialog.barrierColor].
  final Color? dialogBarrierColor;

  /// See [showDialog.barrierDismissible].
  final bool dialogBarrierDismissible;

  /// See [showDialog.useRootNavigator].
  final bool dialogUseRootNavigator;

  @override
  Widget build(BuildContext context) {
    return MkFieldBuilder<List<T>>(
      fieldBloc: fieldBloc,
      name: name,
      builder: (context, state, bloc) {
        final selectedItems = state.value ?? <T>[];
        final isEnabled = state.isEnabled && (enabled ?? true);

        final effectiveMode =
            autovalidateMode ??
            MkFormScope.maybeAutovalidateModeOf(context) ??
            AutovalidateMode.onUserInteraction;
        final isErrorVisible = state.shouldShowError(effectiveMode);

        final effectiveDecoration = decoration.copyWith(
          errorText: isErrorVisible ? state.getLocalizedError(context) : null,
          suffixIcon: icon,
          enabled: isEnabled,
        );

        void commit(List<T> updated) {
          bloc.changeValue(updated);
          onChanged?.call(updated);
        }

        void remove(T item) {
          commit(List<T>.from(selectedItems)..remove(item));
        }

        final hiddenCount = selectedItems.length - maxChipsDisplayed;

        return InkWell(
          onTap: isEnabled
              ? () async {
                  bloc.touch();
                  await _openSelectionModal(
                    context: context,
                    currentSelection: selectedItems,
                    onSelectionChanged: commit,
                  );
                }
              : null,
          borderRadius: borderRadius,
          mouseCursor: mouseCursor,
          focusNode: focusNode,
          autofocus: autofocus,
          onFocusChange: onFocusChange,
          focusColor: focusColor,
          hoverColor: hoverColor,
          splashColor: splashColor,
          highlightColor: highlightColor,
          overlayColor: overlayColor,
          splashFactory: splashFactory,
          enableFeedback: enableFeedback,
          canRequestFocus: canRequestFocus,
          child: InputDecorator(
            decoration: effectiveDecoration,
            child: selectedItems.isEmpty
                ? Text(
                    hintText,
                    style:
                        hintStyle ??
                        TextStyle(color: Theme.of(context).hintColor),
                  )
                : Wrap(
                    spacing: chipSpacing,
                    runSpacing: chipRunSpacing,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...selectedItems.take(maxChipsDisplayed).map((item) {
                        if (chipBuilder != null) {
                          return chipBuilder!(
                            context,
                            item,
                            () => remove(item),
                          );
                        }
                        return InputChip(
                          label: Text(itemToString(item)),
                          labelStyle: chipLabelStyle,
                          backgroundColor: chipBackgroundColor,
                          padding: chipPadding,
                          shape: chipShape,
                          side: chipSide,
                          visualDensity: chipVisualDensity,
                          materialTapTargetSize: chipMaterialTapTargetSize,
                          deleteIcon: chipDeleteIcon,
                          deleteIconColor: chipDeleteIconColor,
                          onDeleted: isEnabled ? () => remove(item) : null,
                        );
                      }),
                      if (hiddenCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            moreLabelBuilder?.call(hiddenCount) ??
                                '+$hiddenCount more',
                            style:
                                moreLabelStyle ??
                                TextStyle(
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

    Widget modalContent() {
      return MkMultiSelectModalContent<T>(
        items: items,
        currentSelection: currentSelection,
        itemToString: itemToString,
        searchHint: searchHint,
        modalTitle: modalTitle,
        doneLabel: doneLabel,
        selectAllLabel: selectAllLabel,
        clearAllLabel: clearAllLabel,
        showSelectAll: showSelectAll,
        itemTitleBuilder: itemTitleBuilder,
        searchPredicate: searchPredicate,
        onSelectionChanged: onSelectionChanged,
      );
    }

    if (modalType == MkMultiSelectModalType.bottomSheet) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: sheetUseSafeArea,
        useRootNavigator: sheetUseRootNavigator,
        backgroundColor: sheetBackgroundColor,
        elevation: sheetElevation,
        shape: sheetShape,
        clipBehavior: sheetClipBehavior,
        constraints: sheetConstraints,
        barrierColor: sheetBarrierColor,
        showDragHandle: sheetShowDragHandle,
        enableDrag: sheetEnableDrag,
        isDismissible: sheetIsDismissible,
        builder: (ctx) => modalContent(),
      );
    } else {
      await showDialog<void>(
        context: context,
        barrierColor: dialogBarrierColor,
        barrierDismissible: dialogBarrierDismissible,
        useRootNavigator: dialogUseRootNavigator,
        builder: (ctx) => Dialog(
          backgroundColor: dialogBackgroundColor,
          elevation: dialogElevation,
          shape: dialogShape,
          insetPadding: dialogInsetPadding,
          child: ConstrainedBox(
            constraints: dialogConstraints,
            child: modalContent(),
          ),
        ),
      );
    }
  }
}
