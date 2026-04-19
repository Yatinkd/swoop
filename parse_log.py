import json

log_file = "/Users/yatinkd/.gemini/antigravity/brain/34d44d7c-fc03-4ca5-8db3-a5c929c9ef0f/.system_generated/logs/overview.txt"

def extract_file(target_file, output_file):
    with open(log_file, "r") as f:
        content = f.read()

    # Find all occurrences of target_file
    import re
    # Look for "CodeContent": "..." associated with TargetFile
    # Because JSON can be huge and multiline, we can search for the tool call
    
    # Simple manual extraction: we know the logs are line by line or JSON wrapped?
    # Let's just find "write_to_file" or "replace_file_content" and the target.
    # A cleaner way is using a rough regex.
    pass

import sys
# Just search for the file
with open(log_file, "r") as f:
    lines = f.readlines()

found_tool_call = False
buffer = []
all_calls = []

for line in lines:
    if "<ctrl42>call:default_api:write_to_file" in line:
        # It's a single line if it's packed, or maybe multiline?
        pass

