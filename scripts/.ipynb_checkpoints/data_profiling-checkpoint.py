from pathlib import Path
import pandas as pd
from contextlib import redirect_stdout

BASE_DIR = Path(__file__).resolve().parents[1]
RAW_DIR = BASE_DIR / "data" / "raw"

REPORTS_DIR = BASE_DIR / "reports"
REPORTS_DIR.mkdir(parents=True, exist_ok=True)

REPORT_PATH = REPORTS_DIR / "data_profiling.txt"

with REPORT_PATH.open("w", encoding="utf-8") as report:
    with redirect_stdout(report):
        for csv_file in sorted(RAW_DIR.glob("*.csv")):
            df = pd.read_csv(csv_file)

            print(f"\nFILE: {csv_file.name}")
            print(f"Rows: {df.shape[0]}")
            print(f"Columns: {df.shape[1]}")

            print("\nColumn types:")
            print(df.dtypes)

            print("\nMissing values:")
            print("-" * 65)
            print(f"{'Column':<40} {'NULL':>10} {'%NULL':>10}")
            print("-" * 65)

            for column in df.columns:
                null_count = df[column].isna().sum()
                null_percent = df[column].isna().mean() * 100

                print(f"{column:<40} {null_count:>10} {null_percent:>9.2f}%")

            print("\n Unique values:")
            print("-" * 65)
            print(f"{'Column':<40} {'Unique':>10}")
            print("-" * 65)
            for column in df.columns:
                unique_values = df[column].nunique()
                print(f"{column:<40} {unique_values:>10}")

            df_dublicated_rows = df.duplicated().sum()
            print(f"\n Duplicate rows: {df_dublicated_rows}")

print(f"Report saved to: {REPORT_PATH}")

