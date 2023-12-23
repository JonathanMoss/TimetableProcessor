"""Endpoints for TSDB related tables"""

# pylint: disable=E0401

from fastapi import APIRouter
from db.config import async_session
from dal.tsdb_dal import TSDBDal
from schemas.tsdb import ImportCIFPayloadBody

TSDB_ROUTES = APIRouter()

@TSDB_ROUTES.delete('/api/v1/tsdb/process_del/', status_code=200, tags=["DELETE"])
async def process_del():
    """Processes CIF delete transactions"""

    async with async_session() as session:
        async with session.begin():
            dal = TSDBDal(session)
            result = await dal.process_del()
    return {'result': result}

@TSDB_ROUTES.put('/api/v1/tsdb/process_rep/', status_code=200, tags=["Update"])
async def process_rep():
    """Processes CIF replace transactions"""

    async with async_session() as session:
        async with session.begin():
            dal = TSDBDal(session)
            result = await dal.process_rep()
    return {'result': result}

@TSDB_ROUTES.delete('/api/v1/tsdb/truncate_bs/', status_code=200, tags=["DELETE"])
async def truncate_bs():
    """Truncates the basic_schedule table"""

    async with async_session() as session:
        async with session.begin():
            dal = TSDBDal(session)
            await dal.empty_bs()
    return {'result': 'ok'}

@TSDB_ROUTES.delete('/api/v1/tsdb/delete_expired/', status_code=200, tags=["DELETE"])
async def delete_expired():
    """Deletes expired records"""

    async with async_session() as session:
        async with session.begin():
            dal = TSDBDal(session)
            result = await dal.delete_expired()
    return {'result': result}

@TSDB_ROUTES.get('/api/v1/tsdb/next_index/', status_code=200, tags=["Read"])
async def get_bs_index():
    """Returns the next available basic schedule index"""

    async with async_session() as session:
        async with session.begin():
            dal = TSDBDal(session)
            index = await dal.get_current_index()
    return {'result': index}

@TSDB_ROUTES.post('/api/v1/tsdb/import/', status_code=200, tags=["Create"])
async def import_cif(body: ImportCIFPayloadBody):
    """Makes a request to import the CIF files specified"""

    async with async_session() as session:
        async with session.begin():
            dal = TSDBDal(session)
            records = await dal.import_cif(body)
    return {'result': records['result']}
