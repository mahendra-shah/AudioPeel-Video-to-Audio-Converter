/// Input validation helpers.
abstract final class ValidationUtils {
  /// Returns `null` if [name] is a valid output file name, or an error string.
  static String? validateFileName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'File name cannot be empty';
    }
    if (name.trim().length > 50) {
      return 'File name must be 50 characters or fewer';
    }
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(name)) {
      return 'File name contains invalid characters';
    }
    return null;
  }
}
