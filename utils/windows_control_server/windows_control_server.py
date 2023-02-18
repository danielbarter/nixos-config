import libvirt
import json

error_cat = r"""
 /\_/\
( o.o )
 > ^ <
""".encode()

class WindowsControlServer:

    def __init__(self, libvirt_uri, domain_name):
        self.connection = libvirt.open(libvirt_uri)
        self.domain = self.connection.lookupByName(domain_name)
        self.hit_count = 0


    def prepare_payload(self):
        state = "shutdown"
        if self.domain.isActive():
           state = "running"

        return json.dumps({ "hit_count" : self.hit_count, "state" : state }).encode()

    def __call__(self, environ, start_response):
        self.hit_count += 1

        if environ['PATH_INFO'] == '/api/status':
            status = '200 OK'
            response_headers = [
                ('Content-type', 'application/json'),
                ('Access-Control-Allow-Origin', 'http://rupert.meow')
            ]
            start_response(status, response_headers)
            return [self.prepare_payload()]


        elif environ['PATH_INFO'] == '/api/start':
            status = '200 OK'
            response_headers = [
                ('Content-type', 'application/json'),
                ('Access-Control-Allow-Origin', 'http://rupert.meow')
            ]
            start_response(status, response_headers)
            try:
                self.domain.create()
            except:
                pass

            return [json.dumps({}).encode()]

        else:
            status = '400 Bad Request'
            response_headers = [("content-type", "text/plain")]
            start_response(status, response_headers)
            return [error_cat]


app = WindowsControlServer(
    libvirt_uri="qemu:///system",
    domain_name = "win10"
)
