# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-09-24

### Added
- **Extensible form state via generics.** `MkFormState<T>` carries a single typed `extra` field, so one form can track several independent API calls (upload, availability check, OTP) or extra statuses — with no state subclass to write. See "Extending Form State" in the README.
  - `MkFormBloc<T>` / `MkStepFormBloc<T>` — generic over the same `T`; `state` is already typed, with no downcast in application code. Both accept `initialExtra`/`extraReset`/`isExtraBusy` directly, so an extras-using bloc doesn't have to hand-build its `initialState:` from `controls`.
  - `MkFormState.updateExtra(fn)` — shorthand for `copyWith(extra: () => fn(extra))`.
  - `MkFormState.copyWith`'s `extra` parameter is a zero-arg function (`T Function()?`), like `submissionError`, so a nullable `extra` can be explicitly cleared to `null` — `copyWith(extra: () => null)` — distinct from omitting it.
  - `MkFormState.isBusy` — reflects `isSubmitting` plus `isExtraBusy(extra)` (set once via the constructor); `canSubmit` and `MkFormBloc.submit()` respect it.
  - `MkFormState.reset(...)` — regenerates `extra` via `extraReset` (set once via the constructor), or leaves it unchanged if omitted.
  - `MkFormStateBuilder<S extends MkFormState>` and `MkFormStateWidgetBuilder<S>` — unchanged in shape; used as `MkFormStateBuilder<MkFormState<YourExtra>>`. `MkFormBuilder` is unchanged.
  - Every pre-existing "no extras" form needs no source changes: omitting the type argument (`extends MkFormBloc`, `extends MkStepFormBloc`) still compiles.

### Fixed
- `MkFormBloc.reset()` dropped subclass state by emitting a plain `MkFormState`. Resetting `extra` is now built into `MkFormState.reset()` via `extraReset`, and `MkStepFormBloc` no longer needs its own `reset()`/`onUpdateFormState()` overrides.

### Changed
- This replaces the subclassing-based extensible-state design from the previous unreleased 1.1.0 draft (never published). If you were tracking that draft: subclass `ProfileFormState extends MkFormState` becomes `MkFormBloc<ProfileExtras>` with `extra: const ProfileExtras()`; `state.extras` becomes `state.extra`.

---

## [1.0.1] - 2026-09-20

### Added
- **`MkFormBuilder`** — Rebuilds from `MkFormState` (with optional `formBloc` and `buildWhen`), mirroring `MkFormListener`.
- **All field widgets now expose the parameters of the Flutter widget they wrap**, so they can be customized without rebuilding them:
  - `MkTextField`, `MkEmailField`, `MkPasswordField`: every `TextField` parameter (`inputFormatters`, `cursor*`, `autofillHints`, `contextMenuBuilder`, `onTap`, `onEditingComplete`, `focusNode`, `buildCounter`, `undoController`, …) except `controller`. `focusNode` may be supplied (it is never disposed by the widget); `enabled` combines with the bloc's state. `MkPasswordField` gains `initiallyObscured`.
  - `MkCheckboxField`: every `CheckboxListTile` parameter (`tristate`, `fillColor`, `shape`, `side`, `controlAffinity`, …), plus `onChanged`, `enabled`, `errorStyle`, `errorPadding`. `isError` defaults to "an error is shown".
  - `MkDropdownField`: every `DropdownButtonFormField` parameter that is not a `FormField` member (`selectedItemBuilder`, `isExpanded`, `icon`, `dropdownColor`, `menuMaxHeight`, …), plus `enabled`.
  - `MkRadioGroup`: the `RadioListTile` / `Radio` parameters at group level, `MkRadioOption.secondary`, `onChanged`, `enabled`, `highlightSelected`, `errorStyle`.
  - `MkMultiSelectSearchDropdown`: `InkWell`, `InputChip`, bottom sheet and dialog parameters (`chip*`, `sheet*`, `dialog*`), plus localizable labels (`doneLabel`, `selectAllLabel`, `clearAllLabel`, `moreLabelBuilder`), `showSelectAll`, `icon`, `hintStyle`, `onChanged`, `enabled`.
- Only parameters available in Flutter 3.41 are exposed (the version this package's own code already requires).

### Fixed
- `MkMultiSelectSearchDropdown` only rendered the first picked item: the modal handed the field its own mutable list, so later picks looked like no-ops to the bloc. It now reports a copy.
- `MkFormBloc` / `MkStepFormBloc` leaked a second, never-closed `MkGroupBloc` (and one extra listener per control) while building their initial state.
- `MkFormBloc.submit()` could run `onSubmit` twice when called again while validation was still in progress.
- Editing a field while async validation was in flight made `submit()` silently do nothing. A superseded `MkFieldBloc.validate()` now resolves to the outcome of the newer validation.
- Mapping server errors onto fields inside `onSubmitFailure` (or touching a field) no longer wipes the failure state; only real value edits clear it.
- `MkValidators.email` rejected valid addresses with hyphenated domains and accepted trailing garbage, commas and `a@b.c@@@`. It is now anchored and follows the HTML5 rule.
- `dependsOn` no longer runs async validators at construction, no longer validates twice per dependency change, and debounces the async part like `changeValue`. Dependents also detach from their dependency on `close()`, and group/array dependencies only trigger when their contents actually change.
- A throwing async validator no longer shows the raw exception text (hostnames, stack details). The field gets a generic localized message (`MkErrorCodes.asyncValidationFailed`, English and Spanish included) and the error is reported through `onError` / `BlocObserver`.
- `isDirty` compares collection values (lists, sets, maps) by contents instead of identity.
- Async work finishing after `close()` (`submit()`, `validate()`, `nextStep()`, `goToStep()`, `validateStep()`, `loadInitialData()`, `reset()`) no longer throws "Cannot emit new states after calling close".
- `MkRadioGroup` (vertical layout) ignored `MkRadioOption.enabled` and the bloc's enabled state visually; disabled options now render as disabled.
- The multi-select modal title could overflow next to the Done button; it now ellipsizes.

### Performance
- Bulk operations (`touch`, `reset`, `markFormSubmitted`, `validate`) on groups, arrays and forms recompute the aggregate once instead of once per child. `submit()` on a 1000-field form went from ~315 ms to ~16 ms and `reset()` from ~105 ms to ~1 ms.
- Aggregate flags and nested values are read from cached state instead of re-walking the subtree.
- State listeners are only notified when a control's state actually changed.
- `MkTextField` no longer rebuilds on every keystroke when nothing visible changes.
- Added `MkFieldBloc.changeValue(value, markTouched: true)`; checkbox, radio and dropdown widgets use it to emit (and rebuild) once per interaction instead of twice.

### Changed
- **Minimum versions corrected to Flutter `>=3.41.0` / Dart `>=3.9.0`.** The code already required them (`AutovalidateMode.onUserInteractionIfError` ships in 3.41, `RadioGroup` and the dropdown's `initialValue` in 3.35); the previous `>=3.10.0` made older Flutter fail at compile time instead of at version resolution.
- **`MkFormScope`** is now a `StatelessWidget` built on `BlocProvider` instead of a custom `InheritedWidget`, with the same two constructors: `MkFormScope(create:, lazy:)` creates and closes the bloc, `MkFormScope.value(value:)` exposes an existing one without closing it. **Breaking:** `MkFormScope(formBloc: x)` is now `MkFormScope.value(value: x)`.
- `MkFormScope.of` no longer registers a rebuild dependency (use `MkFormBuilder`).
- `MkFieldBloc.validate({cascadeDependents})`: the parameter is deprecated and ignored; dependents are revalidated when the dependency's value changes.
- Upgraded `equatable` to `^3.0.0`.
- Dependencies bumped: `bloc ^9.2.1`, `flutter_bloc ^9.1.1`, `meta ^1.19.0` (dev: `bloc_test ^10`, `mocktail ^1.0.5`, `flutter_lints ^6`). Removed the unused `rxdart` dependency.
- **Tree shaking verified.** Unused widgets, validators, the step-form bloc and the Spanish messages are removed from release builds; the package also builds with `flutter build web --wasm` and keeps Flutter's icon tree shaking intact (see README, *Tree Shaking & Bundle Size*).

---

## [1.0.0] - 2026-09-19

### 🎉 Initial stable release

#### Core Architecture
- **`MkFieldBloc<T>`** — Reactive field BLoC managing value, sync/async validation, dirty/touched/pristine state, debouncing, and cross-field dependencies.
- **`MkFormBloc`** — Abstract coordinator BLoC managing aggregated validation, submission lifecycle, and automatic submission-error clearing on edit.
- **`MkSimpleFormBloc`** — Lightweight `MkFormBloc` with an inline `onSubmit` closure — no subclass required for simple forms.
- **`MkStepFormBloc`** — Multi-step wizard BLoC with granular per-step validation gating, multi-route state preservation, and API draft hydration.
- **`MkSimpleStepFormBloc`** — Inline-closure variant of `MkStepFormBloc`.
- **`MkGroupBloc`** — Groups named controls into an independently validatable subform.
- **`MkArrayBloc<C>`** — Dynamic array of form controls with add, insert, remove, and move operations.

#### Validation
- Built-in `MkValidators`: `required`, `email`, `minLength`, `maxLength`, `min`, `max`, `pattern`, `match`, `matchControl`, `compose`, `composeAsync`.
- Async validators with configurable debounce time and automatic stale-request cancellation.
- Cross-field `dependsOn` — automatic revalidation when a dependency field changes, without recursion loops.
- Server error mapping via `setFieldErrors(Map<String, String>)`.
- Partial-form validation: `validateGroup(name)`, `validateControls([names])`, `validateStep([step])`.

#### AutovalidateMode Support
- `AutovalidateMode.always` — errors shown immediately, even on pristine fields.
- `AutovalidateMode.onUserInteraction` *(default)* — errors shown after touch or submit attempt.
- `AutovalidateMode.onUnfocus` — errors shown after field blur or submit attempt.
- `AutovalidateMode.onUserInteractionIfError` — same as `onUserInteraction`.
- `AutovalidateMode.disabled` — errors shown only after submit attempt.
- Configurable at `MkFormScope` level (scope-wide default) or per-field (override).
- `MkFieldState.shouldShowError([AutovalidateMode])` for custom widget integration.

#### Form State & Lifecycle
- `MkFieldState<T>`: `value`, `initialValue`, `error`, `isDirty`, `isTouched`, `isValidating`, `isValid`, `isInvalid`, `isPure`, `wasFormSubmitted`, `showError`, `shouldShowError([mode])`.
- `MkFormState`: `isValid`, `isValidating`, `isDirty`, `isTouched`, `isSubmitting`, `isSuccess`, `isFailure`, `submissionError`, `values`.
- `MkStepFormState`: extends `MkFormState` with `currentStep`, `totalSteps`, `completedSteps`, `isLoadingInitialData`, `redirectedFromStep`, `invalidStepIndex`.
- `populateValues(data, {markPristine: true})` — hydrate fields from API response without triggering premature errors.
- `loadInitialData(loader, {resolveInitialStep})` — async draft loading with smart redirect to earliest invalid step.
- `reset()` — resets form and all controls to their initial values.

#### UI Widgets
- **`MkFormScope`** — `InheritedWidget` providing form bloc and default `AutovalidateMode` to descendants. Context extensions: `context.mkForm`, `context.mkField<T>(name)`, `context.mkGroup(name)`, `context.mkAutovalidateMode`.
- **`MkFormListener`** — Side-effect listener for submission status with `onSubmitting`, `onSuccess`, `onFailure` callbacks.
- **`MkFieldBuilder<T>`** — Fine-grained BlocBuilder for a single field with optional `buildWhen`.
- **`MkSubformBuilder`** — Isolated BlocBuilder for a named `MkGroupBloc`; changes in one subform never rebuild siblings.
- **`MkTextField`** — Material text field with automatic focus/blur tracking and controller sync.
- **`MkEmailField`** — Pre-configured email keyboard, autofill, and format validation.
- **`MkPasswordField`** — Obscured input with show/hide eye toggle.
- **`MkCheckboxField`** — Checkbox with error label and custom label widget.
- **`MkRadioGroup<T>`** — Vertical/horizontal/wrap layout; supports custom `optionBuilder`.
- **`MkDropdownField<T>`** — Single-selection dropdown.
- **`MkMultiSelectSearchDropdown<T>`** — Multi-selection with live search, chips, select-all/clear, bottom-sheet or dialog.

#### Internationalization (i18n)
- `MkFormLocalizations.delegate` — standard `flutter_localizations` integration.
- Built-in English (`DefaultEnglishMessages`) and Spanish (`SpanishMessages`) message sets.
- Global override: `MkFormLocalizations.current = MyMessages()`.
- Scoped override: `MkLocalizationScope(messages: ..., child: ...)`.
- Dynamic runtime locale switching — validation errors update instantly without UI jank.
- `MkErrorCodes` — error code constants for i18n message resolution.

#### Testing
- 68 unit and widget tests covering field blocs, form lifecycle, step forms, subform validation, array blocs, validators, localization, all field widgets, and all `AutovalidateMode` variants.
