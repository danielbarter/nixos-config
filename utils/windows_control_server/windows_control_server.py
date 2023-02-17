import subprocess
import os

class WindowsControlServer:

    def __init__(self):
        self.count = 0

    def __call__(self, environ, start_response):
        self.count += 1
        status = '200 OK'
        response_headers = [('Content-type', 'text/plain')]
        start_response(status, response_headers)
        counter = f'counter: {self.count}\n\n\n'.encode()
        if environ['QUERY_STRING'] == 'status':
            result = subprocess.check_output(['windows', 'status'])
            return [counter, result]
        elif environ['QUERY_STRING'] == 'start':
            result = subprocess.check_output(['windows', 'start'])
            return [counter, result]
        else:
            return [b'usage: url?status or url?start']


run = WindowsControlServer()
