import pytest

def setup_function(function):
    print('__name__=' + __name__)

def test_dummy():
    assert 1 == 2
