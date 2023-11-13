"""Data Access Layer - TSDB"""

# pylint: disable=R0903, W0611, E0401

from sqlalchemy.orm import Session
from sqlalchemy.exc import NoResultFound
from sqlalchemy import select, text
from models.tsdb import (
    BasicSchedule,
    BasicExtra,
    Location,
    ChangeEnRoute
)

class TSDBDal():
    """Data Access Layer - TSDB"""

    def __init__(self, db_session: Session):
        self.db_session = db_session

    async def get_current_index(self) -> int:
        """Returns the last used BS record index"""
        stmt = text('SELECT basic_schedule.id FROM basic_schedule ORDER BY basic_schedule.id DESC;')
        try:
            query = await self.db_session.execute(stmt)
            return query.one()
        except NoResultFound:
            return 0

    async def import_cif(self, body):
        """Import the CIF files"""
        stmt = text(f"COPY basic_schedule FROM '{body.bs}' DELIMITER ',' CSV HEADER;")
        query = await self.db_session.execute(stmt)
        await self.db_session.commit()
        return {}
