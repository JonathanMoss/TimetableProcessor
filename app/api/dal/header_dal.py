"""Data Access Layer - HeaderRecord queries"""

# pylint: disable=R0903,E0401

from typing import List
from sqlalchemy.future import select
from sqlalchemy.orm import Session
from models.cif_header import HeaderRecord
from schemas.cif_header import Header
from sqlalchemy.exc import IntegrityError
from pydantic import ValidationError

class HeaderDal():
    """Data Access Layer - HeaderRecord queries"""

    def __init__(self, db_session: Session):
        self.db_session = db_session

    async def get_all_records(self) -> List[HeaderRecord]:
        """Returns all header records"""
        query = await self.db_session.execute(
            select(HeaderRecord).order_by(HeaderRecord.mainframe_identity)
        )
        return query.scalars().all()
    
    async def create_record(self, header: Header):
        """Create a new header record"""
        try:
            new_record = HeaderRecord(**header.model_dump())
            self.db_session.add(new_record)
            self.db_session.commit()
            await self.db_session.flush()
            return new_record
        except IntegrityError as int_err:
            return new_record
        except ValidationError as val_err:
            return None