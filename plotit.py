#!/usr/bin/env python3

import sys
import plotly.express as px

if __name__ == "__main__":
    with open(sys.argv[1]) as f:
        data = f.readlines()

    x, y1, y2 = [], [], []
    for line in data:
        if len(line.strip()):
            tag, rom, ram = line.strip().split()
            x.append(tag.strip())
            y1.append(int(rom.strip()))
            y2.append(int(ram.strip()))
    # convert the date array to a numpy datetime object
    fig = px.line(
        x=x,
        y=[y1,y2],
        labels={"x": "tag", "y": "size"},
        title="SDK Size per Tag",
    )
    fig.write_html("size_per_tag.html", auto_open=True)
