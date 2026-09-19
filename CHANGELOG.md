# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
