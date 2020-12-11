#!/usr/bin/env python

#load packages
import sqlite3
import glob
# List all db file names in the working dir
dbs = glob.glob('../../03processed-data/apsimxFiles/*.db')
# Loop 
for db in dbs:
    con = sqlite3.connect(db)
    mycur = con.cursor() 
    mycur.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
    (mycur.fetchall())
    mycur.close()
    con.close() 


