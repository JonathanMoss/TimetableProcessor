"""Model representations for VSTP schedule data"""

# pylint: disable=R0903, E0401, W0611

from db.config import Base
from sqlalchemy import (
    Column, 
    String, 
    Integer,
    ForeignKey)

class VSTPBasicSchedule(Base):
    """Model of a Basic Schedule (BS)
        CIF timetable element"""

    __tablename__ = 'vstp_basic_schedule'

    id = Column(Integer, primary_key=True, index=True)
    transaction_type = Column(String(1), nullable=False)
    uid = Column(String(6), nullable=False, index=True)
    date_runs_from = Column(String(6), nullable=False, index=True)
    date_runs_to = Column(String(6), default=None, index=True)
    days_run = Column(String(7), default=None, index=True)
    bank_holiday_running = Column(String(1), default=None)
    train_status = Column(String(1), default=None)
    train_category = Column(String(2), default=None)
    train_identity = Column(String(4), default=None)
    headcode = Column(String(4), default=None)
    train_service_code = Column(String(8), default=None)
    portion_id = Column(String(1), default=None)
    power_type = Column(String(3), default=None)
    timing_load = Column(String(4), default=None)
    speed = Column(String(3), default=None)
    operating_characteristics = Column(String(6), default=None)
    seating_class = Column(String(1), default=None)
    sleepers = Column(String(1), default=None)
    reservations = Column(String(1), default=None)
    catering_code = Column(String(4), default=None)
    service_branding = Column(String(4), default=None)
    stp_indicator = Column(String(1), default=None)

class VSTPBasicExtra(Base):
    """Model of CIF Basic Schedule Extra (BX)"""
    __tablename__ = 'vstp_basic_extra'

    id = Column(Integer, primary_key=True, index=True)
    bs_id = Column(Integer, ForeignKey(VSTPBasicSchedule.id, ondelete="cascade"), index=True)
    uic_code = Column(String(5), default=None)
    atoc_code = Column(String(2), nullable=False)
    applicable_timetable = Column(String(1), nullable=False)

class VSTPLocation(Base):
    """Model of a CIF location record (LO, LI, LT)"""
    __tablename__ = 'vstp_location'

    id = Column(Integer, primary_key=True, index=True)
    bs_id = Column(Integer, ForeignKey(VSTPBasicSchedule.id, ondelete="cascade"), index=True)
    record_type = Column(String(2), nullable=False)
    tiploc = Column(String(7), nullable=False)
    suffix = Column(Integer, default=1)
    wta = Column(String(5), default=None)
    wtp = Column(String(5), default=None)
    wtd = Column(String(5), default=None)
    pta = Column(String(4), default=None)
    ptd = Column(String(4), default=None)
    platform = Column(String(3), default=None)
    line = Column(String(3), default=None)
    path = Column(String(3), default=None)
    activity = Column(String(12), default=None)
    engineering_allowance = Column(String(2), default=None)
    pathing_allowance = Column(String(2), default=None)
    performance_allowance = Column(String(2), default=None)
