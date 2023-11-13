"""Endpoints for TSDB related tables"""

# pylint: disable=E0401

from fastapi import APIRouter, Response
from db.config import async_session
from dal.tsdb_dal import TSDBDal
from schemas.tsdb import ImportCIFPayloadBody

TSDB_ROUTES = APIRouter()

@TSDB_ROUTES.get('/api/v1/tsdb/next_index/', status_code=200, tags=["Read"])
async def get_bs_index():
    """Returns the next available basic schedule index"""

    async with async_session() as session:
        async with session.begin():
            dal = TSDBDal(session)
            records = await dal.get_current_index()
    return {'result': records + 1}

@TSDB_ROUTES.post('/api/v1/tsdb/import/', status_code=200, tags=["Create"])
async def import_cif(body: ImportCIFPayloadBody, response: Response):
    """Makes a request to import the CIF files specified"""
    
    async with async_session() as session:
        async with session.begin():
            dal = TSDBDal(session)
            records = await dal.import_cif(body)
    return {}
            
