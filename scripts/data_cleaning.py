import pandas as pd

def clean_dataframe(df):

    df=df.drop_duplicates()

    df=df.replace("",pd.NA)

    object_cols=df.select_dtypes(include="object").columns

    for col in object_cols:

        df[col]=df[col].str.strip()

    return df