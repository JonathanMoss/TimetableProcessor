"""Endpoints for CIF HEADER related tables"""

from fastapi import APIRouter

HEADER_ROUTES = APIRouter()

@HEADER_ROUTES.get('/api/v1/header/get_all/')
async def get_all():
    """Get all header records from the database"""
    return 200, {'get_all': []}
