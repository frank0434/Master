---
Title: "Summary of 2th April meeting and 31st March catch up with Hamish"

---


There are two types of parameters to calibrate an Apsim model:   
  - Input parameters that define the boundaries and initial conditions for the model. 
    These are drained upper limite (`DUL`), lower limite (`LL`) and `Initial SWC`.  
  - Fitted parameters that best fit of observed data.  
    Can be a range of different parameters. Typical ones like water stress factor (`Fw`) for leaf area expansion rate and radiation use efficiency.   
  _Note_: kl (the parameter describes how much percentage of water in each soil layer are avaiable to the plant per day) is a special one that can be extracted from observed data as a input parameter while can be a fitted parameter. 
  
The first step, therefore, will be extracting input parameters via robust statistic approach. 

# Phase one - re-analysis and automation:

Input parameter extracted from analysing the SWC data.  `DUL` `LL` `Initial SWC`. 
Plot by Plot data analysis could be helpful to illustrate the variations. 

This is the necessary phase to have a deep understanding about the SWC variations.  
A package associated with unit test would be useful to make the analysis future proof. 

Will be a chapter of the thesis.  
The analysis and automation of soil water content will contribute to ask questions around soil physics and associated biology. 



# Phase two - working on the fitted parameters:  

This phase has to be built upon the first phase since it will be incorrect if input parameters are off.  

KL to figure out the interaction between plant uptake and water supply.   

Two ways to have parameter _kl_:  
1. To extract from the detailed layer by layer VWC measurements.  
2. To optimised it from observed data via simple models like `APSIM-SLURP` 

Some thoughts around this phase  

Slurp could be handy to help investigate the best fit kl since we can fix the leaf cover.  
Feed the best fit _kls_ back to `Lucerne` model to examine if the _kls_ can provide the right cover in the model.  


# Phase three - calibrate more fitted parameters: 

The lucerne response to the water stress in growth and development.  

Water stress will hit the plants as following sequence:  
1. Leaf expansion.  
2. Radiation use efficiency.  
3. Development such as phyllochron and branching.  


# Immdediate actions:

Phase one: 

Initial an analysis of SWC data to have a better understanding of the biology and potential applicable models.  
Further actions will be finding ways to automate the data analysis and model fitting in R.   

Get familiar with the apsimx UI and how to modify and examine variables manually.
e.g. Use UI to examine the layer by layer simulation vs observation 

Further actions will be automating the process in Python/R. 
This step will dug deeper about the json manipulation for apsimx files:  
1. Python approach - dictionary key:value pair
2. Built in `Edit` feature in apsimNG  



# General tips and tricks 

It is very common to have SWC varies over different places.   
Simply meaning that the soil parameters for different treatment/plot are probably different as well due to the sapital variations.  

One way to hack it:  
Set up a workflow that can extract key parameters `DUL`, `LL`, `initial SWC` from raw data to parameterise the `[Physical]` node for each treatment. Use the factor node and manager to replace the node for each treatment. 

Two and half sets of parameters to have:
  - below ground: DUL LL and initial swc   
  - midde: kl
  - above groud: `[Lucerne].Leaf.Fw` to have the water stress effect in. 
  
XYPairs must have two children nodes: `XYPairs` and `=XYValue`   




 