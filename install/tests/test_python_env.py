''' verify if all packages in requirements.txt in the current python interpreter are installed
    requirements.txt is either passed as arg, or by default searched in the parent directory of this script
'''
from pathlib import Path
import re
import sys
try:
    from pip._internal.operations import freeze
except ImportError:  # pip < 10.0
    from pip.operations import freeze

if len(sys.argv) == 1:
    path = Path(__file__).parents[1] / 'requirements.txt'
else:
    path = Path(sys.argv[1])
try:
    requirements_txt = path.open().readlines()
except Exception as e:
    print('Cannot open requirements.txt: %s\nThe file must be passed as argument or reside in the parent directory of the script.' % str(e))
    sys.exit(2)
pip_freeze = []
for p in freeze.freeze():
    p = p.replace('-', '_').lower()  # PEP426
    pip_freeze.append(p.split('==')[0])

rc = 0
for l in requirements_txt:
    l = l.strip()
    p = re.split(r'[=<>]', l)[0]
    p = p.replace('-', '_').lower()  # PEP426
    if p == '':
        continue
    if p.startswith('#'):
        continue
    if p in pip_freeze:
        continue
    rc = 1
    print('Required package {} missing'.format(p))
sys.exit(rc)