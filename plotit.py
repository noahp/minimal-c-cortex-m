#!/usr/bin/env python3

import sys
import plotly.express as px
import pandas as pd
import numpy as np

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
    # convert the 3 lists into a panda dataframe
    df = pd.DataFrame(np.c_[y1, y2], columns=['rom', 'ram'])

    fig = px.line(
        df,
        x=x,
        y=["rom", "ram"],
        # dict(ROM=y1,RAM=y2),
        labels={"x": "tag", "y": "size in bytes"},
        title="SDK Size per Tag",
    )
    fig.write_html("size_per_tag.html", auto_open=True)
