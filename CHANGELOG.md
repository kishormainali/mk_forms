# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.4.0] - 2026-10-29

### Added
- **`MkArrayBloc.addAll`, `replaceAll` and `batch`** — apply many structural changes with a single aggregate recompute and a single state emission. `replaceAll` keeps controls that are in both lists and closes only the removed ones (or none with `dispose: false`).

### Changed
- Performance: fewer allocations and one equality check instead of two per state change; `MkArrayBloc.controls` / `state.controls` keep the same list instance across row edits; `MkFormBloc.reset()` no longer re-walks the control tree. `reset()` and `populateValues()` are roughly twice as fast on large forms.
- `MkGroupBloc.close()` and `MkArrayBloc.close()` close their children concurrently.
- The multi-select modal filters its items only when the search query changes (not on every selection tap) and looks up selected rows in a set.
- A batched bulk operation now recomputes its aggregate even if the action throws, so the state is never left stale.

---

## [1.3.0] - 2026-10-11

### Added
- **`MkArrayBuilder<C>`** — builds from an `MkArrayBloc` and, by default, rebuilds only when the list of controls changes (add/insert/remove/move), not when a row's value changes. A plain `BlocBuilder` on an array rebuilds every row on every keystroke in any row, because `MkArrayState.values` changes each time. Accepts `arrayBloc` or `name` (via `MkFormScope`) and an optional `buildWhen`.
  `rebuildOnValueChange: true` opts in to also rebuilding when any row's value changes (for UI that displays the values).
- **`MkFormSelector<R>` — `BlocSelector` for form state (e.g. `(s) => s.canSubmit`), so widgets that need one flag no longer rebuild on every keystroke (`MkFormState.values` changes constantly).

### Changed
- **All field widgets are now Flutter `FormField`s.** A new base class `MkFormField<T>` (with `MkFormFieldState<T>`) is shared by `MkTextField`, `MkEmailField`, `MkPasswordField`, `MkCheckboxField`, `MkRadioGroup`, `MkDropdownField` and `MkMultiSelectSearchDropdown`. Inside a `Form`, `validate()`, `save()`, `reset()`, `onChanged` and `forceErrorText` now work with them, and every field accepts `onSaved:` and `forceErrorText:`. The bloc remains the source of truth, and fine-grained rebuilds are preserved (typing still doesn't rebuild the `TextField`).
- `MkEmailField` and `MkPasswordField` now extend `MkTextField` (instead of wrapping it).
- `MkDropdownField` now renders a `DropdownButton` in an `InputDecorator` (what `DropdownButtonFormField` does internally) so there is exactly one `FormField` per field.
- Reading `widget.enabled` / `widget.autovalidateMode` on a field now yields `FormField`'s members (`bool` / always `AutovalidateMode.disabled`). The constructor parameters are unchanged; the autovalidate override is available as `widget.mkAutovalidateMode`. `restorationId` is now also forwarded to `FormField`.

### Performance
- `populateValues` (and therefore `loadInitialData`) now applies the payload in one batch: one aggregate recompute and one form emission instead of one per field. 2,000 fields: ~480 ms → ~5 ms.
- `validateControls` / `validateStep` and `setFieldErrors` are batched the same way (validating a 20-field step in a 2,000-field form: ~12 ms → ~2 ms).

### Fixed
- **`MkDropdownField` and `MkMultiSelectSearchDropdown` showed the label and the hint at the same time** (the hint was drawn on top of the label). They now follow the Material `TextField` rule: with a label, the hint stays hidden until the label has floated (field focused, or `floatingLabelBehavior: always`); without a label the hint is always shown. The hint keeps its layout space, so the field doesn't change height. The multi-select now also reports `isEmpty`/`isFocused` to its `InputDecorator`, so its label floats correctly when focused.
- **`nextStep()` / `goToStep()` could skip a step** when called twice before validation finished (double tap, slow async validators): both calls advanced. Navigation is now serialized; a call made while another is in flight is ignored and returns `false`, which also prevents a double route push.
- **`MkTextField` (and `MkEmailField`/`MkPasswordField`) reverted or dropped typed characters whenever a parent rebuilt on each keystroke** — most visibly rows inside a dynamic array (typing lagged, text disappeared, values lagged). The field skips rebuilds for value-only changes, which left its `BlocBuilder`'s cached state one keystroke behind; the next parent rebuild wrote that stale value back into the text controller. It now always renders from the bloc's live state.

### Docs
- New `doc/` folder: 16 guides, each with a complete runnable example, including a Performance guide.
- Fixed the README/`llms.txt` step-form snippet: `BlocBuilder<MyStepBloc, MkStepFormState>` does not compile (the declared state type is `MkFormState`); use `MkFormStateBuilder<MkStepFormState>`.
- The dynamic-array example now uses `MkArrayBuilder`.

---

## [1.2.1] - 2026-09-30

### Docs
- Documented `MkFormLocalizations.current`'s role as a no-`BuildContext` fallback only (used by `MkValidators`, which run in the bloc layer) — every built-in widget already resolves messages through `MkFormLocalizationsDelegate`/`Localizations.of` first, the same pattern `flutter_localizations` uses. Clarified in code doc comments (`form_localizations.dart`, `validation.dart`), `README.md`, and `llms.txt`. No behavior change.
- `README.md` and `llms.txt` now document `MkFieldSelector<T, R>` and `MkFieldBloc.isReadOnly`/`setReadOnly`, both added in 1.2.0 but missing from user-facing docs until now.
- Updated stale `mk_forms: ^1.x.x` install snippets in `README.md`/`llms.txt` to `^1.2.1`.

## [1.2.0] - 2026-09-27

### Added
- **`MkFieldSelector<T, R>`** — a `MkFieldBuilder` sibling analogous to `flutter_bloc`'s `BlocSelector`: rebuilds only when a value derived from `MkFieldState<T>` via `selector` actually changes (e.g. just `state.error`), instead of on every field-state emission. Same field resolution (`fieldBloc` or `name` via the nearest `MkFormScope`) and `hideWhenInvisible` behavior as `MkFieldBuilder`; the builder receives `(context, selected, fieldBloc)`.
- **`MkFieldBloc.isReadOnly`** — a new bloc-level flag (constructor param, default `false`, plus `setReadOnly(bool)`) that excludes a field from validation entirely: while read-only, no validator (sync or async) runs, `error`/`isValidating` stay cleared, and `isValid` is always `true` — so a read-only field never blocks the enclosing `MkGroupBloc`/`MkFormBloc` from being valid. Turning it on clears any existing error immediately; turning it off re-validates against the current value. This is independent of the existing, purely presentational `readOnly` prop on `MkTextField`/`MkEmailField`/`MkPasswordField` (which only blocks typing and is unrelated to validation).

## [1.1.1] - 2026-09-27

### Fixed
- **Memory leak: dynamically removing a control from a live `MkGroupBloc` or `MkArrayBloc` now closes it by default.** `MkGroupBloc.removeControl`/`addControl` and `MkArrayBloc.removeAt`/`remove`/`clear` previously detached a removed control's listeners from its parent but never called `close()` on the removed control itself — every runtime "remove a row" / "remove a field" operation leaked one un-closed control, and if that control had an active `addDependency` on another still-live control, it stayed reachable (and kept being revalidated) forever. Whole-form/whole-array teardown via `close()` was never affected — only dynamic partial removal.
  - All four methods gain an optional `dispose`/`disposeReplaced` parameter (default `true`, matching the fixed behavior) for the rare case of intentionally re-parenting a control from one array/group to another without disposing it.
  - `removeAt`/`remove` are unchanged in what they return (the removed control). `removeControl` and `MkArrayBloc.clear()` now return what they removed (`removeControl`: the removed control, previously `void`; `clear()`: the removed `List<C>`, previously `void`) so a caller passing `dispose: false` can still reach them.
  - `addControl`/`registerControl` re-registering the *same* control instance under the key it already occupies no longer closes it — only a genuine replacement (a different instance) is disposed.
  - `MkFormBloc.registerControl`/`unregisterControl` gained the same `disposeReplaced`/`dispose` opt-out as `MkGroupBloc`, and `unregisterControl` now returns the removed control (previously `void`) — needed for the common "toggle a conditional field off and back on" pattern, where the same field instance is unregistered and later re-registered rather than disposed.

### Performance
- `MkValidators.pattern()` now compiles its `RegExp` once, when the validator is constructed, instead of once per validation call.

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
- **Field-aware validation messages.** Built-in validators (`required`, `email`, `minLength`, `maxLength`, `min`, `max`, `pattern`, `match`) now produce messages that name the field, e.g. `"Email is required."` instead of `"This field is required"`.
  - **This changes default text, not just adds an option.** Any field registered in an `MkGroupBloc` — which includes every field inside `MkFormBloc`/`MkStepFormBloc`, the common case — is auto-labeled and gets the new field-aware message from `MkDefaultEnglishMessages`/`MkSpanishMessages`. A field is only unaffected if it's never added to a group and has no explicit `label`.
  - A field's label is auto-derived from its key in the controls map (`'confirmPassword'` -> `"Confirm password"`). Override with an explicit `label:` on `MkFieldBloc`'s constructor when the auto-derived label isn't right.
  - Labels are derived from the (typically English) identifier used as the controls-map key, so a non-English `MkFormMessages` (e.g. `MkSpanishMessages`) will show that label alongside its own translated sentence (e.g. `"Confirm password no coincide."`) unless every field is given an explicit, translated `label:`.
  - `MkFormMessages` gained `resolveField(errorCode, field, [params])` plus 8 new overridable `*Field(...)` methods. **They default to returning `null`** on the abstract `MkFormMessages` class — an app that implements `MkFormMessages` directly (the "entirely custom language" pattern this class's own doc comment describes) is unaffected unless it opts in by overriding them. `MkDefaultEnglishMessages` and `MkSpanishMessages` provide concrete overrides, so apps using those as-is get the new text automatically.
  - **Migration note:** if you extend `MkDefaultEnglishMessages` or `MkSpanishMessages` and override only the base methods (`required()`, `email()`, etc. — the pattern in this package's own README), your override is still used for fields with no label, but a *labeled* field falls back to the built-in field-aware text, not your override. Also override the corresponding `*Field` method (or override `resolveField` to return `null`) to keep your customization for labeled fields too.
  - `resolve()` and every pre-existing `MkFormMessages` method are unchanged.
  - A field that's never registered in a group and has no explicit `label` behaves exactly as before this change.

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
