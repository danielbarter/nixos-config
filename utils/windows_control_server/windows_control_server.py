import subprocess

def run(environ, start_response):
    status = '200 OK'
    response_headers = [('Content-type', 'text/plain')]
    start_response(status, response_headers)
    if environ['QUERY_STRING'] == 'status':
        result = subprocess.check_output(['windows', 'status'])
        return [result.encode('ascii')]
    elif environ['QUERY_STRING'] == 'start':
        result = subprocess.check_output(['windows', 'start'])
        return [result.encode('ascii')]
    else:
        return [b'usage: url?status or url?start']
