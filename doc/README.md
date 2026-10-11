# mk_forms Documentation

Full guides for every part of `mk_forms`. Each page explains the concept, lists the API, and ends with a **complete, copy-pasteable example** (a runnable `main()` unless noted).

| # | Guide | What you'll learn |
|---|---|---|
| 1 | [Getting Started](01-getting-started.md) | Install, mental model, your first form |
| 2 | [Field Blocs](02-field-blocs.md) | `MkFieldBloc<T>`, field state, read-only, visibility |
| 3 | [Form Blocs](03-form-blocs.md) | `MkSimpleFormBloc`, `MkFormBloc`, submission lifecycle |
| 4 | [Scope, Builder & Listener](04-scope-builder-listener.md) | `MkFormScope`, `MkFormBuilder`, `MkFormListener`, context extensions |
| 5 | [AutovalidateMode](05-autovalidate-mode.md) | When errors are shown (scope + per-field) |
| 6 | [Validators](06-validators.md) | Built-ins, composing, writing your own |
| 7 | [Dependent & Async Validation](07-dependent-and-async-validation.md) | `dependsOn`, debounce, stale-request cancellation |
| 8 | [Extending Form State](08-extending-form-state.md) | Typed `extra` payload, multiple API calls per form |
| 9 | [Step Forms & Wizards](09-step-forms.md) | `MkStepFormBloc`, draft hydration, multi-route flows |
| 10 | [Subforms](10-subforms.md) | `MkGroupBloc`, `MkSubformBuilder`, `validateGroup` |
| 11 | [Dynamic Field Arrays](11-field-arrays.md) | `MkArrayBloc` add / insert / remove / reorder |
| 12 | [Widget Reference](12-widgets.md) | Every field widget + custom fields, `MkFieldBuilder`, `MkFieldSelector` |
| 13 | [Internationalization](13-i18n.md) | Delegate, overrides, field-aware messages |
| 14 | [Server Errors & Programmatic Control](14-server-errors-and-programmatic-control.md) | `setFieldErrors`, driving fields from code |
| 15 | [Testing](15-testing.md) | Unit-testing fields and forms |
| 16 | [Performance](16-performance.md) | Rebuild control, selectors, grouping, benchmarks |

The `example/` app in this repository contains a runnable screen for most of these topics. For a compact, machine-oriented reference see [`llms.txt`](../llms.txt).
