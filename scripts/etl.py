import os
import time

from database import get_engine
from table_mapping import TABLE_MAPPING
from validation import validate_dataframe
from data_cleaning import clean_dataframe
from loader import load_dataframe
from logger import logger
from report import ETLReport
from config import DATA_FOLDER

import pandas as pd
from tqdm import tqdm

engine = get_engine()

report = ETLReport()

print("=" * 70)
print("🚀 STARTING E-COMMERCE ETL PIPELINE")
print("=" * 70)

for csv_file, table_name in tqdm(
    TABLE_MAPPING.items(),
    total=len(TABLE_MAPPING),
    desc="Loading Tables"
):

    try:

        start = time.time()

        path = os.path.join(DATA_FOLDER, csv_file)

        df = pd.read_csv(path)

        validate_dataframe(df, table_name)

        df = clean_dataframe(df)

        rows = load_dataframe(df, table_name, engine)

        elapsed = round(time.time() - start, 2)

        logger.info(
            f"{table_name} | {rows} rows | {elapsed} sec"
        )

        report.success(rows)

        print(f"✅ {table_name} loaded ({elapsed} sec)")

    except Exception as e:

        report.fail()

        logger.error(f"{table_name} : {e}")

        print(f"❌ {table_name} failed")

report.show()