import os

filepath = "/Users/yatinkd/community app/community_app/lib/screens/profile_screen.dart"

with open(filepath, "r") as f:
    content = f.read()

# Rename _ActivityCard to ActivityCard for usages
content = content.replace("_ActivityCard(", "ActivityCard(")

# Delete the class definition of _ActivityCard
class_def_start = content.find("class _ActivityCard extends StatelessWidget {")
if class_def_start != -1:
    content = content[:class_def_start]

with open(filepath, "w") as f:
    f.write(content)

print("fixed profile")
