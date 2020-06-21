# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:light
#     text_representation:
#       extension: .py
#       format_name: light
#       format_version: '1.5'
#       jupytext_version: 1.4.2
#   kernelspec:
#     display_name: Python 3
#     language: python
#     name: python3
# ---

#load packages
import sqlite3
import glob
# List all db file names in the working dir
dbs = glob.glob('./03processed-data/apsimxFilesLayers/*.db')
# Loop 
for db in dbs:
    con = sqlite3.connect(db)
    mycur = con.cursor() 
    mycur.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
    (mycur.fetchall())
    mycur.close()
    con.close() 
