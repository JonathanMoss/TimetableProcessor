"""Endpoints for CIF HEADER related tables"""

# pylint: disable=E0401

from fastapi import APIRouter, status, Response
from pydantic import ValidationError
from sqlalchemy.exc import IntegrityError

from db.config import async_session
from dal.header_dal import HeaderDal
from schemas.cif_header import Header, RequestBodyModel

HEADER_ROUTES = APIRouter()

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
        print(body)
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
