"""Representation of a CIF header record"""

#pylint: disable=R0903, E0401

from datetime import datetime
import re
from typing import Union, List
import pydantic

DATETIME = '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'

class RequestBodyModel(pydantic.BaseModel):
    """Representation of a CURL request body"""
    csv_line: str

class Header(pydantic.BaseModel):
    """Representation of a CIF header record"""

    model_config = pydantic.ConfigDict(from_attributes=True)

    mainframe_identity: str = pydantic.Field(
        title='File Mainframe Identity',
        pattern="^[A-Z]{3}.[A-Z0-9]{7}.[A-Z0-9]{8}$"
    )

    extract_date: str = pydantic.Field(
        title='Date of Extract'
    )

    extract_time: str = pydantic.Field(
        title='Time of Extract'
    )

    current_file_ref: str = pydantic.Field(
        title='Current File Reference',
        pattern="^[A-Z0-9]{6}[A-Z]{1}$"
    )

    last_file_ref: Union[str, None] = pydantic.Field(
        title='Last File Reference',
        default=None
    )

    update_indicator: str = pydantic.Field(
        title='Update Indicator',
        pattern="^[UF]{1}$"
    )

    version: str = pydantic.Field(
        title='Version',
        pattern="^[A-Z]{1}$"
    )

    user_start_date: str = pydantic.Field(
        title='CIF First Date'
    )

    user_end_date: str = pydantic.Field(
        title='CIF Last Date'
    )

    compressed_size: int = pydantic.Field(
        title='Compressed File Size'
    )

    uncompressed_size: int = pydantic.Field(
        title='Uncompressed File Size'
    )

    archive_file_name: str = pydantic.Field(
        title='Downloaded (Compressed) file name',
        pattern="^[A-Za-z0-9-._]+.gz"
    )

    uncompressed_file_name: str = pydantic.Field(
        title='Uncompressed File Name',
        pattern="^[A-Z0-9]+.CIF"
    )

    downloaded_datetime: str = pydantic.Field(
        title='Downloaded Datetime',
        pattern=f"^{DATETIME}$"
    )

    processed_datetime: Union[str, None] = pydantic.Field(
        title='Processed Datetime',
        default=None
    )

    @pydantic.field_validator('*', mode='before')
    @classmethod
    def format_all(cls, value: Union[str, None]) -> Union[str, None]:
        """Formatting for all fields"""
        return value.strip()

    @pydantic.field_validator('processed_datetime')
    @classmethod
    def validate_datetime(cls, value: Union[str, None]) -> Union[str, None]:
        """Validate/Format datetimes"""
        if not value:
            return None
        match = re.match(f'{DATETIME}', value)
        if not match:
            raise ValueError(
                f'Invalid DateTime: {value}'
            )
        return match[0]

    @pydantic.field_validator('last_file_ref')
    @classmethod
    def validate_last_file_reference(cls, value: Union[str, None]) -> Union[str, None]:
        """Format the Last File Reference"""
        if not value:
            return None
        if not re.match('[A-Z0-9]{6}[A-Z]{1}', value):
            raise ValueError(
                f'Invalid Last File Reference: {value}'
            )
        return value

    @pydantic.field_validator('extract_time')
    @classmethod
    def format_extract_time(cls, value: Union[str, None]) -> Union[str, None]:
        """Format the extract time"""
        if not value:
            return None
        if not re.match('[0-9]{4}', value):
            raise ValueError(
                f'Invalid Extract Time: {value}'
            )
        return str(datetime.strptime(value, '%H%M').time())

    @pydantic.field_validator('extract_date', 'user_start_date', 'user_end_date')
    @classmethod
    def format_extract_date(cls, value: Union[str, None]) -> Union[str, None]:
        """Format the extract date"""
        if not value:
            return None
        if not re.match('[0-9]{6}', value):
            raise ValueError(
                f'Invalid Extract Date: {value}'
            )
        return str(datetime.strptime(value, '%d%m%y').date())

    @staticmethod
    @pydantic.validate_call
    def factory(values: Union[List[str], str]) -> object:
        """Create a Header Object from a list of csv values/csv string"""
        if isinstance(values, str):
            values = values.split(',')
        if len(values) < 14:
            raise ValueError
        params = {
            'mainframe_identity': values[0],
            'extract_date': values[1],
            'extract_time': values[2],
            'current_file_ref': values[3],
            'last_file_ref': values[4],
            'update_indicator': values[5],
            'version': values[6],
            'user_start_date': values[7],
            'user_end_date': values[8],
            'compressed_size': values[9],
            'uncompressed_size': values[10],
            'archive_file_name': values[11],
            'uncompressed_file_name': values[12],
            'downloaded_datetime': values[13]
        }

        if len(values) > 14:
            params['processed_datetime'] = values[14]

        return Header(**params)
