

# General tips and tricks 

It is very common to have SWC varies over different treatment.   
Simply meaning that the soil parameters for different treatment are probably different as well.  

One way to hack it:  
Set up a workflow that can extract key parameters `DUL`, `LL`, `initial SWC` from raw data to parameterise the `[Physical]` node for each treatment. Use the factor node and manager to replace the node for each treatment. 

Two and half sets of parameters to have:
  - below ground: DUL LL and initial swc   
  - midde: kl
  - above groud: `[Lucerne].Leaf.Fw` to have the water stress effect in. 
  
XYPairs must have two children nodes: `XYPairs` and `=XYValue`   


# Phase one:   
Input parameter extracted from analysing the SWC data.  `DUL` `LL` `Initial SWC`
_Note_: use quantile to have the `DUL` and `LL` probably a robust way to go. 

This is the necessary phase to have a deep understanding about the SWC in different soil types and for different crops. 
Will be a chapter of the thesis. 

Things need to be confirmed:  
 - Data sets are going to be used.  
    Richards 10 sowing date  
    Lucerne and pasture    
    Maxlucerne and MaxClover (still need to liasion with Anna)  


# Phase two:   
KL to figure out the interaction between plant uptake and water supply.   
The _kls_ needs to extract from the detailed layer by layer VWC measurements.  

Some thoughts around this phase  

Slurp could be handy to help investigate the best fit kl since we can fix the cover.  
Feed the best fit _kls_ back to `Lucerne` model to examine if the _kls_ can give us the right cover in the model.  


# Phase three: 
The lucerne response to the water stress (ration between demand and supply).  


# Where to next:

Phase one: 
  
Get familiar with the apsimx UI and how to examine variables. e.g. Use UI to examine the layer by layer simulation vs observation - _Can be automated in Python/R_
Ways to automate the data analysis to have the parameters from SWC data.   

Dug deeper about the json manipulation for apsimx files:  
1. Python approach    
2. Edit feature in apsimNG  






 