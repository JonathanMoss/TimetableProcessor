"""Data Access Layer - HeaderRecord queries"""

# pylint: disable=R0903,E0401


from sqlalchemy.future import select
from sqlalchemy.orm import Session


from models.cif_header import HeaderRecord
from schemas.cif_header import Header


class HeaderDal():
    """Data Access Layer - HeaderRecord queries"""

    def __init__(self, db_session: Session):
        self.db_session = db_session

    async def get_all_records(self) -> dict:
        """Return all header records"""
        query = await self.db_session.execute(
            select(HeaderRecord).order_by(HeaderRecord.mainframe_identity)
        )
        return query.scalars().all()

    async def create_record(self, header: Header):
        """Attempt to insert a header record into the db"""

        new_record = HeaderRecord(**header.model_dump())
        self.db_session.add(new_record)
        await self.db_session.commit()
        await self.db_session.flush()
        return new_record
