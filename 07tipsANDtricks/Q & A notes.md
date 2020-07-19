## 20200510
How to calculate initial soil water and parameterise it? 

Should I use one PAWC_profile for all treatment 
Experiment  SowingDate PAWC_profile
AshleyDene	SD1	1.3547361		
AshleyDene	SD2	1.3929496		
AshleyDene	SD3	1.3967832		
AshleyDene	SD4	1.3548853		
AshleyDene	SD5	1.3266429		
AshleyDene	SD6	0.8305323		
AshleyDene	SD7	0.9312899		
AshleyDene	SD8	0.7833570		
AshleyDene	SD9	0.7485258		
AshleyDene	SD10	0.7726116		

ask richard how did he calculate the DUL AND LL AND initial soil water? 
ask Hamish/Rog about the parameterisation? 


DUL and LL should be depend on soil 
SWD should be refered to DUL 


2. Initial Soil Water as a Fraction of Available Soil Water distributed evenly
down the profile

Initial soil water can be set to a fraction of the maximum available soil water
in each layer. Setting the insoil parameter to a fraction (0 = LL15, 1 = DUL)
initialises the soil water parameter (initial sw values are ignored) to this
fraction for each layer.

ie. If 0.0 <= Insoil <= 1.0, then
in each layer
Soil water (sw) = LL15 + ((DUL-LL15) x Insoil)
5. Initial Soil Water as a depth of wet soil, filled to field capacity.

Initial soil water can be set to a depth of wet soil. The profile is filled from
the top down until the soil depth is reached. Setting the wet_soil_depth
parameter to a depth of soil filled to field capacity (DUL) initialises the soil
water for layers starting at the top of the profile to DUL, until the soil depth
is reached. The remaining layers are set to LL15. This parameter is exclusive of
the others.

e.g. Using the soil parameters of the previous example and
wet_soil_depth = 400 mm,
Then
The ESW of each layer is set to 33, 33, 21, 0 mm giving
A total of 87 mm in the profile.

TO set up the initial soil water content for each layer:
.Simulations.New Zealand.AshleyDene.AshleyDene.paddock.AshleyDene Lismore very stony silt Loam.Initial nitrogen.SW 

20200513
Hamish
To use the SW for initial soil water, delete the initial soil water node 
DUL and LL can be depend on sowing dates since APSIM is a point based model. 

Hamish 
kl should be link to the root turnover?? 
yes. but it can't be dynamic to reflect the real world stuiation in NZ since the
cold temperature could limit the crop water uptake. why we can't make the kl
calculated on the fly? monthly value probably the best you could have but
suspect that it still won't reflect the real world senarios.

Slurp is probably the best way to go so far, since it accounts the incomplete
canopy and tempareture. curving fitting is not recommended since the assumptions
are very easy to be violated in NZ.


Rog:
elimate the rainfall event for looking the decay of the kls 

swcon is very similar to kls 

filter out the noise to get the 
filter out the period full canopy cover without rainfall 

questions to Richard: 
	1. what happen during the winter - crop is full canopy? 
	2. 


How are you guys doing in the bubbles? 

I started to do apsimx parameterisation for the lucerne model and have a few
questions about how did you calculate the values for soil parameters. Hamish and
I did a diagnosis session for the current lucerne model in apsimx. He suggested
we need to have 10 sets of soil water conditions for the 10 sowing dates to
capture the real water movements. So I started to re-analysis your data and hope
I can automate the process and apply it to other datasets. Before that, I reckon
that I have to understand the way of obtaining the DUL and LL.

2 key questions are :
1.	Wondering if you used all data for all sowing dates to have the DUL and LL or
just the first 5 sowing dates?
Yes – I calculated/estimated specific values for DUL and LL for all plots, and
layers within plots. This was required because although the trial area was
relatively small, there was considerable variation among plots with changing
soils types. Probably more in Iversen 12 due to highly variable depth and size
of sand layers.

I wasn’t sure if I need to use all points and checked your thesis. You mentioned
that DUL in section 6.2.1.5 and it was from a fallowed plots?
Yes – basically what I did was graph up the soil water content of each layer
over time and looked for periods during winter when I knew that there had been a
heavy rainfall and very little crop water use - consistent soil water content
indicated the layer was at DUL and excess was drainage. Further to this was the
areas I sowed in the second year, I chemically fallowed for the prior season –
they received ~600 mm of rainfall and no crop extraction. Soil water
measurements of these were compared with the method above and they lined up.

2.	How did you calculate the initial soil water content? 
Current I use the value from the nearest date to sowing dates for initial soil
wate content, not sure if this is what you used?
Generally, I tried to install the neutron probes soon after sowing and took
readings. But not always. However, I did install the TDR rods. Therefore, prior
to neutron probe readings I assumed water was only lost from the top layer and
the lower layers would have been consistent with the neutron probe readings when
I managed to get them in. there may of ben 1 or 2 cases when the initial water
just did not fit, and would through out the whole water balance, therefore I
‘fined tuned’ the initial water to fit the dry down pattern.


I averaged the SWC profile across 4 reps in AD and plotted out over time by 10
sowing dates. The blue line is the max SWC and the red is min SWC for all
points.

Looks good – however I suspect that each SD will have slightly different values
because of the variation in soil. For examples the DUL looks slightly too high,
and the LL slightly too low for SD1. For the crops sown in year two I would use
an average LL – because the crops were not fully established they did not reach
a terminal drought situation and extract all the water from whole profile. You
can see from SD6 to 10, the depth of max extraction was progressively less.

Interestingly, the first measured point in SD6-10 seems low. These plots had
been fallowed and I would expect them to be closer to the DUL values – I can
have a closer look at these.


## 20200531
ERROR Message:   
`Property set method not found.`
Caused by:   
 zone.Set("Slurp.Leaf.CoverTotal", CoverTotalResetValue); 

Why I can't set this variable? do I have to use the current setup to back
calculate the LAI?

## 20200608
How does Hamish prepare initial soil water content when sowing dates doesn't
match soil water measurements?


## 20200617

Ed pointed out the simulation results seem have systemitic bias.
For example, the prediction always underestimate soil water profile 
**One cause would be the initial conditions for SD1**

Rog suggested to try adjust the clock a bit forward to see what is the soil
doing for the water
Use the simulation water as the initial conditions 

## 20200618

Progress to calculate all STATS for all layers. 
Maybe this could tell which layer contribute to poor prediction? 

Hamish comments:

Two approaches: 
1. expotential decay is good to generalised the model 
2. layer by layer fit is good for details study 

Try both 

## 20200703

Catch up with Derrick. Key points:  

1. The chapter for the thesis.   
  - Literature review on kl (apsimx/stick approaches - prons/cons - free
  draining/stone)
  - Comparision of automated and conventional ways of soil initial condition
  calculation (SW, DUL and LL)
  - Comparision of automated and conventional ways of kls 
  - The three concepts of simulation validation: water, nitrogen and biomass
  
2. The talk.  
  - Bring back the bucket picture 
  - Engage with the audience by showing a working model and how this works and
  why it is relevant (the soil water measurements are crutial to set the initial
  soil conditions right)  
  - A package developed to facilitate the job  
  - when we try to add other type of soil all of a sudden it is not so great  
  - why (stone content/ model set up incorrect)   
  
3. The next.  
  - There is no canopy at all during winter (July to August). Therefore, there
  should not be any water usage by the plants. 
  - Stone content must be considered. Hope a literature review would reveal more
  insights about dealing with stony soils.  
  - Plant parameterisation might be incorrect if the soil has been set up
  correctly and water prediction reasonable.  
  - Derive kls from observation data is still possible but just need to remove
  the big rainfall event.  
  - Where is the root in the soil profile. The root must be in the certain layer
  to be able to use the water. Check if the root prediction is correct.
  - Water table rise up could be an issue.   
  - If biomass is still accumulate while soil profile was dried out, we assume
  the plant was extracting water from deeper layer which exceeded the measured
  depth.
  - Aim a conference talk just on the automation of deriving soil initial
  condition
  - Aim a paper for the parameterisation of soil initial conditions 


Catch up with Xiumei. Key points:   Latest version Apsimx might have broken
parts in the PMF because resipiration constant is not affecting the simulation.


# 20200708

Xiumei suggested that the hydrothermal effect could affect the seed germination 
which will have effects on the canopy development for sure. 
but Changing the `shootlag` in the [Lucerne].Phenology.emergence didn't change any 
prediction results. 

# 20200718

RootFrontVelocity has 3 stages in the current model:
1. Preemergence  Germination-->Emergence
2. Early Emergence-->StartFlowering
3. Late  StartFlowering-->Maturity

1. I should derive RFV by different stages? 
2. water stress has an effect on it as well? 

Root Depth is definately not correct. 
How to get it right? 
 


something more to try
1. get the iversen12 orginal kls back


Question for Hamish

1. k values for canopy structure - origin 0.81, drought 0.66, I12 0.94 - manager script to make it dynamic?
2. re-analysis RFV based on development stages?