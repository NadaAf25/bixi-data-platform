import glob
import zipfile

import pandas as pd

for path in sorted(glob.glob("data/raw/**/*.zip", recursive=True)):
    with zipfile.ZipFile(path) as z:
        csvs = [n for n in z.namelist() if n.lower().endswith(".csv")]
        print(path, "->", len(csvs), "csv file(s)")
        ref = None
        for name in csvs:
            with z.open(name) as f:
                cols = list(pd.read_csv(f, nrows=2).columns)
            if ref is None:
                ref = cols
                print("  first:", name, cols)
            elif cols != ref:
                print("  DIFFERENT:", name, cols)

w = pd.read_csv("data/raw/weather_2025.csv", nrows=2)
print("weather_2025.csv ->", list(w.columns))