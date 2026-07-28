from sqlalchemy import text

def load_dataframe(df,table,engine):

    df.to_sql(

        table,

        engine,

        if_exists="append",

        index=False,

        chunksize=5000,

        method="multi"

    )

    with engine.connect() as conn:

        result=conn.execute(

            text(f"SELECT COUNT(*) FROM {table}")

        )

        rows=result.scalar()

    return rows