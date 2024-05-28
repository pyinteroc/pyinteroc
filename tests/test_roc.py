import pytest

from roc import roc

def test_roc(capfd):
    result = roc.call_roc(10)
    out, err = capfd.readouterr()
    expected_output = "Number received!! 10"
    # Assuming the output is printed with a newline at the end, we strip it before comparing
    assert out.strip() == expected_output

    assert result == 11