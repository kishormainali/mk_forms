import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('mkHumanizeFieldName', () {
    test('single lowercase word', () {
      expect(mkHumanizeFieldName('email'), 'Email');
    });

    test('camelCase', () {
      expect(mkHumanizeFieldName('confirmPassword'), 'Confirm password');
    });

    test('snake_case', () {
      expect(mkHumanizeFieldName('agree_terms'), 'Agree terms');
    });

    test('kebab-case', () {
      expect(mkHumanizeFieldName('shipping-address'), 'Shipping address');
    });

    test('mixed camelCase and underscores', () {
      expect(
        mkHumanizeFieldName('shipping_streetName'),
        'Shipping street name',
      );
    });

    test('already short/single letter run', () {
      expect(mkHumanizeFieldName('zip'), 'Zip');
    });

    test(
      'consecutive uppercase acronym is kept as one word (documented limitation)',
      () {
        expect(mkHumanizeFieldName('userID'), 'User id');
      },
    );

    test('empty string returns empty string', () {
      expect(mkHumanizeFieldName(''), '');
    });

    test('collapses repeated separators', () {
      expect(mkHumanizeFieldName('shipping__address'), 'Shipping address');
    });
  });
}
