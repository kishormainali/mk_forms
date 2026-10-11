import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../blocs/field_bloc.dart';
import 'form_scope.dart';

/// Base class of every `mk_forms` field widget.
///
/// An [MkFormField] is a real Flutter [FormField], so it participates in an
/// enclosing [Form]: `Form.validate()`, `Form.save()`, `Form.reset()`,
/// `Form.onChanged` and `Form(autovalidateMode: ...)` all work on it. The
/// [MkFieldBloc] stays the single source of truth, though:
///
/// - [FormFieldState.value], `errorText`, `hasError` and `isValid` read the
///   bloc, never a copy.
/// - `didChange` writes to the bloc, `reset` resets the bloc, and `validate`
///   touches the bloc and runs its (sync and async) validators, revealing the
///   error like a submit attempt would.
/// - [FormField.validator] and [FormField.initialValue] are not used: validation
///   and initial values belong to the bloc.
/// - Errors are shown according to the field's [AutovalidateMode] override,
///   the enclosing [MkFormScope], or `onUserInteraction`. [FormField.autovalidateMode]
///   itself is therefore always `disabled`; use [mkAutovalidateMode] to read the
///   override.
///
/// The field is rebuilt only when the bloc's state changes in a way the
/// concrete widget says is visible (see [MkFormFieldState.affectsDisplay]).
abstract class MkFormField<T> extends FormField<T> {
  const MkFormField({
    super.key,
    this.fieldBloc,
    this.name,
    AutovalidateMode? autovalidateMode,
    bool? enabled,
    super.restorationId,
    super.onSaved,
    super.forceErrorText,
  }) : assert(
         fieldBloc != null || name != null,
         'Either fieldBloc or name must be provided',
       ),
       mkAutovalidateMode = autovalidateMode,
       super(builder: _delegateToState, enabled: enabled ?? true);

  /// The field bloc to bind to. If null, [name] is looked up in the nearest
  /// [MkFormScope].
  final MkFieldBloc<T>? fieldBloc;

  /// Name of the field in the nearest [MkFormScope], used when [fieldBloc] is
  /// null.
  final String? name;

  /// Overrides the [AutovalidateMode] of the enclosing [MkFormScope] for this
  /// field. `null` means "use the scope's mode".
  final AutovalidateMode? mkAutovalidateMode;

  /// Builds the visible content of the field.
  ///
  /// Read the live state from `field.bloc.state` (never from a cached copy),
  /// use `field.errorText` for the error to display, and report user edits
  /// with `field.userChange(...)`.
  Widget buildContent(BuildContext context, MkFormFieldState<T> field);

  @override
  MkFormFieldState<T> createState() => MkFormFieldState<T>();

  static Widget _delegateToState(FormFieldState<dynamic> state) {
    final mkState = state as MkFormFieldState<dynamic>;
    return mkState.buildField(mkState.context);
  }
}

/// State of an [MkFormField]. Binds to the field bloc and rebuilds when it
/// changes visibly.
class MkFormFieldState<T> extends FormFieldState<T> {
  MkFieldBloc<T>? _bloc;
  StreamSubscription<MkFieldState<T>>? _subscription;
  MkFieldState<T>? _lastEmitted;
  AutovalidateMode _scopeMode = AutovalidateMode.onUserInteraction;

  /// The widget as an [MkFormField].
  MkFormField<T> get mkWidget => widget as MkFormField<T>;

  /// The bound field bloc.
  MkFieldBloc<T> get bloc => _bloc ?? _bind();

  /// The bloc's current state (always live).
  MkFieldState<T> get fieldState => bloc.state;

  /// The mode that decides when errors are shown: the field's own override,
  /// else the enclosing [MkFormScope]'s, else `onUserInteraction`.
  AutovalidateMode get effectiveAutovalidateMode =>
      mkWidget.mkAutovalidateMode ?? _scopeMode;

  /// Whether the field accepts input: the bloc is enabled and the widget's
  /// `enabled` parameter allows it.
  bool get isFieldEnabled => fieldState.isEnabled && widget.enabled;

  /// Whether moving from [previous] to [current] changes anything on screen.
  /// Override to skip rebuilds for emissions the widget already reflects.
  @protected
  bool affectsDisplay(MkFieldState<T> previous, MkFieldState<T> current) =>
      true;

  /// Builds the field content. Defaults to [MkFormField.buildContent].
  @protected
  Widget buildField(BuildContext context) =>
      mkWidget.buildContent(context, this);

  /// Reports a user edit: updates the bloc, then notifies the enclosing
  /// [Form] (`onChanged`, autovalidate).
  ///
  /// [markTouched] also marks the field touched in the same emission, e.g. for
  /// taps on checkboxes, radios and dropdowns.
  void userChange(T? value, {bool markTouched = false}) {
    final before = bloc.state;
    bloc.changeValue(value, markTouched: markTouched);
    // `FormFieldState.didChange` always calls setState. When the widget says
    // the edit changes nothing on screen (e.g. a keystroke the TextField
    // already shows), keep the Form notification but skip the rebuild.
    _suppressRebuild = !affectsDisplay(before, bloc.state);
    try {
      super.didChange(value);
    } finally {
      _suppressRebuild = false;
    }
  }

  bool _suppressRebuild = false;

  @override
  void setState(VoidCallback fn) {
    if (_suppressRebuild) {
      fn();
      return;
    }
    super.setState(fn);
  }

  MkFieldBloc<T> _bind() {
    final resolved =
        mkWidget.fieldBloc ??
        (mkWidget.name != null ? context.mkField<T>(mkWidget.name!) : null);
    if (resolved == null) {
      throw StateError(
        '${widget.runtimeType} could not find an MkFieldBloc<$T> for name: '
        '"${mkWidget.name}". Ensure the field is registered in the MkFormBloc '
        'and wrapped in an MkFormScope.',
      );
    }
    if (!identical(resolved, _bloc)) {
      unawaited(_subscription?.cancel());
      _bloc = resolved;
      _lastEmitted = resolved.state;
      _subscription = resolved.stream.listen(_onBlocState);
    }
    return resolved;
  }

  void _onBlocState(MkFieldState<T> state) {
    if (!mounted) return;
    final previous = _lastEmitted ?? state;
    _lastEmitted = state;
    if (!affectsDisplay(previous, state)) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(FormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bind();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  // ---- FormFieldState overrides: the bloc is the source of truth ----------

  @override
  T? get value => fieldState.value;

  @override
  String? get errorText {
    final forced = widget.forceErrorText;
    if (forced != null) return forced;
    final state = fieldState;
    return state.shouldShowError(effectiveAutovalidateMode)
        ? state.getLocalizedError(context)
        : null;
  }

  @override
  bool get hasError =>
      widget.forceErrorText != null || fieldState.error != null;

  @override
  bool get isValid => widget.forceErrorText == null && fieldState.isValid;

  @override
  void didChange(T? value) => userChange(value);

  @override
  void reset() {
    bloc.reset();
    super.reset();
  }

  @override
  void clearError() {
    bloc.clearError();
    super.clearError();
  }

  /// Reveals and runs validation, like a submit attempt for this field.
  ///
  /// Returns whether the field is valid right now. Asynchronous validators
  /// started here are still running when this returns; the field then counts
  /// as not valid until they settle.
  @override
  bool validate() {
    if (!widget.enabled) return true;
    bloc
      ..markFormSubmitted()
      ..touch();
    unawaited(bloc.validate());
    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    _bind();
    _scopeMode =
        MkFormScope.maybeAutovalidateModeOf(context) ??
        AutovalidateMode.onUserInteraction;
    if (!fieldState.isVisible) return const SizedBox.shrink();
    return super.build(context);
  }
}
