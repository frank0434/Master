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
import re
import datetime
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import math

# Build connection with db
con = sqlite3.connect('./03processed-data/Richard.sqlite3')
mycur = con.cursor() 
mycur.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
# Read data in 
biomass = pd.read_sql('Select * from biomass',  con)
met_AD = pd.read_sql('Select * from met_AshleyDene', con)
met_I12 = pd.read_sql('Select * from met_Iversen12', con)

LAI_Height = biomass.loc[(biomass['Seed'] == 'CS')
                         & (biomass['Harvest.No.']!='Post'), 
                         ['Experiment', 'Clock.Today', 'SowingDate', 'Rep',
                          'Plot', 'Rotation.No.', 'Harvest.No.', 'Height','LAImod']]
# Plot that had 'Post' measurement should be out 
LAI_Height[(LAI_Height['Harvest.No.'] == 'Post') & (LAI_Height.LAImod==0)]
# Add the k for all 
LAI_Height['k'] = 0.94
# Replace the k for the summur crop in Ashley Dene
LAI_Height.loc[(LAI_Height['Clock.Today'] > '2011-11-30') 
               & (LAI_Height['Clock.Today'] < '2012-03-01') 
               & (LAI_Height['Experiment'] == 'AshleyDene'), 'k'] = 0.66
LAI_Height['Date'] = pd.to_datetime(LAI_Height['Clock.Today']).dt.strftime('%Y %b')

# ### Output LAI as the slurp input 

SDs = ['SD' + str(SD) for SD in range(1, 11)]
SDs
sites = ['AshleyDene', 'Iversen12']
for site in sites: 
    for i in SDs:
        LAI_Height.loc[(LAI_Height['Experiment'] == site) & (LAI_Height.SowingDate == i),
                       ['Clock.Today', 'LAImod','k']].to_csv('./03processed-data/CoverData/LAI' + site + i + '.csv',index = False)

LAI_Height['LI_frac'] = 1 - np.exp( - LAI_Height['k'] * LAI_Height['LAImod'])

# +
# Select only LI column
LI = LAI_Height.loc[:, ['Experiment', 'Clock.Today','SowingDate', 
                        'Rep', 'Plot', 
                        'LI_frac']]
# print_full(LI)
# remove the rows that have 0S - Likely to be wrong 0s
LI = LI[LI['LI_frac'] != 0.00]
LI = LI.pivot_table(index = 'Clock.Today', 
                    columns=['Experiment', 'SowingDate', 
                             'Rep', 'Plot'],
                    values = 'LI_frac')

# Change the index to datetime tyep
LI.index = pd.to_datetime(LI.index)
# Rename the index name 
LI.index.name = 'Clock.Today'
# Normalise the datetime to midnight 
LI.index = LI.index.normalize()

# -

LIGroupedMean = LI.groupby(axis=1, level=['Experiment', 'SowingDate']).mean()

# +
# Met data to calculate thermal time
# -

met_AD = met_AD.loc[:, ['year','day', 'maxt', 'mint','mean']]
met_AD['Experiment'] = 'AshleyDene'
met_I12 = met_I12.loc[(met_I12['year'] >= 2010)                       
                      & (met_I12['year'] < 2013), ['year','day', 'maxt', 'mint','mean']]
met_I12['Experiment'] = 'Iversen12'
met = pd.concat([met_AD, met_I12], ignore_index=True)
# Change 4 digits year to the first date of the year
met['year'] = [str(year) + '-01-01' for year in met['year']]
met['year'] = pd.to_datetime(met['year'])
# Change the day to a delta days and add back to the year 
met['Clock.Today'] = met['year'] + pd.to_timedelta(met['day'], unit='D')
met = met[(met['Clock.Today'] > '2010-06-01')
          &(met['Clock.Today'] < '2012-08-01')]
# indexing 
met.set_index('Clock.Today', inplace = True)
# Try 2 sites the same time 
ThermalTimeAccum = met.loc[:, 'mean'].cumsum()
ThermalTimeAccum.index = pd.to_datetime(ThermalTimeAccum.index)
#Reindex coverdata frame to daily values
LIDaily = LI.reindex(ThermalTimeAccum.index)
LIDaily.loc[:, 'AccumTT'] = ThermalTimeAccum
# CoverDataDaily.loc[:,'AccumTT'] = ThermalTimeAccum

sowingdates = pd.read_sql('Select * from SowingDates',  con)
sowingdates.AD = pd.to_datetime(sowingdates.AD)
sowingdates.I12 = pd.to_datetime(sowingdates.I12)
# set index and rename columns 
sowingdates.set_index('SD', inplace=True)
sowingdates.columns = ['AshleyDene', 'Iversen12']

# +
LIAD = LI.filter(regex = 'Ashley')
#Reindex coverdata frame to daily values
TTAccumAD = met.loc[(met['Experiment'] == 'AshleyDene')
                    & (met.index > '2010-10-20'), 'mean'].cumsum()
TTAccumAD.index = pd.to_datetime(TTAccumAD.index)

LIDailyAD = LIAD.reindex(TTAccumAD.index)
LIDailyAD.loc[:, 'AccumTT'] = TTAccumAD

for sd in sowingdates.index:
    # Select the date for correpond sowing date
    date0 = sowingdates.at[sd, 'AshleyDene']
    # A slicer
    idx = pd.IndexSlice
    # Replace the row values with 0s
    LIDailyAD.loc[LIDailyAD.index <= date0, idx[:,sd]] = float(0.001)
    # Verification 
    df = LIDailyAD.loc[LIDailyAD.index == date0, idx[:,sd]]
for p in LIDailyAD.columns:
    Obs = LIDailyAD.loc[:,p].dropna()
    LIDailyAD.loc[:,p] = np.interp(LIDailyAD.AccumTT,
                                   LIDailyAD.loc[Obs.index,'AccumTT'],Obs)
# -

LIGroupedMeanADForced = LIDailyAD.groupby(axis=1, level=['Experiment', 'SowingDate']).mean()

# +
LII12 = LI.filter(regex = 'Iver')
#Reindex coverdata frame to daily values
TTAccumI12 = met.loc[(met['Experiment'] == 'Iversen12')
                    & (met.index > '2010-10-03'), 'mean'].cumsum()
TTAccumI12.index = pd.to_datetime(TTAccumI12.index)

LIDailyI12 = LII12.reindex(TTAccumI12.index)
LIDailyI12.loc[:, 'AccumTT'] = TTAccumI12
for sd in sowingdates.index:
    # Select the date for correpond sowing date
    date0 = sowingdates.at[sd, 'Iversen12']
    # A slicer
    idx = pd.IndexSlice
    # Replace the row values with 0s
    LIDailyI12.loc[LIDailyI12.index <= date0, idx[:,sd]] = float(0.001)
#     # Verification 
    df = LIDailyI12.loc[LIDailyI12.index == date0, idx[:,sd]]
#     print(df)
for p in LIDailyI12.columns:
    Obs = LIDailyI12.loc[:,p].dropna()
    LIDailyI12.loc[:,p] = np.interp(LIDailyI12.AccumTT,
                                   LIDailyI12.loc[Obs.index,'AccumTT'],Obs)
LIGroupedMeanI12Forced = LIDailyI12.groupby(axis=1, level=['Experiment', 'SowingDate']).mean()
# -

CoverDF = LIGroupedMeanADForced.drop('AccumTT', axis=1, level=0).stack([0,1]).reset_index()
CoverDFI12 = LIGroupedMeanI12Forced.drop('AccumTT', axis=1, level=0).stack([0,1]).reset_index()
CoverDF.columns = ['Date', 'Experiment', 'SowingDate', 'LightInterception']
CoverDFI12.columns = ['Date', 'Experiment', 'SowingDate', 'LightInterception']
CoverDF = pd.concat([CoverDF,CoverDFI12], axis=0)

# Add the k for all 
CoverDF['k'] = 0.94
# Replace the k for the summur crop in Ashley Dene
CoverDF.loc[(CoverDF['Date'] > '2011-11-30') 
               & (CoverDF['Date'] < '2012-03-01') 
               & (CoverDF['Experiment'] == 'AshleyDene'), 'k'] = 0.66

# Output the coverData with k values 
SDs = ['SD' + str(SD) for SD in range(1, 11)]
SDs
for i in sites:
    for j in SDs:
        CoverDF.loc[(CoverDF['SowingDate'] == j)
                    & (CoverDF['Experiment'] == i),
                    ['Date', 'LightInterception','k']]. \
        to_csv('./03processed-data/CoverData/CoverData' + i + j + '.csv', index = False)

# CoverDF
