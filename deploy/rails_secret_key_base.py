from pulumi import ResourceOptions, Output
from pulumi.dynamic import Resource, ResourceProvider, CreateResult
from typing import Optional
import binascii
import os


class RailsSecretKeyBaseProvider(ResourceProvider):
    def create(self, inputs):
        resource_id = binascii.b2a_hex(os.urandom(16)).decode("utf-8")
        key = binascii.b2a_hex(os.urandom(64)).decode("utf-8")
        return CreateResult(id_=resource_id, outs={
            'result': Output.secret(key)
        })


class RailsSecretKeyBase(Resource):
    result: Output[str]

    def __init__(self, name: str, opts: Optional[ResourceOptions] = None):
        super().__init__(RailsSecretKeyBaseProvider(), name, {'result': None}, opts)
