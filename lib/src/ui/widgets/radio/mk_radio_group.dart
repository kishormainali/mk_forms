import 'package:flutter/material.dart';
import '../../../blocs/field_bloc.dart';
import '../../field_builder.dart';
import '../../form_scope.dart';
import 'mk_radio_option.dart';

export 'mk_radio_option.dart';

/// A reactive radio group bound to an [MkFieldBloc<T>].
class MkRadioGroup<T> extends StatelessWidget {
  const MkRadioGroup({
    super.key,
    this.fieldBloc,
    this.name,
    required this.options,
    this.layout = MkRadioLayout.vertical,
    this.title,
    this.activeColor,
    this.contentPadding,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.itemBuilder,
    this.autovalidateMode,
  }) : assert(
          fieldBloc != null || name != null,
          'Either fieldBloc or name must be provided',
        );

  final MkFieldBloc<T>? fieldBloc;
  final String? name;
  final List<MkRadioOption<T>> options;
  final MkRadioLayout layout;
  final Widget? title;
  final Color? activeColor;
  final EdgeInsetsGeometry? contentPadding;
  final double spacing;
  final double runSpacing;
  final AutovalidateMode? autovalidateMode;

  /// Optional custom builder for full design system flexibility
  /// (e.g. selectable card designs, pill buttons, etc.).
  final Widget Function(
    BuildContext context,
    MkRadioOption<T> option,
    bool isSelected,
    VoidCallback onSelect,
  )? itemBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MkFieldBuilder<T>(
      fieldBloc: fieldBloc,
      name: name,
      builder: (context, state, bloc) {
        Widget content;

        if (itemBuilder != null) {
          final items = options.map((option) {
            final isSelected = state.value == option.value;
            return itemBuilder!(
              context,
              option,
              isSelected,
              () {
                if (state.isEnabled && option.enabled) {
                  bloc.touch();
                  bloc.changeValue(option.value);
                }
              },
            );
          }).toList();

          content = switch (layout) {
            MkRadioLayout.vertical => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: items,
              ),
            MkRadioLayout.horizontal => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(mainAxisSize: MainAxisSize.min, children: items),
              ),
            MkRadioLayout.wrap => Wrap(
                spacing: spacing,
                runSpacing: runSpacing,
                children: items,
              ),
          };
        } else {
          void onSelect(T? val) {
            if (state.isEnabled) {
              bloc.touch();
              bloc.changeValue(val);
            }
          }

          Widget inner;
          switch (layout) {
            case MkRadioLayout.vertical:
              inner = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: options.map((option) {
                  return RadioListTile<T>(
                    value: option.value,
                    title: option.label,
                    subtitle: option.subtitle,
                    activeColor: activeColor,
                    contentPadding: contentPadding,
                    dense: true,
                  );
                }).toList(),
              );
            case MkRadioLayout.horizontal:
              inner = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((option) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<T>(
                            value: option.value,
                            activeColor: activeColor,
                          ),
                          InkWell(
                            onTap: (state.isEnabled && option.enabled)
                                ? () => onSelect(option.value)
                                : null,
                            child: option.label,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            case MkRadioLayout.wrap:
              inner = Wrap(
                spacing: spacing,
                runSpacing: runSpacing,
                children: options.map((option) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<T>(
                        value: option.value,
                        activeColor: activeColor,
                      ),
                      InkWell(
                        onTap: (state.isEnabled && option.enabled)
                            ? () => onSelect(option.value)
                            : null,
                        child: option.label,
                      ),
                    ],
                  );
                }).toList(),
              );
          }

          content = RadioGroup<T>(
            groupValue: state.value,
            onChanged: onSelect,
            child: inner,
          );
        }

        final effectiveMode = autovalidateMode ??
            MkFormScope.maybeAutovalidateModeOf(context) ??
            AutovalidateMode.onUserInteraction;
        final isErrorVisible = state.shouldShowError(effectiveMode);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              title!,
              const SizedBox(height: 4),
            ],
            content,
            if (isErrorVisible && state.error != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  state.getLocalizedError(context) ?? state.error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
