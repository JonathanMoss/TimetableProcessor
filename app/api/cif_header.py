"""Endpoints for CIF HEADER related tables"""

# pylint: disable=E0401

from fastapi import APIRouter, status, Response
from pydantic import ValidationError
from sqlalchemy.exc import IntegrityError

from db.config import async_session
from dal.header_dal import HeaderDal
from schemas.cif_header import Header, RequestBodyModel

HEADER_ROUTES = APIRouter()

@HEADER_ROUTES.get('/api/v1/header/get_update/indicator/{index}', status_code=200, tags=["Read"])
async def get_update_indicator(index: int):
    """Get the update indicator for the header record id passed"""

    async with async_session() as session:
        async with session.begin():
            dal = HeaderDal(session)
            result = await dal.get_update_indicator(index)
    return {'result': result}

@HEADER_ROUTES.get('/api/v1/header/files_to_process/', status_code=200, tags=["Read"])
async def files_to_process():
    """Return a list of CIF files that require processing"""

    async with async_session() as session:
        async with session.begin():
            dal = HeaderDal(session)
            records = await dal.get_files_to_process()
            if not records:
                return {'result': {}}

    return {'result': dict(records)}

@HEADER_ROUTES.put('/api/v1/header/update_expired', status_code=200, tags=["Update"])
async def update_expired():
    """Update expired header records"""

    async with async_session() as session:
        async with session.begin():
            dal = HeaderDal(session)
            await dal.mark_previous_expired()
    return {'result': 'ok'}

@HEADER_ROUTES.get('/api/v1/header/get_current_full_cif', status_code=200, tags=["Read"])
async def get_current_full_cif():
    """Get the current full CIF record"""

    async with async_session() as session:
        async with session.begin():
            dal = HeaderDal(session)
            record = await dal.get_current_full_cif()
    return {'result': record}

@HEADER_ROUTES.get('/api/v1/header/get_all/', status_code=200, tags=["Read"])
async def get_all():
    """Get all header records from the database"""

    async with async_session() as session:
        async with session.begin():
            dal = HeaderDal(session)
            records = await dal.get_all_records()
    return {'result': records}

@HEADER_ROUTES.post('/api/v1/header/insert/', tags=["Create"])
async def insert(body: RequestBodyModel, response: Response):
    """Insert a header record into the database"""
    try:
        header = Header.factory(body.csv_line)
        async with async_session() as session:
            async with session.begin():
                dal = HeaderDal(session)
                result = await dal.create_record(header)
                response.status_code = status.HTTP_201_CREATED
                return {'result': [result]}
    except ValidationError:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return {'error': 'Validation Error', 'data': body.csv_line}
    except ValueError:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return {'error': 'Validation Error', 'data': body.csv_line}
    except IntegrityError as err:
        response.status_code = status.HTTP_409_CONFLICT
        return {'error': err}
