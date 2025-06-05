class PaymentMemberInfo {
  final String name;
  final String email;
  final bool hasPaid;

  PaymentMemberInfo({
    required this.name,
    required this.email,
    required this.hasPaid,
  });

  factory PaymentMemberInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMemberInfo(
      name: json['name'] as String,
      email: json['email'] as String,
      hasPaid: json['hasPaid'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'hasPaid': hasPaid,
    };
  }
} 