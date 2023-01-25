import subprocess

def run(environ, start_response):
    status = '200 OK'
    response_headers = [('Content-type', 'text/plain')]
    start_response(status, response_headers)
    if environ['QUERY_STRING'] == 'status':
        result = subprocess.check_output(['/bin/windows', 'status'])
        return [result]
    elif environ['QUERY_STRING'] == 'start':
        result = subprocess.check_output(['/bin/windows', 'start'])
        return [result]
    else:
        return [b'usage: url?status or url?start']
