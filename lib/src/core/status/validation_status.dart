/// Represents the validation status of an individual form control.
enum MkValidationStatus {
  /// The control has passed validation or is in initial valid state.
  valid,

  /// The control has failed validation and has an active error.
  invalid,

  /// The control is currently running asynchronous validation.
  validating,
}
