from sqlalchemy import create_engine
from config import *

def get_engine():

    engine = create_engine(
        f"mysql+pymysql://{USERNAME}:{PASSWORD}@{HOST}:{PORT}/{DATABASE}",
        pool_pre_ping=True,
        pool_recycle=3600
    )

    return engine