""" Representation of a CIF header record"""

# pylint: disable=R0903, E0401, C0413

import enum
import sys
from sqlalchemy import Column, String, BigInteger, Integer, Enum
sys.path.insert(0, './app') # nopep8
from db.config import Base

class Status(enum.Enum):
    """Valid status enumerations"""

    TO_PROCESS = 1
    EXPIRED = 2
    PROCESSED = 3
    ERROR = 4
    OUT_OF_SEQUENCE = 5

class HeaderRecord(Base):
    """Representation of a CIF header record"""
    __tablename__ = "header_record"

    id = Column(Integer, primary_key=True, index=True)
    mainframe_identity = Column(String(20), unique=True, index=True, nullable=False)
    extract_date = Column(String(10), nullable=False)
    extract_time = Column(String(8), nullable=False)
    current_file_ref = Column(String(7), nullable=False)
    last_file_ref = Column(String(7), nullable=True)
    update_indicator = Column(String(1), nullable=False)
    version = Column(String(1), nullable=False)
    user_start_date = Column(String(10), nullable=False)
    user_end_date = Column(String(10), nullable=False)
    compressed_size = Column(BigInteger, nullable=False)
    uncompressed_size = Column(BigInteger, nullable=False)
    archive_file_name = Column(String, nullable=False)
    uncompressed_file_name = Column(String, nullable=False)
    downloaded_datetime = Column(String(19), nullable=False)
    processed_datetime = Column(String(19), default=None)
    status = Column(Enum(Status), default=Status.TO_PROCESS)
