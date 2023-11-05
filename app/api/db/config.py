"""Database connection configuration"""

import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import declarative_base, sessionmaker

DB_USER = os.environ.get("POSTGRES_USER", 'postgres')
DB_PASS = os.environ.get("POSTGRES_PASSWORD", 'password')
DB_HOST = os.environ.get("POSTGRES_HOST", 'postgres')

SQLALCHEMY_DATABASE_URL = f"postgresql+asyncpg://{DB_USER}:{DB_PASS}@{DB_HOST}/TSDB"

engine = create_async_engine(SQLALCHEMY_DATABASE_URL, future=True, echo=True)
async_session = sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
Base = declarative_base()
