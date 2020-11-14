import libb
import pendulum


def new_pendulum():
    arrow = libb.new_arrow()
    return pendulum.from_timestamp(arrow.timestamp)
