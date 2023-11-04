#!/bin/python3
"""Entrypoint for FastAPI"""

from fastapi import FastAPI
import cif_header

app = FastAPI(
    docs_url='/',
    title='TimeTableProcessor Database API',
    description='An API for the TimeTableProcessor Database'
)

app.include_router(cif_header.HEADER_ROUTES)
