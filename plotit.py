#!/usr/bin/env python3

import sys
import plotly.express as px
import pandas as pd
import numpy as np
import plotly.graph_objects as go
from plotly.subplots import make_subplots


def plot_express(tags, rom, ram):
    # convert the 3 lists into a panda dataframe
    df = pd.DataFrame(np.c_[rom, ram], columns=["rom", "ram"])

    fig = px.line(
        df,
        x=tags,
        y=["rom", "ram"],
        # dict(ROM=rom,RAM=ram),
        labels={"x": "tag", "y": "size in bytes"},
        title="SDK Size per Tag",
    )
    fig.write_html("size_per_tag.html", auto_open=True)


def plot_multi_y_axis(tags, rom, ram):
    # use specs parameter in make_subplots function
    # to create secondary y-axis
    fig = make_subplots(specs=[[{"secondary_y": True}]])

    # plot a scatter chart by specifying the x and y values
    # Use add_trace function to specify secondary_y axes.
    fig.add_trace(go.Scatter(x=tags, y=rom, name="ROM"), secondary_y=False)

    # Use add_trace function and specify secondary_y axes = True.
    fig.add_trace(go.Scatter(x=tags, y=ram, name="RAM"), secondary_y=True)

    # Adding title text to the figure
    fig.update_layout(title_text="SDK Size per Tag")

    # Naming x-axis
    fig.update_xaxes(title_text="Tag")

    # Naming y-axes
    fig.update_yaxes(title_text="<b>ROM</b> bytes", secondary_y=False)
    fig.update_yaxes(title_text="<b>RAM</b> bytes", secondary_y=True)

    fig.write_html("size_per_tag.html", full_html=False, include_plotlyjs='cdn', auto_open=True)


if __name__ == "__main__":
    with open(sys.argv[1]) as f:
        data = f.readlines()

    tags, rom, ram = [], [], []
    for line in data:
        if len(line.strip()):
            tag, rom_point, ram_point = line.strip().split()
            tags.append(tag.strip())
            rom.append(int(rom_point.strip()))
            # offset by the RAM-backed coredump size (-8000)
            ram_point = int(ram_point.strip()) - 8000
            # hard coded, add in the s_log_buf_storage + s_event_storage sizes
            ram_point += 512 + 1024
            ram.append(ram_point)

    # plot_express(tags, rom, ram)
    plot_multi_y_axis(tags, rom, ram)
