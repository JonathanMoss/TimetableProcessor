""" Representation of a CIF header record"""

# pylint: disable=R0903, E0401, C0413

import sys
from sqlalchemy import Column, String, Date, Time, DateTime, BigInteger, Integer
sys.path.insert(0, './app') # nopep8
from db.config import Base

class HeaderRecord(Base):
    """Representation of a CIF header record"""
    __tablename__ = "header_record"

    id = Column(Integer, primary_key=True, index=True)
    mainframe_identity = Column(String, unique=True, index=True)
    extract_date = Column(Date)
    extract_time = Column(Time)
    current_file_ref = Column(String)
    last_file_ref = Column(String)
    update_indicator = Column(String)
    version = Column(String)
    user_start_date = Column(Date)
    user_end_date = Column(Date)
    compressed_size = Column(BigInteger)
    uncompressed_size = Column(BigInteger)
    archive_file_name = Column(String)
    uncompressed_file_name = Column(String)
    downloaded_datetime = Column(DateTime)
    processed_datetime = Column(DateTime, default=None)
