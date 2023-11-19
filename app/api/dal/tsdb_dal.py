"""Data Access Layer - TSDB"""

# pylint: disable=R0903, W0611, E0401

import asyncio
import re
from typing import Tuple
from sqlalchemy.orm import Session
from sqlalchemy.exc import NoResultFound, IntegrityError
from sqlalchemy import select, text, update
from models.tsdb import (
    BasicSchedule,
    BasicExtra,
    Location,
    ChangeEnRoute
)
from models.cif_header import HeaderRecord, Status
from schemas.tsdb import ImportCIFPayloadBody

LOC_FIELDS = "bs_id,record_type,tiploc,suffix,wta," \
            "wtp,wtd,pta,ptd,platform,line,path,activity," \
            "engineering_allowance,pathing_allowance,performance_allowance"

CR_FIELDS = "bs_id,tiploc,suffix,train_category,train_identity,headcode," \
            "train_service_code,portion_id,power_type,timing_load,speed," \
            "operating_characteristics,seating_class,sleepers,reservations," \
            "catering_code,service_branding,uic_code"

BX_FIELDS = "bs_id,uic_code,atoc_code,applicable_timetable"


class TSDBDal():
    """Data Access Layer - TSDB"""

    def __init__(self, db_session: Session):
        self.db_session = db_session

    async def empty_bs(self, commit=True):
        """TRUNATES basic_schedule table"""
        stmt = 'TRUNCATE TABLE basic_schedule CASCADE;'
        await self.db_session.execute(text(stmt))
        if commit:
            await self.db_session.commit()

    async def update_processed(self, header_id: int, commit=False):
        """Update the CIF header record once processed"""
        query = update(
            HeaderRecord
        ).where(
            HeaderRecord.id == header_id
        ).values(
            status=Status.PROCESSED
        )

        await self.db_session.execute(query)
        if commit:
            await self.db_session.commit()

    async def delete_expired(self, commit=True) -> None:
        """Delete expired records"""

        await self.db_session.execute(text("CALL delete_expired();"))
        if commit:
            await self.db_session.commit()

    async def get_current_index(self) -> int:
        """Returns the last used BS record index"""
        stmt = text(
            'SELECT basic_schedule.id FROM basic_schedule ORDER BY basic_schedule.id DESC LIMIT 1;'
        )
        try:
            query = await self.db_session.execute(stmt)
            return query.one()[0]
        except NoResultFound:
            return 0

    async def import_cif(self, body: ImportCIFPayloadBody):
        """Import the CIF files"""

        try:
            stmt = f"COPY basic_schedule FROM '{body.bs}' DELIMITER ',' CSV HEADER;"
            await self.db_session.execute(text(stmt))
            res = [f'{body.bs} imported']

            stmt = f"COPY location({LOC_FIELDS}) FROM '{body.lo}' DELIMITER ',' CSV HEADER;"
            await self.db_session.execute(text(stmt))
            res.append(f'{body.lo} imported')

            stmt = f"COPY changes_en_route({CR_FIELDS}) FROM '{body.cr}' DELIMITER ',' CSV HEADER;"
            await self.db_session.execute(text(stmt))
            res.append(f'{body.cr} imported')

            stmt = f"COPY basic_extra({BX_FIELDS}) FROM '{body.bx}' DELIMITER ',' CSV HEADER;"
            await self.db_session.execute(text(stmt))
            res.append(f'{body.bx} imported')

            header_id = re.findall('[0-9]{1,}', body.bs)
            if not header_id:
                await self.db_session.commit()
                return {'result': res}
            await self.update_processed(int(header_id[0]))
            await self.db_session.commit()
            return {'result': res}
        except IntegrityError:
            return {'result': 'IntegrityError'}

"""
SELECT * FROM basic_schedule WHERE transaction_type = 'D';
SELECT * FROM basic_schedule WHERE transaction_type = 'R';

CREATE OR REPLACE PROCEDURE delete_expired()
LANGUAGE SQL
AS $$
DELETE FROM changes_en_route WHERE bs_id IN (SELECT id FROM basic_schedule WHERE CAST (date_runs_to AS DATE) < (current_date - INTEGER '1'));
DELETE FROM basic_extra WHERE bs_id IN (SELECT id FROM basic_schedule WHERE CAST (date_runs_to AS DATE) < (current_date - INTEGER '1'));
DELETE FROM location WHERE bs_id IN (SELECT id FROM basic_schedule WHERE CAST (date_runs_to AS DATE) < (current_date - INTEGER '1'));
DELETE FROM basic_schedule WHERE CAST (date_runs_to AS DATE) < (current_date - INTEGER '1');
$$"""