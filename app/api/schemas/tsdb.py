"""Representations of CIF TSDB objects"""

# pylint: disable=E0401, R0903

import pydantic

class ImportCIFPayloadBody(pydantic.BaseModel):
    """Representation of a CURL request to import CIF files"""
    bs: str
    bx: str
    lo: str
    cr: str
    