/// Structural equality for form values.
///
/// Compares maps, sets and other iterables (lists included) element by element,
/// recursively, and falls back to `==` for everything else. Needed because the
/// default `==` on collections is identity, so two lists with the same contents
/// would otherwise look "changed".
bool mkDeepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !mkDeepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is Set && b is Set) {
    return a.length == b.length && a.every(b.contains);
  }
  if (a is Iterable && b is Iterable && a is! Set && b is! Set) {
    final ia = a.iterator;
    final ib = b.iterator;
    while (true) {
      final hasA = ia.moveNext();
      final hasB = ib.moveNext();
      if (hasA != hasB) return false;
      if (!hasA) return true;
      if (!mkDeepEquals(ia.current, ib.current)) return false;
    }
  }
  return a == b;
}
