"""Endpoints for TSDB related tables"""

# pylint: disable=E0401

from fastapi import APIRouter
from db.config import async_session
from dal.tsdb_dal import TSDBDal

TSDB_ROUTES = APIRouter()

@TSDB_ROUTES.get('/api/v1/tsdb/next_index/', status_code=200, tags=["Read"])
async def get_bs_index():
    """Returns the next available basic schedule index"""

    async with async_session() as session:
        async with session.begin():
            dal = TSDBDal(session)
            records = await dal.get_current_index()
    return {'result': records + 1}
