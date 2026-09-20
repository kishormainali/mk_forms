import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../core/di/injection.dart';
import 'bloc/all_fields_form_bloc.dart';

/// Complete showcase screen featuring all built-in mk_forms fields powered by [AllFieldsFormBloc].
@RoutePage()
class AllFieldsScreen extends StatefulWidget {
  const AllFieldsScreen({
    super.key,
    AllFieldsFormBloc? formBloc,
  }) : _formBloc = formBloc;

  final AllFieldsFormBloc? _formBloc;

  @override
  State<AllFieldsScreen> createState() => _AllFieldsScreenState();
}

class _AllFieldsScreenState extends State<AllFieldsScreen> {
  late final AllFieldsFormBloc _formBloc;

  @override
  void initState() {
    super.initState();
    _formBloc = widget._formBloc ?? getIt<AllFieldsFormBloc>();
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
        title: const Text('All Fields Showcase'),
      ),
      body: MkFormScope.value(
        value: _formBloc,
        child: MkFormListener(
          formBloc: _formBloc,
          onSuccess: (context, response) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Form submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Text Inputs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                const MkTextField(
                  name: 'fullName',
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                const MkEmailField(name: 'email'),
                const SizedBox(height: 16),
                const MkPasswordField(name: 'password'),
                const Divider(height: 36),
                Text(
                  'Dropdowns & Selectors',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                const MkDropdownField<String>(
                  name: 'country',
                  hint: Text('Select Country'),
                  decoration: InputDecoration(
                    labelText: 'Country of Residence',
                    prefixIcon: Icon(Icons.public),
                  ),
                  items: [
                    DropdownMenuItem(value: 'US', child: Text('United States')),
                    DropdownMenuItem(
                        value: 'UK', child: Text('United Kingdom')),
                    DropdownMenuItem(value: 'DE', child: Text('Germany')),
                    DropdownMenuItem(value: 'JP', child: Text('Japan')),
                    DropdownMenuItem(value: 'NP', child: Text('Nepal')),
                  ],
                ),
                const SizedBox(height: 16),
                MkMultiSelectSearchDropdown<String>(
                  name: 'technologies',
                  modalTitle: 'Select Technologies',
                  searchHint: 'Search tech stacks...',
                  items: const [
                    'Flutter',
                    'Dart',
                    'Bloc',
                    'Kotlin',
                    'Swift',
                    'TypeScript',
                    'Python',
                    'Rust',
                    'Go',
                    'Docker',
                  ],
                  itemToString: (item) => item,
                  decoration: const InputDecoration(
                    labelText: 'Skills / Tech Stack',
                    prefixIcon: Icon(Icons.code),
                  ),
                ),
                const Divider(height: 36),
                Text(
                  'Radio Groups',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                const MkRadioGroup<String>(
                  name: 'plan',
                  title: Text(
                    'Select Plan (Wrap Layout):',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  layout: MkRadioLayout.wrap,
                  options: [
                    MkRadioOption(value: 'free', label: Text('Free Tier')),
                    MkRadioOption(value: 'pro', label: Text('Pro (\$19/mo)')),
                    MkRadioOption(
                      value: 'enterprise',
                      label: Text('Enterprise'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const MkRadioGroup<String>(
                  name: 'role',
                  title: Text(
                    'Select Role (Vertical Layout):',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  options: [
                    MkRadioOption(
                      value: 'developer',
                      label: Text('Software Engineer'),
                      subtitle: Text('Full-stack, frontend, or backend'),
                    ),
                    MkRadioOption(
                      value: 'designer',
                      label: Text('UI/UX Designer'),
                      subtitle: Text('Design systems & prototyping'),
                    ),
                    MkRadioOption(
                      value: 'manager',
                      label: Text('Product Manager'),
                      subtitle: Text('Roadmap and strategy'),
                    ),
                  ],
                ),
                const Divider(height: 36),
                Text(
                  'Checkboxes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                const MkCheckboxField(
                  name: 'agreeTerms',
                  title:
                      Text('I agree to the Terms of Service & Privacy Policy'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _formBloc.submit(),
                  child: const Text('Submit Showcase Form'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _formBloc.reset(),
                  child: const Text('Reset All Fields'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
