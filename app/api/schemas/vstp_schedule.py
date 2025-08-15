"""Representation if a VSTP Schedule"""

import pydantic
from typing import Union

class BasicSchedule(pydantic.BaseModel):
    """Representation of a BS record for a VSTP record"""
    
    model_config = pydantic.ConfigDict(from_attributes=True)
    
    transaction_type: str = pydantic.Field(
        title='transaction_type',
        pattern="^[NDR]{1}$"
    )
    
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
    
    @pydantic.field_validator('*', mode='before')
    @classmethod
    def format_all(cls, value: Union[str, None]) -> Union[str, None]:
        """Formatting all fields"""
        return value.strip()