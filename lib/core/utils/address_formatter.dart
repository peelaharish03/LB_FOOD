String looseMatchKey(String? value) {
  if (value == null) return '';
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String normalizeAddressText(String? value) {
  if (value == null) return '';

  return value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'\s*,\s*'), ', ')
      .replaceAll(RegExp(r'(^[,\s]+)|([,\s]+$)'), '')
      .trim();
}

String joinAddressParts(Iterable<String?> parts) {
  final addressParts = <String>[];

  for (final part in parts) {
    final segments = normalizeAddressText(part)
        .split(RegExp(r'\s*,\s*'))
        .map(normalizeAddressText)
        .where((segment) => segment.isNotEmpty);

    for (final segment in segments) {
      _addUniqueAddressPart(addressParts, segment);
    }
  }

  return addressParts.join(', ');
}

String firstAddressPart(Iterable<String?> parts) {
  for (final part in parts) {
    final value = normalizeAddressText(part);
    if (value.isNotEmpty) return value;
  }

  return '';
}

void _addUniqueAddressPart(List<String> parts, String candidate) {
  final candidateLower = candidate.toLowerCase();

  for (var index = 0; index < parts.length; index++) {
    final existingLower = parts[index].toLowerCase();

    if (existingLower == candidateLower) return;
    if (existingLower.contains(candidateLower)) return;

    if (candidateLower.contains(existingLower)) {
      parts[index] = candidate;
      return;
    }
  }

  parts.add(candidate);
}
