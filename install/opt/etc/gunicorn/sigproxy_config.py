import os
from seclay_xmlsig_proxy_config import SigProxyConfig as Cfg

# Parameter description: see https://github.com/benoitc/gunicorn/blob/master/examples/example_config.py

bind = Cfg.host + ':' + str(Cfg.port)

access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"'
accesslog = '/var/log/sigproxy/access.log'
errorlog = '/var/log/sigproxy/error.log'
loglevel = 'info'
pidfile = '/var/run/sigproxy/gunicorn.pid'

backlog = 64
workers = 1
worker_class = 'sync'
worker_connections = 1000
timeout = 30
keepalive = 2

spew = False

daemon = True

raw_env = [
    'CSRFENCRYPTKEY=' + os.environ['CSRFENCRYPTKEY'],
    'CSRFSECRET=' + os.environ['CSRFSECRET'],
]
# raw_env.append('DEBUG=') # activate this to set workers = 1

umask = 0
user = None
group = None
