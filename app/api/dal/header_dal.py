"""Data Access Layer - HeaderRecord queries"""

# pylint: disable=R0903,E0401

from typing import List, Union
from sqlalchemy import update, select
from sqlalchemy.orm import Session
from sqlalchemy.exc import NoResultFound
from models.cif_header import HeaderRecord, Status
from schemas.cif_header import Header


class HeaderDal():
    """Data Access Layer - HeaderRecord queries"""


    def __init__(self, db_session: Session):
        self.db_session = db_session

    async def get_files_to_process(self) -> List[str]:
        """Returns a list of files that require processing"""
        query = await self.db_session.execute(
            select(
                HeaderRecord.id,
                HeaderRecord.uncompressed_file_name
            ).where(
                HeaderRecord.status == Status.TO_PROCESS
            ).order_by(
                HeaderRecord.update_indicator.asc()
            ).order_by(
                HeaderRecord.id.asc()
            )
        )
        return query.fetchall()

    async def get_update_indicator(self, header_id: int) -> Union[str, None]:
        """Returns the update_indcator for the passed header id"""
        try:
            query = await self.db_session.execute(
                select(
                    HeaderRecord.update_indicator
                ).where(
                    HeaderRecord.id == header_id
                )
            )
            return query.one()[0]
        except NoResultFound:
            return None

    async def get_current_full_cif(self) -> HeaderRecord:
        """Returns the current full CIF"""
        query = await self.db_session.execute(
            select(
                HeaderRecord
            ).where(
                HeaderRecord.update_indicator == 'F'
            ).where(
                HeaderRecord.status not in (Status.EXPIRED, Status.ERROR, Status.OUT_OF_SEQUENCE)
            ).order_by(
                HeaderRecord.id.desc()
            )
        )

        return query.scalars().first()

    async def _set_expired_headers(self, current_full_cif_id: int):
        """Return a list of expired header records"""
        query = update(
            HeaderRecord
        ).where(
            HeaderRecord.id < current_full_cif_id
        ).values(
            status=Status.EXPIRED
        )

        await self.db_session.execute(query)
        await self.db_session.commit()

    async def update_processed(self, header_id: int):
        """Update the header record once processed"""
        query = update(
            HeaderRecord
        ).where(
            HeaderRecord.id == header_id
        ).values(
            status=Status.PROCESSED
        )

        await self.db_session.execute(query)
        await self.db_session.commit()

    async def mark_previous_expired(self):
        """Update all previous header records as expired"""
        cur_full_cif = await self.get_current_full_cif()
        return await self._set_expired_headers(cur_full_cif.id)

    async def mark_out_of_sequence(self):
        """Check for update CIF sequencing and update sequence status"""

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
        return new_record
