import libvirt
import json
import concurrent.futures

error_cat = r"""
 /\_/\
( o.o )
 > ^ <
""".encode()

class WindowsControlServer:
    """
    state updating

    state       isActive      updated state
    down        0             down
    starting    0             starting
    up          0             down
    down        1             up
    starting    1             up
    up          1             up
    """

    def __init__(self, libvirt_uri, libvirt_domain_name, site_url):
        self.connection = libvirt.open(libvirt_uri)
        self.domain = self.connection.lookupByName(libvirt_domain_name)
        self.site_url = site_url

        # since we are storing state in the worker, it is important
        # that we only have one wsgi worker running. This is not an
        # issue since this service will only ever be used on a local network
        # by a very small number of people. It is not designed to scale.

        self.state = "down" # "down", "starting", "up"
        self.counter = 0


        self.executor = concurrent.futures.ThreadPoolExecutor(max_workers=1)
        self.futures = []


    def update_state(self):
        isActive = self.domain.isActive()
        if isActive == 1:
            self.state = "up"

        elif self.state == "up" and isActive == 0:
            self.state = "down"

    def prepare_payload(self):
        return json.dumps({
            "counter" : str(self.counter),
            "state" : self.state }).encode()


    def __call__(self, environ, start_response):
        self.futures = [ f for f in self.futures if not f.done() ]
        self.counter += 1
        self.update_state()

        if environ['PATH_INFO'] == '/api/state':
            status = '200 OK'
            response_headers = [
                ('Content-type', 'application/json'),
                ('Access-Control-Allow-Origin', self.site_url)
            ]

            start_response(status, response_headers)
            return [self.prepare_payload()]


        elif environ['PATH_INFO'] == '/api/start':
            status = '200 OK'
            response_headers = [
                ('Content-type', 'application/json'),
                ('Access-Control-Allow-Origin', self.site_url)
            ]

            start_response(status, response_headers)

            if self.state == "down":
                self.futures.append(self.executor.submit(
                    lambda domain: domain.create(),
                    self.domain
                ))

                self.state = "starting"

            return [self.prepare_payload()]

        else:
            status = '400 Bad Request'
            response_headers = [("content-type", "text/plain")]
            start_response(status, response_headers)
            return [error_cat]


app = WindowsControlServer(
    libvirt_uri="qemu:///system",
    libvirt_domain_name = "win10",
    site_url="http://rupert.meow"
)
