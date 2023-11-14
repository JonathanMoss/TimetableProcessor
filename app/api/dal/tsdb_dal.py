"""Data Access Layer - TSDB"""

# pylint: disable=R0903, W0611, E0401

from typing import Tuple
from sqlalchemy.orm import Session
from sqlalchemy.exc import NoResultFound, IntegrityError
from sqlalchemy import select, text
from models.tsdb import (
    BasicSchedule,
    BasicExtra,
    Location,
    ChangeEnRoute
)
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

            await self.db_session.commit()
            return {'result': res}
        except IntegrityError:
            return {'result': 'IntegrityError'}
