import pandas as pd

def validate_dataframe(df,name):

    print("="*60)

    print(name)

    print("="*60)

    print(f"Rows : {len(df):,}")

    print(f"Columns : {len(df.columns)}")

    duplicates=df.duplicated().sum()

    print(f"Duplicates : {duplicates}")

    nulls=df.isnull().sum()

    if nulls.sum()>0:

        print("\nMissing Values")

        print(nulls[nulls>0])

    print("="*60)