import os

filepath = "/Users/yatinkd/community app/community_app/lib/screens/profile_screen.dart"

with open(filepath, "r") as f:
    content = f.read()

# Add import for activity_screen
if "import 'activity_screen.dart';" not in content:
    content = content.replace("import 'edit_profile_screen.dart';", "import 'edit_profile_screen.dart';\nimport 'activity_screen.dart';")

# Add _allActivities dummy data inside build logic
build_start = content.find("    final isCompactPhone = MediaQuery.sizeOf(context).width < 380;")
if build_start != -1:
    dummy_data = """    final isCompactPhone = MediaQuery.sizeOf(context).width < 380;

    final List<Map<String, String>> _allActivities = [
      {'title': 'Sunset Beach Bonfire', 'date': 'Oct 14', 'status': 'Hosted'},
      {'title': 'Coffee & Code', 'date': 'Oct 10', 'status': 'Joined'},
      {'title': 'Morning Hike', 'date': 'Oct 02', 'status': 'Joined'},
      {'title': 'Friday Night Drinks', 'date': 'Sep 28', 'status': 'Hosted'},
      {'title': 'Book Club: Sci-Fi', 'date': 'Sep 15', 'status': 'Joined'},
    ];"""
    content = content.replace("    final isCompactPhone = MediaQuery.sizeOf(context).width < 380;", dummy_data)

# Replace section 5 and delete section 6 up to section 7
section_5_start = content.find("              // 5. ACTIVITY SECTION")
section_7_start = content.find("              // 7. SETTINGS SECTION")

if section_5_start != -1 and section_7_start != -1:
    new_section_5 = """              // 5. ACTIVITY SECTION (LIMITED)
              const SizedBox(height: 32),
              const Text(
                'Your Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              ..._allActivities.take(3).map((act) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActivityCard(
                  title: act['title']!,
                  date: act['date']!,
                  status: act['status']!
                ),
              )),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActivityScreen(activities: _allActivities),
                      ),
                    );
                  },
                  child: const Text(
                    'View all →',
                    style: TextStyle(
                      fontWeight: FontWeight.w700, 
                      fontSize: 14, 
                      color: AppColors.primary
                    ),
                  ),
                ),
              ),

"""
    content = content[:section_5_start] + new_section_5 + content[section_7_start:]

with open(filepath, "w") as f:
    f.write(content)

print("done profile")
