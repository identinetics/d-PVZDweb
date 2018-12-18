#!/bin/bash

cd $PROJ_HOME
python fedop/tests/load_db_with_testdata.py
python portaladmin/tests/load_db_with_testdata.py