"""Model representations for timetable data"""

# pylint: disable=R0903, E0401, W0611

import enum
from sqlalchemy import (
    Column,
    String,
    BigInteger,
    Integer,
    Enum,
    ForeignKey
)
from db.config import Base

class TransactionType(enum.Enum):
    """Valid schedule transaction types"""
    NEW = 1
    DELETE = 2
    REVISE = 3

class TimingPointType(enum.Enum):
    """Valid timing point types"""
    LO = 1
    LI = 2
    LT = 3

class BasicSchedule(Base):
    """Model of a Basic Schedule (BS) 
        CIF timetable element"""

    __tablename__ = 'basic_schedule'

    id = Column(Integer, primary_key=True, index=True)
    transaction_type = Column(Enum(TransactionType), nullable=False)
    uid = Column(String(6), nullable=False)
    date_runs_from = Column(String(6), nullable=False)
    date_runs_to = Column(String(6), default=None)
    days_run = Column(String(7), default=None)
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

class BasicExtra(Base):
    """Model of CIF Basic Schedule Extra (BX)"""
    __tablename__ = 'basic_extra'

    id = Column(Integer, primary_key=True, index=True)
    bs_id = Column(Integer, ForeignKey(BasicSchedule.id))
    uic_code = Column(String(5), default=None)
    atoc_code = Column(String(2), nullable=False)
    applicable_timetable = Column(String(1), nullable=False)

class Location(Base):
    """Model of a CIF location record (LO, LI, LT)"""
    __tablename__ = 'location'

    id = Column(Integer, primary_key=True, index=True)
    bs_id = Column(Integer, ForeignKey(BasicSchedule.id))
    record_type = Column(Enum(TimingPointType), nullable=False)
    tiploc = Column(String(7), nullable=False)
    suffix = Column(Integer, default=1)
    wta = Column(String(5), default=None)
    wtp = Column(String(5), default=None)
    wtd = Column(String(5), default=None)
    platform = Column(String(3), default=None)
    line = Column(String(3), default=None)
    path = Column(String(3), default=None)
    activity = Column(String(12), default=None)
    engineering_allowance = Column(String(2), default=None)
    pathing_allowance = Column(String(2), default=None)
    performance_allowance = Column(String(2), default=None)

class ChangeEnRoute(Base):
    """Model of a Change en-route (CR) record"""
    __tablename__ = 'changes_en_route'

    id = Column(Integer, primary_key=True, index=True)
    bs_id = Column(Integer, ForeignKey(BasicSchedule.id))
    tiploc = Column(String(7), nullable=False)
    suffix = Column(Integer, default=1)
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
    uic_code = Column(String(5), default=None)
