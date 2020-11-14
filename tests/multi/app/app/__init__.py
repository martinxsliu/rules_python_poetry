import liba
import libb
import requests
import responses


def new_datetime_a():
    return liba.new_pendulum()


def new_datetime_b():
    return libb.new_arrow()


def new_request():
    return requests.Request()


def new_response():
    return responses.Response(method="GET", url="https://www.python.org/")
