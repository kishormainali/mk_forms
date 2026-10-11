import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

TextField _textField(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

void main() {
  group('MkTextField forwards TextField parameters', () {
    testWidgets('every parameter reaches the TextField', (tester) async {
      final field = MkFieldBloc<String>();
      final formatters = <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ];
      final scroll = ScrollController();
      final undo = UndoHistoryController();
      final states = WidgetStatesController();
      const strut = StrutStyle(fontSize: 22);
      const style = TextStyle(fontSize: 18);
      const cursorRadius = Radius.circular(3);
      void onEditingComplete() {}
      void onTapOutside(PointerDownEvent _) {}
      void onTapUpOutside(PointerUpEvent _) {}
      void onAppPrivateCommand(String a, Map<String, dynamic> b) {}
      Widget counter(
        BuildContext c, {
        required int currentLength,
        required bool isFocused,
        required int? maxLength,
      }) => const Text('counter');
      final insertion = ContentInsertionConfiguration(
        onContentInserted: _noContent,
      );
      const spell = SpellCheckConfiguration.disabled();
      const magnifier = TextMagnifierConfiguration();
      const hintLocales = [Locale('en', 'GB')];
      final key = Object();

      await tester.pumpWidget(
        _host(
          MkTextField(
            fieldBloc: field,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.words,
            style: style,
            strutStyle: strut,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.bottom,
            textDirection: TextDirection.rtl,
            showCursor: false,
            obscureText: true,
            obscuringCharacter: '*',
            autocorrect: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            enableSuggestions: false,
            maxLength: 12,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            onEditingComplete: onEditingComplete,
            onAppPrivateCommand: onAppPrivateCommand,
            inputFormatters: formatters,
            ignorePointers: false,
            cursorWidth: 4,
            cursorHeight: 21,
            cursorRadius: cursorRadius,
            cursorOpacityAnimates: true,
            cursorColor: Colors.red,
            cursorErrorColor: Colors.orange,
            selectionHeightStyle: ui.BoxHeightStyle.max,
            selectionWidthStyle: ui.BoxWidthStyle.max,
            keyboardAppearance: Brightness.dark,
            scrollPadding: const EdgeInsets.all(7),
            enableInteractiveSelection: false,
            selectAllOnFocus: true,
            dragStartBehavior: DragStartBehavior.down,
            onTapAlwaysCalled: true,
            onTapOutside: onTapOutside,
            onTapUpOutside: onTapUpOutside,
            mouseCursor: SystemMouseCursors.text,
            buildCounter: counter,
            scrollController: scroll,
            scrollPhysics: const ClampingScrollPhysics(),
            autofillHints: const [AutofillHints.username],
            contentInsertionConfiguration: insertion,
            clipBehavior: Clip.none,
            restorationId: 'restoration',
            stylusHandwritingEnabled: false,
            enableIMEPersonalizedLearning: false,
            undoController: undo,
            spellCheckConfiguration: spell,
            magnifierConfiguration: magnifier,
            hintLocales: hintLocales,
            groupId: key,
            statesController: states,
          ),
        ),
      );

      final tf = _textField(tester);
      expect(tf.keyboardType, TextInputType.number);
      expect(tf.textInputAction, TextInputAction.search);
      expect(tf.textCapitalization, TextCapitalization.words);
      expect(tf.style, style);
      expect(tf.strutStyle, strut);
      expect(tf.textAlign, TextAlign.center);
      expect(tf.textAlignVertical, TextAlignVertical.bottom);
      expect(tf.textDirection, TextDirection.rtl);
      expect(tf.showCursor, isFalse);
      expect(tf.obscureText, isTrue);
      expect(tf.obscuringCharacter, '*');
      expect(tf.autocorrect, isFalse);
      expect(tf.smartDashesType, SmartDashesType.disabled);
      expect(tf.smartQuotesType, SmartQuotesType.disabled);
      expect(tf.enableSuggestions, isFalse);
      expect(tf.maxLength, 12);
      expect(tf.maxLengthEnforcement, MaxLengthEnforcement.none);
      expect(tf.onEditingComplete, same(onEditingComplete));
      expect(tf.onAppPrivateCommand, same(onAppPrivateCommand));
      expect(tf.inputFormatters, same(formatters));
      expect(tf.ignorePointers, isFalse);
      expect(tf.cursorWidth, 4);
      expect(tf.cursorHeight, 21);
      expect(tf.cursorRadius, cursorRadius);
      expect(tf.cursorOpacityAnimates, isTrue);
      expect(tf.cursorColor, Colors.red);
      expect(tf.cursorErrorColor, Colors.orange);
      expect(tf.selectionHeightStyle, ui.BoxHeightStyle.max);
      expect(tf.selectionWidthStyle, ui.BoxWidthStyle.max);
      expect(tf.keyboardAppearance, Brightness.dark);
      expect(tf.scrollPadding, const EdgeInsets.all(7));
      expect(tf.enableInteractiveSelection, isFalse);
      expect(tf.selectAllOnFocus, isTrue);
      expect(tf.dragStartBehavior, DragStartBehavior.down);
      expect(tf.onTapAlwaysCalled, isTrue);
      expect(tf.onTapOutside, same(onTapOutside));
      expect(tf.onTapUpOutside, same(onTapUpOutside));
      expect(tf.mouseCursor, SystemMouseCursors.text);
      expect(tf.buildCounter, same(counter));
      expect(tf.scrollController, same(scroll));
      expect(tf.scrollPhysics, isA<ClampingScrollPhysics>());
      expect(tf.autofillHints, const [AutofillHints.username]);
      expect(tf.contentInsertionConfiguration, same(insertion));
      expect(tf.clipBehavior, Clip.none);
      expect(tf.restorationId, 'restoration');
      expect(tf.stylusHandwritingEnabled, isFalse);
      expect(tf.enableIMEPersonalizedLearning, isFalse);
      expect(tf.undoController, same(undo));
      expect(tf.spellCheckConfiguration, same(spell));
      expect(tf.magnifierConfiguration, same(magnifier));
      expect(tf.hintLocales, hintLocales);
      expect(tf.groupId, same(key));
      expect(tf.statesController, same(states));

      // The input formatter really applies through the bloc round trip.
      await tester.enterText(find.byType(TextField), '12ab34');
      expect(field.value, '1234');
    });

    testWidgets('multiline options: maxLines / minLines / expands', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MkTextField(
            fieldBloc: MkFieldBloc<String>(),
            maxLines: 5,
            minLines: 2,
          ),
        ),
      );
      expect(_textField(tester).maxLines, 5);
      expect(_textField(tester).minLines, 2);

      await tester.pumpWidget(
        _host(
          MkTextField(
            fieldBloc: MkFieldBloc<String>(),
            maxLines: null,
            expands: true,
          ),
        ),
      );
      expect(_textField(tester).expands, isTrue);
      expect(_textField(tester).maxLines, isNull);
    });

    testWidgets('sensible Flutter defaults are kept', (tester) async {
      await tester.pumpWidget(
        _host(MkTextField(fieldBloc: MkFieldBloc<String>())),
      );
      final tf = _textField(tester);
      expect(tf.cursorWidth, 2.0);
      expect(tf.scrollPadding, const EdgeInsets.all(20.0));
      expect(tf.obscuringCharacter, '•');
      expect(tf.enableSuggestions, isTrue);
      expect(tf.clipBehavior, Clip.hardEdge);
      expect(tf.canRequestFocus, isTrue);
      expect(tf.enableIMEPersonalizedLearning, isTrue);
      expect(tf.dragStartBehavior, DragStartBehavior.start);
      expect(tf.groupId, EditableText);
      expect(tf.contextMenuBuilder, isNotNull);
    });

    testWidgets('callbacks fire: onTap, onChanged (after the bloc), '
        'onSubmitted', (tester) async {
      final field = MkFieldBloc<String>();
      var taps = 0;
      String? seenByOnChanged;
      String? submitted;

      await tester.pumpWidget(
        _host(
          MkTextField(
            fieldBloc: field,
            onTap: () => taps++,
            onChanged: (v) => seenByOnChanged = field.value,
            onSubmitted: (v) => submitted = v,
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'hi');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(taps, greaterThan(0));
      expect(seenByOnChanged, 'hi');
      expect(submitted, 'hi');
    });

    testWidgets('custom contextMenuBuilder is used', (tester) async {
      Widget builder(BuildContext c, EditableTextState s) =>
          const SizedBox.shrink();
      await tester.pumpWidget(
        _host(
          MkTextField(
            fieldBloc: MkFieldBloc<String>(),
            contextMenuBuilder: builder,
          ),
        ),
      );
      expect(_textField(tester).contextMenuBuilder, same(builder));
    });

    testWidgets('enabled combines the parameter with the bloc state', (
      tester,
    ) async {
      final field = MkFieldBloc<String>();
      await tester.pumpWidget(_host(MkTextField(fieldBloc: field)));
      expect(_textField(tester).enabled, isTrue);

      field.setEnabled(false);
      await tester.pumpAndSettle();
      expect(_textField(tester).enabled, isFalse);

      field.setEnabled(true);
      await tester.pumpWidget(
        _host(MkTextField(fieldBloc: field, enabled: false)),
      );
      await tester.pumpAndSettle();
      expect(_textField(tester).enabled, isFalse);
    });

    testWidgets('a supplied focusNode is used, marks touched on blur and '
        'is not disposed', (tester) async {
      final field = MkFieldBloc<String>();
      final node = FocusNode();
      final other = FocusNode();
      addTearDown(node.dispose);
      addTearDown(other.dispose);

      await tester.pumpWidget(
        _host(
          Column(
            children: [
              MkTextField(fieldBloc: field, focusNode: node),
              Focus(focusNode: other, child: const SizedBox()),
            ],
          ),
        ),
      );
      expect(_textField(tester).focusNode, same(node));

      node.requestFocus();
      await tester.pump();
      expect(field.isTouched, isFalse);
      other.requestFocus();
      await tester.pump();
      expect(field.isTouched, isTrue);

      // Removing the widget must not dispose a node it does not own.
      await tester.pumpWidget(_host(const SizedBox()));
      expect(() => node.addListener(() {}), returnsNormally);
    });

    testWidgets('swapping the focusNode moves the blur listener', (
      tester,
    ) async {
      final field = MkFieldBloc<String>();
      final a = FocusNode();
      final b = FocusNode();
      final other = FocusNode();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      addTearDown(other.dispose);

      Widget build(FocusNode? node) => _host(
        Column(
          children: [
            MkTextField(fieldBloc: field, focusNode: node),
            Focus(focusNode: other, child: const SizedBox()),
          ],
        ),
      );

      await tester.pumpWidget(build(a));
      await tester.pumpWidget(build(b));
      expect(_textField(tester).focusNode, same(b));

      b.requestFocus();
      await tester.pump();
      other.requestFocus();
      await tester.pump();
      expect(field.isTouched, isTrue);

      // Back to the internally managed node.
      await tester.pumpWidget(build(null));
      expect(_textField(tester).focusNode, isNot(same(b)));
    });
  });

  group('MkEmailField', () {
    testWidgets('keeps its defaults and lets them be overridden', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(MkEmailField(fieldBloc: MkFieldBloc<String>())),
      );
      var tf = _textField(tester);
      expect(tf.keyboardType, TextInputType.emailAddress);
      expect(tf.textInputAction, TextInputAction.next);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);

      await tester.pumpWidget(
        _host(
          MkEmailField(
            fieldBloc: MkFieldBloc<String>(),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            inputFormatters: [FilteringTextInputFormatter.deny(' ')],
            cursorColor: Colors.green,
            textAlign: TextAlign.end,
            maxLength: 40,
            enableInteractiveSelection: false,
            mouseCursor: SystemMouseCursors.click,
          ),
        ),
      );
      tf = _textField(tester);
      expect(tf.keyboardType, TextInputType.text);
      expect(tf.textInputAction, TextInputAction.done);
      expect(tf.autocorrect, isFalse);
      expect(tf.autofillHints, const [AutofillHints.email]);
      expect(tf.inputFormatters, hasLength(1));
      expect(tf.cursorColor, Colors.green);
      expect(tf.textAlign, TextAlign.end);
      expect(tf.maxLength, 40);
      expect(tf.enableInteractiveSelection, isFalse);
      expect(tf.mouseCursor, SystemMouseCursors.click);
    });

    testWidgets('a custom decoration keeps its own label and icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MkEmailField(
            fieldBloc: MkFieldBloc<String>(),
            decoration: const InputDecoration(
              labelText: 'Work email',
              prefixIcon: Icon(Icons.work),
            ),
          ),
        ),
      );
      expect(find.text('Work email'), findsOneWidget);
      expect(find.byIcon(Icons.work), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsNothing);
    });
  });

  group('MkPasswordField', () {
    testWidgets('keeps its defaults, forwards parameters and toggles', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MkPasswordField(
            fieldBloc: MkFieldBloc<String>(),
            obscuringCharacter: '#',
            cursorColor: Colors.purple,
            autofillHints: const [AutofillHints.password],
            enableSuggestions: false,
            maxLength: 64,
          ),
        ),
      );
      var tf = _textField(tester);
      expect(tf.keyboardType, TextInputType.visiblePassword);
      expect(tf.textInputAction, TextInputAction.done);
      expect(tf.obscureText, isTrue);
      expect(tf.obscuringCharacter, '#');
      expect(tf.cursorColor, Colors.purple);
      expect(tf.autofillHints, const [AutofillHints.password]);
      expect(tf.enableSuggestions, isFalse);
      expect(tf.maxLength, 64);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(_textField(tester).obscureText, isFalse);
    });

    testWidgets('initiallyObscured: false starts visible', (tester) async {
      await tester.pumpWidget(
        _host(
          MkPasswordField(
            fieldBloc: MkFieldBloc<String>(),
            initiallyObscured: false,
          ),
        ),
      );
      expect(_textField(tester).obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });

  group('MkCheckboxField forwards CheckboxListTile parameters', () {
    testWidgets('every parameter reaches the tile', (tester) async {
      final field = MkFieldBloc<bool>(initialValue: true);
      final node = FocusNode();
      addTearDown(node.dispose);
      const shape = RoundedRectangleBorder();
      const checkboxShape = CircleBorder();
      const side = BorderSide(color: Colors.red);
      final fill = WidgetStateProperty.all<Color?>(Colors.blue);
      final overlay = WidgetStateProperty.all<Color?>(Colors.green);
      void onFocusChange(bool _) {}

      await tester.pumpWidget(
        _host(
          MkCheckboxField(
            fieldBloc: field,
            title: const Text('T'),
            subtitle: const Text('S'),
            secondary: const Icon(Icons.info),
            mouseCursor: SystemMouseCursors.help,
            activeColor: Colors.teal,
            fillColor: fill,
            checkColor: Colors.white,
            hoverColor: Colors.amber,
            overlayColor: overlay,
            splashRadius: 11,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            focusNode: node,
            shape: shape,
            side: side,
            isError: true,
            tileColor: Colors.grey,
            isThreeLine: true,
            dense: true,
            selected: true,
            controlAffinity: ListTileControlAffinity.trailing,
            contentPadding: const EdgeInsets.all(3),
            checkboxShape: checkboxShape,
            selectedTileColor: Colors.pink,
            onFocusChange: onFocusChange,
            enableFeedback: false,
            horizontalTitleGap: 9,
            minVerticalPadding: 4,
            minLeadingWidth: 30,
            minTileHeight: 70,
            checkboxSemanticLabel: 'semantic',
            checkboxScaleFactor: 1.5,
            titleAlignment: ListTileTitleAlignment.top,
          ),
        ),
      );

      final tile = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(tile.value, isTrue);
      expect(tile.mouseCursor, SystemMouseCursors.help);
      expect(tile.activeColor, Colors.teal);
      expect(tile.fillColor, same(fill));
      expect(tile.checkColor, Colors.white);
      expect(tile.hoverColor, Colors.amber);
      expect(tile.overlayColor, same(overlay));
      expect(tile.splashRadius, 11);
      expect(tile.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
      expect(tile.visualDensity, VisualDensity.compact);
      expect(tile.focusNode, same(node));
      expect(tile.shape, shape);
      expect(tile.side, side);
      expect(tile.isError, isTrue);
      expect(tile.tileColor, Colors.grey);
      expect(tile.isThreeLine, isTrue);
      expect(tile.dense, isTrue);
      expect(tile.selected, isTrue);
      expect(tile.controlAffinity, ListTileControlAffinity.trailing);
      expect(tile.contentPadding, const EdgeInsets.all(3));
      expect(tile.checkboxShape, checkboxShape);
      expect(tile.selectedTileColor, Colors.pink);
      expect(tile.onFocusChange, same(onFocusChange));
      expect(tile.enableFeedback, isFalse);
      expect(tile.horizontalTitleGap, 9);
      expect(tile.minVerticalPadding, 4);
      expect(tile.minLeadingWidth, 30);
      expect(tile.minTileHeight, 70);
      expect(tile.checkboxSemanticLabel, 'semantic');
      expect(tile.checkboxScaleFactor, 1.5);
      expect(tile.titleAlignment, ListTileTitleAlignment.top);
      expect(find.text('S'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('defaults: leading affinity, error state follows the bloc', (
      tester,
    ) async {
      final field = MkFieldBloc<bool>(
        initialValue: false,
        validators: [MkValidators.required('Must accept')],
      );
      await tester.pumpWidget(
        _host(MkCheckboxField(fieldBloc: field, title: const Text('T'))),
      );
      var tile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(tile.controlAffinity, ListTileControlAffinity.leading);
      expect(tile.isError, isFalse);

      field.touch();
      await tester.pumpAndSettle();
      tile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(tile.isError, isTrue);
      expect(find.text('Must accept'), findsOneWidget);
    });

    testWidgets('errorStyle and errorPadding customize the error text', (
      tester,
    ) async {
      final field = MkFieldBloc<bool>(
        initialValue: false,
        validators: [MkValidators.required('Must accept')],
      );
      await tester.pumpWidget(
        _host(
          MkCheckboxField(
            fieldBloc: field,
            title: const Text('T'),
            errorStyle: const TextStyle(fontSize: 31),
            errorPadding: const EdgeInsets.all(9),
          ),
        ),
      );
      field.touch();
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('Must accept'));
      expect(text.style?.fontSize, 31);
      final padding = tester.widget<Padding>(
        find
            .ancestor(
              of: find.text('Must accept'),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(padding.padding, const EdgeInsets.all(9));
    });

    testWidgets('onChanged fires after the bloc was updated', (tester) async {
      final field = MkFieldBloc<bool>(initialValue: false);
      bool? seenInBloc;
      bool? received;
      await tester.pumpWidget(
        _host(
          MkCheckboxField(
            fieldBloc: field,
            title: const Text('T'),
            onChanged: (v) {
              received = v;
              seenInBloc = field.value;
            },
          ),
        ),
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      expect(received, isTrue);
      expect(seenInBloc, isTrue);
    });

    testWidgets('enabled: false or a disabled bloc blocks input', (
      tester,
    ) async {
      final field = MkFieldBloc<bool>(initialValue: false);
      await tester.pumpWidget(
        _host(
          MkCheckboxField(
            fieldBloc: field,
            title: const Text('T'),
            enabled: false,
          ),
        ),
      );
      var tile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(tile.onChanged, isNull);
      expect(tile.enabled, isFalse);

      await tester.pumpWidget(
        _host(MkCheckboxField(fieldBloc: field, title: const Text('T'))),
      );
      field.setEnabled(false);
      await tester.pumpAndSettle();
      tile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(tile.onChanged, isNull);
    });

    testWidgets('tristate shows a null value as indeterminate', (tester) async {
      final field = MkFieldBloc<bool>();
      await tester.pumpWidget(
        _host(
          MkCheckboxField(
            fieldBloc: field,
            title: const Text('T'),
            tristate: true,
          ),
        ),
      );
      var tile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(tile.tristate, isTrue);
      expect(tile.value, isNull);

      await tester.pumpWidget(
        _host(MkCheckboxField(fieldBloc: field, title: const Text('T'))),
      );
      tile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(tile.value, isFalse);
    });
  });

  group('MkDropdownField forwards DropdownButton parameters', () {
    testWidgets('every parameter reaches the dropdown', (tester) async {
      final field = MkFieldBloc<String>(initialValue: 'a');
      final node = FocusNode();
      addTearDown(node.dispose);
      const icon = Icon(Icons.arrow_downward);
      const hint = Text('hint');
      void onTap() {}
      List<Widget> selectedBuilder(BuildContext c) => [
        const Text('A!'),
        const Text('B!'),
      ];

      await tester.pumpWidget(
        _host(
          MkDropdownField<String>(
            fieldBloc: field,
            items: const [
              DropdownMenuItem(value: 'a', child: Text('A')),
              DropdownMenuItem(value: 'b', child: Text('B')),
            ],
            selectedItemBuilder: selectedBuilder,
            hint: hint,
            onTap: onTap,
            elevation: 3,
            style: const TextStyle(fontSize: 19),
            icon: icon,
            iconDisabledColor: Colors.grey,
            iconEnabledColor: Colors.red,
            iconSize: 30,
            isDense: false,
            isExpanded: true,
            itemHeight: 60,
            focusColor: Colors.yellow,
            focusNode: node,
            dropdownColor: Colors.black,
            menuMaxHeight: 200,
            enableFeedback: false,
            alignment: AlignmentDirectional.centerEnd,
            borderRadius: BorderRadius.circular(9),
            padding: const EdgeInsets.all(2),
            barrierDismissible: false,
            mouseCursor: SystemMouseCursors.grab,
            dropdownMenuItemMouseCursor: SystemMouseCursors.copy,
          ),
        ),
      );

      final dd = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dd.selectedItemBuilder, same(selectedBuilder));
      expect(dd.hint, same(hint));
      expect(dd.onTap, same(onTap));
      expect(dd.elevation, 3);
      expect(dd.style?.fontSize, 19);
      expect(dd.icon, same(icon));
      expect(dd.iconDisabledColor, Colors.grey);
      expect(dd.iconEnabledColor, Colors.red);
      expect(dd.iconSize, 30);
      expect(dd.isDense, isFalse);
      expect(dd.isExpanded, isTrue);
      expect(dd.itemHeight, 60);
      expect(dd.focusColor, Colors.yellow);
      expect(dd.focusNode, same(node));
      expect(dd.dropdownColor, Colors.black);
      expect(dd.menuMaxHeight, 200);
      expect(dd.enableFeedback, isFalse);
      expect(dd.alignment, AlignmentDirectional.centerEnd);
      expect(dd.borderRadius, BorderRadius.circular(9));
      expect(dd.padding, const EdgeInsets.all(2));
      expect(dd.barrierDismissible, isFalse);
      expect(dd.mouseCursor, SystemMouseCursors.grab);
      expect(dd.dropdownMenuItemMouseCursor, SystemMouseCursors.copy);
    });

    testWidgets('onChanged fires after the bloc; enabled: false blocks it', (
      tester,
    ) async {
      final field = MkFieldBloc<String>(initialValue: 'a');
      String? seenInBloc;
      Widget build({bool? enabled}) => _host(
        MkDropdownField<String>(
          fieldBloc: field,
          enabled: enabled,
          items: const [
            DropdownMenuItem(value: 'a', child: Text('A')),
            DropdownMenuItem(value: 'b', child: Text('B')),
          ],
          onChanged: (v) => seenInBloc = field.value,
        ),
      );

      await tester.pumpWidget(build());
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B').last);
      await tester.pumpAndSettle();
      expect(seenInBloc, 'b');

      await tester.pumpWidget(build(enabled: false));
      final dd = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dd.onChanged, isNull);
    });
  });

  group('MkRadioGroup forwards Radio / RadioListTile parameters', () {
    const options = [
      MkRadioOption<String>(
        value: 'a',
        label: Text('Option A'),
        subtitle: Text('Sub A'),
        secondary: Icon(Icons.star),
      ),
      MkRadioOption<String>(
        value: 'b',
        label: Text('Option B'),
        subtitle: Text('Sub B'),
        enabled: false,
      ),
    ];

    testWidgets('vertical layout: parameters reach every RadioListTile', (
      tester,
    ) async {
      final fill = WidgetStateProperty.all<Color?>(Colors.blue);
      final overlay = WidgetStateProperty.all<Color?>(Colors.green);
      final background = WidgetStateProperty.all<Color?>(Colors.pink);
      final inner = WidgetStateProperty.all<double?>(3);
      const shape = RoundedRectangleBorder();
      const side = BorderSide(color: Colors.red);
      void onFocusChange(bool _) {}

      await tester.pumpWidget(
        _host(
          MkRadioGroup<String>(
            fieldBloc: MkFieldBloc<String>(initialValue: 'a'),
            options: options,
            mouseCursor: SystemMouseCursors.help,
            toggleable: true,
            activeColor: Colors.teal,
            fillColor: fill,
            hoverColor: Colors.amber,
            overlayColor: overlay,
            splashRadius: 11,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            autofocus: true,
            radioBackgroundColor: background,
            radioSide: side,
            radioInnerRadius: inner,
            contentPadding: const EdgeInsets.all(3),
            dense: false,
            isThreeLine: true,
            controlAffinity: ListTileControlAffinity.trailing,
            shape: shape,
            tileColor: Colors.grey,
            selectedTileColor: Colors.pink,
            highlightSelected: true,
            onFocusChange: onFocusChange,
            enableFeedback: false,
            horizontalTitleGap: 9,
            minVerticalPadding: 4,
            minLeadingWidth: 30,
            minTileHeight: 70,
            radioScaleFactor: 1.4,
            titleAlignment: ListTileTitleAlignment.top,
          ),
        ),
      );

      final tiles = tester
          .widgetList<RadioListTile<String>>(find.byType(RadioListTile<String>))
          .toList();
      expect(tiles, hasLength(2));
      final a = tiles[0];
      final b = tiles[1];
      for (final t in tiles) {
        expect(t.mouseCursor, SystemMouseCursors.help);
        expect(t.toggleable, isTrue);
        expect(t.activeColor, Colors.teal);
        expect(t.fillColor, same(fill));
        expect(t.hoverColor, Colors.amber);
        expect(t.overlayColor, same(overlay));
        expect(t.splashRadius, 11);
        expect(t.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
        expect(t.visualDensity, VisualDensity.compact);
        expect(t.radioBackgroundColor, same(background));
        expect(t.radioSide, side);
        expect(t.radioInnerRadius, same(inner));
        expect(t.contentPadding, const EdgeInsets.all(3));
        expect(t.dense, isFalse);
        expect(t.isThreeLine, isTrue);
        expect(t.controlAffinity, ListTileControlAffinity.trailing);
        expect(t.shape, shape);
        expect(t.tileColor, Colors.grey);
        expect(t.selectedTileColor, Colors.pink);
        expect(t.onFocusChange, same(onFocusChange));
        expect(t.enableFeedback, isFalse);
        expect(t.horizontalTitleGap, 9);
        expect(t.minVerticalPadding, 4);
        expect(t.minLeadingWidth, 30);
        expect(t.minTileHeight, 70);
        expect(t.radioScaleFactor, 1.4);
        expect(t.titleAlignment, ListTileTitleAlignment.top);
      }
      // Per option state.
      expect(a.selected, isTrue);
      expect(b.selected, isFalse);
      expect(a.autofocus, isTrue);
      expect(b.autofocus, isFalse);
      expect(a.enabled, isTrue);
      expect(b.enabled, isFalse); // option.enabled is honoured
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('horizontal and wrap layouts: parameters reach every Radio', (
      tester,
    ) async {
      final fill = WidgetStateProperty.all<Color?>(Colors.blue);
      final overlay = WidgetStateProperty.all<Color?>(Colors.green);
      final background = WidgetStateProperty.all<Color?>(Colors.pink);
      final inner = WidgetStateProperty.all<double?>(3);
      const side = BorderSide(color: Colors.red);

      for (final layout in [MkRadioLayout.horizontal, MkRadioLayout.wrap]) {
        await tester.pumpWidget(
          _host(
            MkRadioGroup<String>(
              fieldBloc: MkFieldBloc<String>(initialValue: 'a'),
              options: options,
              layout: layout,
              mouseCursor: SystemMouseCursors.help,
              toggleable: true,
              activeColor: Colors.teal,
              fillColor: fill,
              focusColor: Colors.yellow,
              hoverColor: Colors.amber,
              overlayColor: overlay,
              splashRadius: 11,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              autofocus: true,
              radioBackgroundColor: background,
              radioSide: side,
              radioInnerRadius: inner,
            ),
          ),
        );

        final radios = tester
            .widgetList<Radio<String>>(find.byType(Radio<String>))
            .toList();
        expect(radios, hasLength(2), reason: '$layout');
        for (final r in radios) {
          expect(r.mouseCursor, SystemMouseCursors.help);
          expect(r.toggleable, isTrue);
          expect(r.activeColor, Colors.teal);
          expect(r.fillColor, same(fill));
          expect(r.focusColor, Colors.yellow);
          expect(r.hoverColor, Colors.amber);
          expect(r.overlayColor, same(overlay));
          expect(r.splashRadius, 11);
          expect(r.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
          expect(r.visualDensity, VisualDensity.compact);
          expect(r.backgroundColor, same(background));
          expect(r.side, side);
          expect(r.innerRadius, same(inner));
        }
        expect(radios[0].autofocus, isTrue);
        expect(radios[1].autofocus, isFalse);
        expect(radios[0].enabled, isTrue);
        expect(radios[1].enabled, isFalse);
      }
    });

    testWidgets('isThreeLine is only applied to options with a subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MkRadioGroup<String>(
            fieldBloc: MkFieldBloc<String>(initialValue: 'a'),
            isThreeLine: true,
            options: const [
              MkRadioOption(
                value: 'a',
                label: Text('A'),
                subtitle: Text('sub'),
              ),
              MkRadioOption(value: 'b', label: Text('B')),
            ],
          ),
        ),
      );

      final tiles = tester
          .widgetList<RadioListTile<String>>(find.byType(RadioListTile<String>))
          .toList();
      expect(tiles[0].isThreeLine, isTrue);
      expect(tiles[1].isThreeLine, isNull);
    });

    testWidgets('defaults are unchanged: dense tiles, no highlight', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MkRadioGroup<String>(
            fieldBloc: MkFieldBloc<String>(initialValue: 'a'),
            options: options,
          ),
        ),
      );
      final tile = tester
          .widgetList<RadioListTile<String>>(find.byType(RadioListTile<String>))
          .first;
      expect(tile.dense, isTrue);
      expect(tile.selected, isFalse);
      expect(tile.toggleable, isFalse);
    });

    testWidgets('onChanged fires after the bloc; a disabled option or group '
        'cannot be selected', (tester) async {
      final field = MkFieldBloc<String>();
      final changes = <String?>[];
      Widget build({bool? enabled}) => _host(
        MkRadioGroup<String>(
          fieldBloc: field,
          enabled: enabled,
          options: const [
            MkRadioOption(value: 'a', label: Text('Option A')),
            MkRadioOption(value: 'b', label: Text('Option B')),
          ],
          onChanged: (v) {
            expect(field.value, v);
            changes.add(v);
          },
        ),
      );

      await tester.pumpWidget(build());
      await tester.tap(find.text('Option B'));
      await tester.pump();
      expect(changes, ['b']);

      await tester.pumpWidget(build(enabled: false));
      await tester.tap(find.text('Option A'));
      await tester.pump();
      expect(changes, ['b']);
      expect(field.value, 'b');
    });

    testWidgets('errorStyle customizes the error text', (tester) async {
      final field = MkFieldBloc<String>(
        validators: [MkValidators.required('Pick one')],
      );
      await tester.pumpWidget(
        _host(
          MkRadioGroup<String>(
            fieldBloc: field,
            options: const [MkRadioOption(value: 'a', label: Text('A'))],
            errorStyle: const TextStyle(fontSize: 33),
          ),
        ),
      );
      field.touch();
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text('Pick one')).style?.fontSize, 33);
    });
  });

  group('MkMultiSelectSearchDropdown customization', () {
    Widget build(
      MkFieldBloc<List<String>> field, {
      bool? enabled,
      MkMultiSelectModalType modalType = MkMultiSelectModalType.bottomSheet,
      ValueChanged<List<String>>? onChanged,
      bool showSelectAll = true,
      int maxChips = 4,
      String Function(int)? moreLabel,
      BoxConstraints? dialogConstraints,
      bool? showDragHandle,
    }) => _host(
      MkMultiSelectSearchDropdown<String>(
        fieldBloc: field,
        items: const ['Apple', 'Banana', 'Cherry'],
        itemToString: (s) => s,
        enabled: enabled,
        modalType: modalType,
        onChanged: onChanged,
        showSelectAll: showSelectAll,
        maxChipsDisplayed: maxChips,
        moreLabelBuilder: moreLabel,
        doneLabel: 'Listo',
        selectAllLabel: 'Todos',
        clearAllLabel: 'Ninguno',
        hintText: 'Elegir',
        hintStyle: const TextStyle(fontSize: 21),
        icon: const Icon(Icons.expand_more),
        chipSpacing: 13,
        chipRunSpacing: 7,
        chipLabelStyle: const TextStyle(fontSize: 17),
        chipBackgroundColor: Colors.amber,
        chipVisualDensity: VisualDensity.compact,
        chipDeleteIcon: const Icon(Icons.close, key: Key('del')),
        chipDeleteIconColor: Colors.red,
        borderRadius: BorderRadius.circular(6),
        mouseCursor: SystemMouseCursors.help,
        splashColor: Colors.cyan,
        hoverColor: Colors.lime,
        enableFeedback: false,
        dialogConstraints:
            dialogConstraints ??
            const BoxConstraints(maxWidth: 450, maxHeight: 600),
        sheetShowDragHandle: showDragHandle,
      ),
    );

    testWidgets('texts, icon and hint style are configurable', (tester) async {
      final field = MkFieldBloc<List<String>>(initialValue: const []);
      await tester.pumpWidget(build(field));

      expect(find.text('Elegir'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Elegir')).style?.fontSize, 21);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.text('Listo'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Ninguno'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('InkWell parameters are forwarded', (tester) async {
      await tester.pumpWidget(
        build(MkFieldBloc<List<String>>(initialValue: const [])),
      );
      final ink = tester.widget<InkWell>(find.byType(InkWell).first);
      expect(ink.borderRadius, BorderRadius.circular(6));
      expect(ink.mouseCursor, SystemMouseCursors.help);
      expect(ink.splashColor, Colors.cyan);
      expect(ink.hoverColor, Colors.lime);
      expect(ink.enableFeedback, isFalse);
    });

    testWidgets('chip styling, spacing and the more-label', (tester) async {
      final field = MkFieldBloc<List<String>>(
        initialValue: const ['Apple', 'Banana', 'Cherry'],
      );
      await tester.pumpWidget(
        build(field, maxChips: 2, moreLabel: (n) => '+$n mas'),
      );

      final chips = tester
          .widgetList<InputChip>(find.byType(InputChip))
          .toList();
      expect(chips, hasLength(2));
      expect(chips.first.labelStyle?.fontSize, 17);
      expect(chips.first.backgroundColor, Colors.amber);
      expect(chips.first.visualDensity, VisualDensity.compact);
      expect(chips.first.deleteIconColor, Colors.red);
      expect(find.byKey(const Key('del')), findsNWidgets(2));
      expect(find.text('+1 mas'), findsOneWidget);

      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.spacing, 13);
      expect(wrap.runSpacing, 7);
    });

    testWidgets('onChanged fires after the bloc for chip removal and picks', (
      tester,
    ) async {
      final field = MkFieldBloc<List<String>>(initialValue: const ['Apple']);
      final seen = <List<String>>[];
      await tester.pumpWidget(
        build(
          field,
          onChanged: (v) {
            expect(field.value, v);
            seen.add(List.of(v));
          },
        ),
      );

      await tester.tap(find.byKey(const Key('del')));
      await tester.pumpAndSettle();
      expect(seen, [<String>[]]);

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Banana'));
      await tester.pump();
      expect(seen.last, ['Banana']);
    });

    testWidgets('showSelectAll: false hides the bulk buttons', (tester) async {
      await tester.pumpWidget(
        build(
          MkFieldBloc<List<String>>(initialValue: const []),
          showSelectAll: false,
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.text('Todos'), findsNothing);
      expect(find.text('Ninguno'), findsNothing);
      expect(find.text('Listo'), findsOneWidget);
    });

    testWidgets('enabled: false or a disabled bloc does not open the picker', (
      tester,
    ) async {
      final field = MkFieldBloc<List<String>>(initialValue: const []);
      await tester.pumpWidget(build(field, enabled: false));
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.text('Listo'), findsNothing);

      await tester.pumpWidget(build(field));
      field.setEnabled(false);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.text('Listo'), findsNothing);
    });

    testWidgets('dialog mode honours the dialog constraints', (tester) async {
      await tester.pumpWidget(
        build(
          MkFieldBloc<List<String>>(initialValue: const []),
          modalType: MkMultiSelectModalType.dialog,
          dialogConstraints: const BoxConstraints(
            maxWidth: 300,
            maxHeight: 400,
          ),
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      final size = tester.getSize(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(MkMultiSelectModalContent<String>),
        ),
      );
      expect(size.width, lessThanOrEqualTo(300));
      expect(size.height, lessThanOrEqualTo(400));
    });

    testWidgets('sheet parameters are forwarded to the bottom sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        build(
          MkFieldBloc<List<String>>(initialValue: const []),
          showDragHandle: true,
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(sheet.showDragHandle, isTrue);
    });
  });
}

void _noContent(KeyboardInsertedContent _) {}
