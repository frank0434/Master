#load packages
import sqlite3
import re
import datetime
import pandas as pd
import numpy as np
import math

# Build connection with db
con = sqlite3.connect('./Data/ProcessedData/Richard.sqlite3')
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
LAI_Height['Date'] = pd.to_datetime(LAI_Height['Clock.Today']).dt.strftime('%Y %b')

LAI = LAI_Height.pivot_table(index = 'Clock.Today', 
                    columns=['Experiment', 'SowingDate'],
                    values = 'LAImod')
# Change the index to datetime tyep
LAI.index = pd.to_datetime(LAI.index)
# Rename the index name 
LAI.index.name = 'Clock.Today'
# Normalise the datetime to midnight 
LAI.index = LAI.index.normalize()

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

sowingdates = pd.read_sql('Select * from SowingDates',  con)
sowingdates.AD = pd.to_datetime(sowingdates.AD)
sowingdates.I12 = pd.to_datetime(sowingdates.I12)
# set index and rename columns 
sowingdates.set_index('SD', inplace=True)
sowingdates.columns = ['AshleyDene', 'Iversen12']

# +
LAIAD = LAI.filter(regex = 'Ashley')
#Reindex coverdata frame to daily values
TTAccumAD = met.loc[(met['Experiment'] == 'AshleyDene')
                    & (met.index > '2010-10-01'), 'mean'].cumsum()
TTAccumAD.index = pd.to_datetime(TTAccumAD.index)

LAIDailyAD = LAIAD.reindex(TTAccumAD.index)
LAIDailyAD.loc[:, 'AccumTT'] = TTAccumAD

# Force LAI to be zero
for sd in sowingdates.index:
    # Select the date for correpond sowing date
    date0 = sowingdates.at[sd, 'AshleyDene']
    # A slicer
    idx = pd.IndexSlice
    # Replace the row values with 0s
    LAIDailyAD.loc[LAIDailyAD.index <= date0, idx[:,sd]] = float(0.001)
    # Verification 
    df = LAIDailyAD.loc[LAIDailyAD.index == date0, idx[:,sd]]
for p in LAIDailyAD.columns:
    Obs = LAIDailyAD.loc[:,p].dropna()
    LAIDailyAD.loc[:,p] = np.interp(LAIDailyAD.AccumTT,
                                   LAIDailyAD.loc[Obs.index,'AccumTT'],Obs)
# -

LAIGroupedMeanADForced = LAIDailyAD.groupby(axis=1, level=['Experiment', 'SowingDate']).mean()

# +
LAII12 = LAI.filter(regex = 'Ive')

TTAccumI12 = met.loc[(met['Experiment'] == 'Iversen12')
                      & (met.index > '2010-10-01'), 'mean'].cumsum()
TTAccumI12.index = pd.to_datetime(TTAccumI12.index)
LAIDailyI12 = LAII12.reindex(TTAccumI12.index)  #Reindex coverdata frame to daily values
LAIDailyI12.loc[:,'AccumTT'] = TTAccumI12
for sd in sowingdates.index:
    # Select the date for correpond sowing date
    date0 = sowingdates.at[sd, 'Iversen12']
    # A slicer
    idx = pd.IndexSlice
    # Replace the row values with 0s
    LAIDailyI12.loc[LAIDailyI12.index <= date0, idx[:,sd]] = float(0.001)
    # Verification 
    df = LAIDailyI12.loc[LAIDailyI12.index == date0, idx[:,sd]]
#     print(df)
# Interpolate LAI daily value by thermal time 
for p in LAIDailyI12.columns:
    Obs = LAIDailyI12.loc[:,p].dropna()
    LAIDailyI12.loc[:,p] = np.interp(LAIDailyI12.AccumTT,
                                   LAIDailyI12.loc[Obs.index,'AccumTT'],Obs)
LAIGroupedMeanI12Forced = LAIDailyI12.groupby(axis=1, level=['Experiment', 'SowingDate']).mean()
# -

# Stack them together
CoverDFAD = LAIGroupedMeanADForced.drop('AccumTT', axis=1, level=0).stack([0,1]).reset_index()
CoverDFI12 = LAIGroupedMeanI12Forced.drop('AccumTT', axis=1, level=0).stack([0,1]).reset_index()
CoverDF = pd.concat([CoverDFAD, CoverDFI12], ignore_index = True )

CoverDF.columns = ['Clock.Today', 'Experiment', 'SowingDate', 'LAImod']
# Add the k for all 
CoverDF['k'] = 0.94
# Replace the k for the summur crop in Ashley Dene
CoverDF.loc[(CoverDF['Clock.Today'] > '2011-11-30') 
               & (CoverDF['Clock.Today'] < '2012-03-01') 
               & (CoverDF['Experiment'] == 'AshleyDene'), 'k'] = 0.66
CoverDF['LI'] = 1 - np.exp( - CoverDF['k'] * CoverDF['LAImod'])

SDs = ['SD' + str(SD) for SD in range(1, 11)]
Sites = ['AshleyDene', 'Iversen12']
for i in SDs:
    for j in Sites:
        CoverDF.loc[(CoverDF['Experiment'] == j)
                    & (CoverDF['SowingDate'] == i),
                    ['Clock.Today', 'LAImod', 'k']].\
        to_csv('./Data/ProcessedData/CoverData/LAI' + j + i + '.csv',index = False)

SDs = ['SD' + str(SD) for SD in range(1, 11)]
SDs
for i in SDs:
    for j in Sites:
        CoverDF.loc[(CoverDF['Experiment'] == j)
                    & (CoverDF['SowingDate'] == i),
                      ['Clock.Today', 'LI']]. \
        to_csv('./Data/ProcessedData/CoverData/Cover' + i + j + '.csv',index = False)

# # Process observation data into treatment excels 

import xlsxwriter
df = pd.read_excel('./Data/ProcessedData/20200630Whole.xlsx')
df['SimulationName'] = 'Experiment'
for i in Sites:
    for j in SDs:
        sitesd = df.loc[(df['Experiment'] == i) 
                        & (df['SowingDate'] == j)]

        # Create a Pandas Excel writer using XlsxWriter as the engine.
        writer = pd.ExcelWriter('./Data/ProcessedData/CoverData/Observation' + i + j + '.xlsx', engine='xlsxwriter') 
        # Convert the dataframe to an XlsxWriter Excel object.
        sitesd.to_excel(writer, sheet_name='Observed', index = False)
        # Close the Pandas Excel writer and output the Excel file.
        writer.save()

# CoverDF
