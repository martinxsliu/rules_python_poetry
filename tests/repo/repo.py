import pandas as pd
import pendulum


def new_pendulum():
    return pendulum.datetime(2020, 1, 1)


def new_series():
    return pd.Series([1, 2, 3])
