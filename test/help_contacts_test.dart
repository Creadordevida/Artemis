import 'package:flutter_test/flutter_test.dart';
import 'package:artemis/help_contacts.dart';

void main() {
  test('El directorio contiene teléfonos sin conexión y fuentes', () {
    expect(helpContacts, isNotEmpty);
    expect(helpContacts.where((c) => c.phone == '112').length, 1);
    expect(helpContacts.any((c) => c.phone == '116111'), isTrue);
    for (final contact in helpContacts) {
      expect(RegExp(r'^\d+).hasMatch(contact.phone), isTrue);
      expect(contact.source.startsWith('https://'), isTrue);
      expect(DateTime.tryParse(contact.verifiedOn), isNotNull);
    }
  });
}
).hasMatch(contact.phone), isTrue);
      expect(contact.source.startsWith('https://'), isTrue);
      expect(DateTime.tryParse(contact.verifiedOn), isNotNull);
    }
  });
}
