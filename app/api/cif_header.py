"""Endpoints for CIF HEADER related tables"""

# pylint: disable=E0401

from fastapi import APIRouter
from db.config import async_session
from dal.header_dal import HeaderDal

HEADER_ROUTES = APIRouter()

@HEADER_ROUTES.get('/api/v1/header/get_all/')
async def get_all():
    """Get all header records from the database"""

    async with async_session() as session:
        async with session.begin():
            dal = HeaderDal(session)
            records = await dal.get_all_records()
    return 200, {'get_all': records}
