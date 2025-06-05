enum PartyOption {
  mixed('MIXED', '혼성'),
  onlyMale('ONLY_MALE', '남성만'),
  onlyFemale('ONLY_FEMALE', '여성만');

  final String value;
  final String label;

  const PartyOption(this.value, this.label);

  static PartyOption fromString(String value) {
    return PartyOption.values.firstWhere(
      (option) => option.value == value,
      orElse: () => PartyOption.mixed,
    );
  }

  @override
  String toString() => value;
} 