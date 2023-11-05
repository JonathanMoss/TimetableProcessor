#!/bin/python3
"""Entrypoint for FastAPI"""

# pylint: disable=C0413, W0611

from fastapi import FastAPI
import cif_header

from db.config import engine, Base

app = FastAPI(
    docs_url='/',
    title='TimeTableProcessor Database API',
    description='An API for the TimeTableProcessor Database'
)

app.include_router(cif_header.HEADER_ROUTES)

@app.on_event("startup")
async def startup():
    """Creates the necessary db tables"""

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
