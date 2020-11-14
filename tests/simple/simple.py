import arrow
import pendulum


def new_arrow():
    return arrow.get(2020, 1, 1)


def new_pendulum():
    return pendulum.datetime(2020, 1, 1)
