"""Tests for schemas/cif_header.py"""

# pylint: disable=E0401, C0116, C0413, C0115, W0621, R0903

import sys
import pytest
import pydantic
sys.path.insert(0, './app') # nopep8
from schemas import cif_header


@pytest.fixture
def return_header_from_csv():
    with open('app/tests/test_data/header_inf.csv', '+r', encoding='utf-8') as file:
        csv = file.read().splitlines()
        return csv

class TestHeader:
    def test_factory_from_bad_list(self):
        with pytest.raises(pydantic.ValidationError):
            cif_header.Header.factory()

        tmp = list(range(0, 15))
        with pytest.raises(pydantic.ValidationError):
            cif_header.Header.factory(tmp)

    def test_factory_from_string(self, return_header_from_csv):
        tmp = return_header_from_csv[0]
        tmp = cif_header.Header.factory(tmp)
        assert isinstance(tmp, cif_header.Header)

    def test_factory_from_list(self, return_header_from_csv):
        tmp = return_header_from_csv[0].split(',')
        tmp = cif_header.Header.factory(tmp)

    def test_multiple(self, return_header_from_csv):
        for csv_line in return_header_from_csv:
            tmp = cif_header.Header.factory(csv_line)
            assert isinstance(tmp, cif_header.Header)


    def test_with_proc_date(self, return_header_from_csv):
        tmp = return_header_from_csv[0]
        tmp = f'{tmp},2023-11-03 17:00:45'
        tmp = cif_header.Header.factory(tmp)
        assert isinstance(tmp, cif_header.Header)
        assert tmp.processed_datetime == '2023-11-03 17:00:45'
