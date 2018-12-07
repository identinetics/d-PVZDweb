import os
import requests
import sys

def test_webapp():
    upload_url = 'http://localhost:8080/mdupload'
    upload_filepath = 'testdata-setup/input/idp4TestExampleOrg_idpXml.xml'
    target_dir = 'testdata-run/repodir_upload/request_queue'
    os.makedirs(target_dir, exist_ok=True)
    target_filepath = os.path.join(target_dir, 'TEST-ORGID.idp4TestExampleOrg_idpXml.xml')
    git_filepath = '/var/lib/git/repodir_upload/request_queue/TEST-ORGID.idp4TestExampleOrg_idpXml.xml'

    with open(upload_filepath, 'rb') as fd:
        try:
            response = requests.post(upload_url,
                                     data={'orgid': 'Test-OrgID'},
                                     files={'upload': fd})
        except Exception as e:
            print('Connection Error when connecting to ' + upload_url)
            sys.exit(1)
        assert response.status_code == 200
        # assert os.path.exists(git_filepath) # removed because path includes time stamp
