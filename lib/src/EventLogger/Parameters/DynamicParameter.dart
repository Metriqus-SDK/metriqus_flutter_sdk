/// Dynamic parameter for Metriqus events
class DynamicParameter {
  final String name;
  final dynamic value;

  String get parameterName => name;
  dynamic get parameterValue => value;

  DynamicParameter(this.name, this.value);

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }

  /// Create from JSON
  factory DynamicParameter.fromJson(Map<String, dynamic> json) {
    return DynamicParameter(
      json['name'] ?? '',
      json['value'],
    );
  }

  @override
  String toString() {
    return 'DynamicParameter(name: $name, value: $value)';
  }
}
