/// Environment of project operates
/// Sandbox: App in testing/editor
/// Production: App is in production
enum MetriqusEnvironment {
  sandbox,
  production,
}

/// Extension methods for MetriqusEnvironment
extension MetriqusEnvironmentExtension on MetriqusEnvironment {
  String toLowercaseString() {
    switch (this) {
      case MetriqusEnvironment.sandbox:
        return "sandbox";
      case MetriqusEnvironment.production:
        return "production";
    }
  }
}
