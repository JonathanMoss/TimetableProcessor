"""Endpoints for CIF HEADER related tables"""

from fastapi import APIRouter

from db.config import async_session
from dal.header_dal import HeaderDal
from schemas.cif_header import Header

HEADER_ROUTES = APIRouter()

@HEADER_ROUTES.get('/api/v1/header/get_all/')
async def get_all():
    """Get all header records from the database"""

    async with async_session() as session:
        async with session.begin():
            dal = HeaderDal(session)
            records = await dal.get_all_records()
    return 200, {'result': records}

@HEADER_ROUTES.post('/api/v1/header/insert/{csv_line}')
async def insert(csv_line: str):
    """Insert a header record into the database"""
    header = Header.factory(csv_line)
    async with async_session() as session:
        async with session.begin():
            dal = HeaderDal(session)
            result = await dal.create_record(header)
            
    return 200, result
            
