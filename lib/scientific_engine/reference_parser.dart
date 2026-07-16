class AcademicReference {
  final String raw;
  final String authors;
  final String journalOrBook;
  final String year;
  final String publisherOrLocation;
  final String details;

  const AcademicReference({
    required this.raw,
    required this.authors,
    required this.journalOrBook,
    required this.year,
    required this.publisherOrLocation,
    required this.details,
  });

  /// Formats the reference according to APA-like academic standards
  String toAPAFormat() {
    final buffer = StringBuffer();

    if (authors.isNotEmpty) {
      buffer.write('$authors ');
    }

    if (year.isNotEmpty) {
      buffer.write('($year).');
    } else {
      buffer.write('(n.d.).');
    }

    if (journalOrBook.isNotEmpty) {
      buffer.write(' $journalOrBook');
    }

    if (publisherOrLocation.isNotEmpty) {
      if (journalOrBook.isNotEmpty && !journalOrBook.endsWith('.')) {
        buffer.write('. ');
      } else {
        buffer.write(' ');
      }
      buffer.write(publisherOrLocation);
    }

    if (details.isNotEmpty) {
      if (buffer.isNotEmpty && !buffer.toString().endsWith('.')) {
        buffer.write(', ');
      } else {
        buffer.write(' ');
      }
      buffer.write(details);
    }

    var result = buffer.toString().trim();
    if (!result.endsWith('.')) {
      result = '$result.';
    }

    return result;
  }

  /// Formats a short citation tag, e.g., "Auterhoff et al. (1973)"
  String toShortCitation() {
    if (authors.isEmpty) return 'Anon. (${year.isNotEmpty ? year : "n.d."})';

    // Extract first author last name
    // Authors usually format like "Auterhoff, H., Braun, D." or "Kovar, K.-A."
    final parts = authors.split(',');
    String primaryAuthor = parts[0].trim();

    // Check if there are other authors
    final hasEtAl = parts.length > 2 ||
        authors.toLowerCase().contains('et al') ||
        authors.toLowerCase().contains('et. al') ||
        authors.contains('&') ||
        authors.contains(' and ');

    final formattedYear = year.isNotEmpty ? year : 'n.d.';

    if (hasEtAl) {
      return '$primaryAuthor et al. ($formattedYear)';
    } else {
      return '$primaryAuthor ($formattedYear)';
    }
  }
}

class ReferenceParser {
  /// Parses a raw bibliographic string into an [AcademicReference]
  static AcademicReference parse(String rawRef) {
    if (rawRef.isEmpty) {
      return const AcademicReference(
        raw: '',
        authors: '',
        journalOrBook: '',
        year: '',
        publisherOrLocation: '',
        details: '',
      );
    }

    // 1. Extract Year using Regex
    final yearRegex = RegExp(r'\b(19\d\d|20\d\d)\b');
    final yearMatch = yearRegex.firstMatch(rawRef);
    String year = yearMatch != null ? yearMatch.group(0)! : '';

    String authors = '';
    String journalOrBook = '';
    String publisherOrLocation = '';
    String details = '';

    try {
      // Clean raw ref
      var clean = rawRef.trim();

      // 2. Identify authors: usually before double dots ".." or first major segment
      if (clean.contains('..')) {
        final authorPart = clean.split('..')[0];
        authors = authorPart.trim();
        clean = clean.substring(authorPart.length + 2).trim();
      } else if (clean.contains('. ')) {
        final parts = clean.split('. ');
        // Find if parts[0] contains name markers like initials
        if (parts[0].contains(',') || parts[0].contains('-')) {
          authors = parts[0].trim();
          clean = parts.sublist(1).join('. ').trim();
        }
      }

      // If authors not found, fallback to first part before comma
      if (authors.isEmpty && clean.contains(',')) {
        final commaParts = clean.split(',');
        if (commaParts[0].split(' ').length <= 3) {
          authors = commaParts[0].trim();
          clean = commaParts.sublist(1).join(',').trim();
        }
      }

      // 3. Extract details (like page numbers: p. 16, 306 (1973) 866)
      final pRegex = RegExp(r'(,\s*p\.\s*\d+|\b\d+\s*\(\d{4}\)\s*\d+)');
      final pMatch = pRegex.firstMatch(rawRef);
      if (pMatch != null) {
        details = pMatch.group(0)!.replaceAll(RegExp(r'^,\s*'), '').trim();
        clean = clean.replaceAll(pMatch.group(0)!, '').trim();
      }

      // 4. Identify Publisher or Journal
      // Let's check common publishers/journals
      if (clean.contains('Verlag') ||
          clean.contains('Press') ||
          clean.contains('Sons') ||
          clean.contains('University')) {
        final parts = clean.split('.');
        if (parts.length >= 2) {
          journalOrBook = parts[0].trim();
          publisherOrLocation = parts.sublist(1).join('.').trim();
        } else {
          publisherOrLocation = clean;
        }
      } else {
        journalOrBook = clean.replaceAll(RegExp(r'[,\.\s\(\)]+$'), '').trim();
      }
    } catch (_) {
      // Graceful fallback on any parsing failure
      authors = rawRef.split(',')[0].trim();
      journalOrBook = rawRef;
    }

    // Post processing cleanups
    authors = _cleanString(authors);
    journalOrBook = _cleanString(journalOrBook);
    publisherOrLocation = _cleanString(publisherOrLocation);
    details = _cleanString(details);

    return AcademicReference(
      raw: rawRef,
      authors: authors,
      journalOrBook: journalOrBook,
      year: year,
      publisherOrLocation: publisherOrLocation,
      details: details,
    );
  }

  static String _cleanString(String s) {
    return s
        .replaceAll(RegExp(r'^[,\.\s\-]+'), '')
        .replaceAll(RegExp(r'[,\.\s\-]+$'), '')
        .trim();
  }
}
