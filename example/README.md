# mk_forms_example

A runnable gallery of `mk_forms` features. From this folder:

```bash
flutter run
```

| Screen | Shows |
|---|---|
| Minimal Login Form | `MkSimpleFormBloc`, pristine initial state |
| Multi-Route Onboarding Wizard | `MkStepFormBloc`, route-per-step, API draft hydration |
| Independent Subforms (Checkout) | `MkGroupBloc`, `MkSubformBuilder`, `validateGroup` |
| Cross-Field Dependent Validation | `dependsOn` |
| Debounced Async Validation | async validators, in-flight spinner |
| Dynamic Array Forms | `MkArrayBloc` + `MkArrayBuilder` |
| All Fields Showcase | every field widget |
| Internationalization | delegate, scoped overrides, live locale switch |
| Custom Design System | custom radio cards and chips |
| Autovalidate Modes | scope and per-field `AutovalidateMode` |
| Extended Form State | typed `extra`, concurrent API calls |
| Flutter Form Integration | fields inside a `Form`: `validate`/`save`/`reset`, `forceErrorText` |
| Large Form Performance | 200 fields + array with `MkFormSelector`/`MkSubformBuilder`/`MkArrayBuilder` |

After changing routes or injectable classes, regenerate code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Full documentation lives in [`../doc`](../doc/README.md).
