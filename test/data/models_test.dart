import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarea_5/data/models/post.dart';
import 'package:tarea_5/data/models/user.dart';

import 'fixtures.dart';

void main() {
  group('User', () {
    test('fromJson reads nested company.name and address.city', () {
      final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);

      expect(user.id, 1);
      expect(user.name, 'Leanne Graham');
      expect(user.email, 'Sincere@april.biz');
      expect(user.companyName, 'Romaguera-Crona');
      expect(user.city, 'Gwenborough');
      expect(user.phone, '1-770-736-8031 x56442');
    });

    test('toJson round-trips through fromJson without loss', () {
      final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      final copy = User.fromJson(
        jsonDecode(jsonEncode(user.toJson())) as Map<String, dynamic>,
      );

      expect(copy, user);
    });

    test('missing optional fields default to empty strings', () {
      final user = User.fromJson({
        'id': 2,
        'name': 'Ervin Howell',
        'email': 'Shanna@melissa.tv',
      });

      expect(user.companyName, '');
      expect(user.city, '');
    });
  });

  test('Post.fromJson reads all fields', () {
    final post = Post.fromJson(jsonDecode(postJson) as Map<String, dynamic>);

    expect(post.id, 1);
    expect(post.userId, 1);
    expect(post.title, startsWith('sunt aut facere'));
    expect(post.body, contains('\n'));
  });
}
