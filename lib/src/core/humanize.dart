/// Converts a camelCase, snake_case, or kebab-case field name into a
/// sentence-case, human-readable label.
///
/// Examples: `'email'` -> `'Email'`, `'confirmPassword'` -> `'Confirm
/// password'`, `'agree_terms'` -> `'Agree terms'`.
///
/// Consecutive uppercase letters (an acronym, e.g. `'userID'`) are not
/// split apart — the whole run is treated as one word and lowercased like
/// any other, so `'userID'` becomes `'User id'` rather than `'User I D'`.
String mkHumanizeFieldName(String name) {
  if (name.isEmpty) return name;

  final spaced = name
      .replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (m) => ' ')
      .replaceAll(RegExp(r'[_\-]+'), ' ');

  final words = spaced
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return name;

  final lower = words.map((w) => w.toLowerCase()).toList();
  lower[0] = lower[0][0].toUpperCase() + lower[0].substring(1);
  return lower.join(' ');
}
