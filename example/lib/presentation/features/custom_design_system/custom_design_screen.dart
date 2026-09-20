import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../core/di/injection.dart';
import 'bloc/custom_design_form_bloc.dart';

/// Screen demonstrating custom design system integration with mk_forms
/// powered by [CustomDesignFormBloc].
///
/// Shows:
/// - Custom selectable Card radios via [itemBuilder].
/// - Custom chips via [chipBuilder].
/// - Custom design styling adhering to modern UI guidelines.
@RoutePage()
class CustomDesignScreen extends StatefulWidget {
  const CustomDesignScreen({
    super.key,
    CustomDesignFormBloc? formBloc,
  }) : _formBloc = formBloc;

  final CustomDesignFormBloc? _formBloc;

  @override
  State<CustomDesignScreen> createState() => _CustomDesignScreenState();
}

class _CustomDesignScreenState extends State<CustomDesignScreen> {
  late final CustomDesignFormBloc _formBloc;

  @override
  void initState() {
    super.initState();
    _formBloc = widget._formBloc ?? getIt<CustomDesignFormBloc>();
  }

  @override
  void dispose() {
    unawaited(_formBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Design System'),
      ),
      body: MkFormScope.value(
        value: _formBloc,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Custom Card-Style Radio Selection',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              MkRadioGroup<String>(
                name: 'billingCycle',
                options: const [
                  MkRadioOption(
                    value: 'monthly',
                    label: Text('Monthly Plan'),
                    subtitle: Text('\$12 / billed monthly'),
                  ),
                  MkRadioOption(
                    value: 'annual',
                    label: Text('Annual Plan (Save 20%)'),
                    subtitle: Text('\$115 / billed yearly'),
                  ),
                ],
                itemBuilder: (context, option, isSelected, onSelect) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onSelect,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DefaultTextStyle(
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    child: option.label,
                                  ),
                                  if (option.subtitle != null) ...[
                                    const SizedBox(height: 4),
                                    DefaultTextStyle(
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      child: option.subtitle!,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Custom Pill Multi-Select Chips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              MkMultiSelectSearchDropdown<String>(
                name: 'interests',
                modalTitle: 'Choose Your Interests',
                items: const [
                  'Mobile',
                  'Web',
                  'Backend',
                  'Design',
                  'DevOps',
                  'AI / ML',
                  'Cybersecurity',
                ],
                itemToString: (item) => item,
                decoration: InputDecoration(
                  labelText: 'Areas of Interest',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                chipBuilder: (context, item, onRemove) {
                  return Chip(
                    label: Text(
                      item,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: onRemove,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _formBloc.submit(),
                child: const Text('Save Preferences'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
