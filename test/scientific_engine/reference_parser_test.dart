import 'package:flutter_test/flutter_test.dart';
import 'package:reagentkit/scientific_engine/reference_parser.dart';

void main() {
  group('ReferenceParser parsing and formatting tests', () {
    test('Parses empty string gracefully', () {
      final ref = ReferenceParser.parse('');
      expect(ref.raw, '');
      expect(ref.authors, '');
      expect(ref.journalOrBook, '');
      expect(ref.year, '');
      expect(ref.publisherOrLocation, '');
      expect(ref.details, '');
      
      expect(ref.toAPAFormat(), '(n.d.).');
      expect(ref.toShortCitation(), 'Anon. (n.d.)');
    });

    test('Parses standard reference with double-dot separator', () {
      // E.g. "Auterhoff, H., Braun, D... Arch.Pharm. (1973) 306"
      final raw = 'Auterhoff, H., Braun, D... Arch.Pharm. (1973) 306';
      final ref = ReferenceParser.parse(raw);

      expect(ref.raw, raw);
      expect(ref.authors, 'Auterhoff, H., Braun, D');
      expect(ref.year, '1973');
      expect(ref.details, ''); // Details are empty because there's no p. prefix
      expect(ref.journalOrBook, isNotEmpty);

      // APA format should compile cleanly
      final apa = ref.toAPAFormat();
      expect(apa, contains('Auterhoff, H., Braun, D'));
      expect(apa, contains('(1973)'));

      // Short citation should format as et al. since there are multiple authors
      final short = ref.toShortCitation();
      expect(short, equals('Auterhoff et al. (1973)'));
    });

    test('Parses single author reference without double-dots', () {
      final raw = 'Kovar, K.-A. Arch.Pharm. (1989) 322';
      final ref = ReferenceParser.parse(raw);

      expect(ref.authors, 'Kovar, K.-A');
      expect(ref.year, '1989');
      
      final short = ref.toShortCitation();
      expect(short, equals('Kovar (1989)'));
    });

    test('Parses book publisher format', () {
      final raw = 'Clarke, E.G.C. Isolation and Identification of Drugs. London: The Pharmaceutical Press (1975)';
      final ref = ReferenceParser.parse(raw);

      expect(ref.authors, 'Clarke, E.G.C');
      expect(ref.year, '1975');
      expect(ref.toAPAFormat(), contains('Clarke, E.G.C'));
      expect(ref.toAPAFormat(), contains('(1975)'));
    });
  });
}
