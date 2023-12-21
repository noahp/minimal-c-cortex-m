import sys
from collections import defaultdict
from operator import itemgetter

data = sys.stdin.read()

# Split data into lines and filter out lines without file information
lines = [line.split() for line in data.splitlines() if len(line.split()) > 3]

# Create a defaultdict to tally sizes per file
file_sizes = defaultdict(int)

# Iterate through lines to tally sizes for each file
for line in lines:
    if line[2].lower() == "t":
        size = int(line[1], 16)
        file_name = line[-1]
        file_sizes[file_name] += size

# Sort files by total size in descending order
sorted_files = sorted(file_sizes.items(), key=itemgetter(1), reverse=True)

# Print the sorted and tallied file sizes
for file_name, total_size in sorted_files:
    print(f"{total_size:#10d} {file_name}")
