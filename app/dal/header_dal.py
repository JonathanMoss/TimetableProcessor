"""Data Access Layer - HeaderRecord queries"""

# pylint: disable=E0401, R0903

from typing import List
from sqlalchemy.future import select
from sqlalchemy.orm import Session
from models.cif_header import HeaderRecord

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
