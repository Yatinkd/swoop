import 'dart:typed_data';

class OnboardingData {
  bool isEditing = false;

  String name = '';
  Uint8List? profileImageBytes;
  String? profileImageType;
  String?
  existingImageUrl; // Keep track of their current photo if they have one!

  String location = '';

  // Smart Prompts
  String bioEnjoy = '';
  String bioWeekend = '';

  List<String> vibes = [];

  // Interests changed to List to support Chip selecting
  List<String> interestsList = [];

  String university = '';
  String major = '';
  String gradYear = '';

  // Helper getter to combine Smart Prompts properly for the backend Single-String column natively.
  String get consolidatedBio {
    if (bioEnjoy.isEmpty && bioWeekend.isEmpty) return '';
    if (bioEnjoy.isEmpty) return 'Weekend: $bioWeekend';
    if (bioWeekend.isEmpty) return 'Enjoy: $bioEnjoy';
    return 'Enjoy: $bioEnjoy\nWeekend: $bioWeekend';
  }
}
