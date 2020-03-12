names(apsimx.options)
apsimx_options(exe.path = "../APSIM2019.10.04.4236/Bin/ApsimNG.exe",examples.path = "../APSIM2019.10.04.4236/Examples/")
apsimx.options$exe.path
apsimx.options$examples.path
inspect_apsimx("Barley", src.dir = "../APSIM2019.10.04.4236/Examples/", node = "Soil", soil.child = "Water") 


# lucerne in prototype ----------------------------------------------------


names(apsimx.options)
apsimx_options(exe.path = "../APSIM2019.10.04.4236/Bin/ApsimNG.exe",examples.path = "../APSIM2019.10.04.4236/Examples/")
apsimx.options$exe.path
apsimx.options$examples.path
inspect_apsimx("LucerneValidation", src.dir = "../APSIM2019.10.10/Prototypes/Lucerne/", node = "Soil", soil.child = "Water") 
inspect_apsimx_replacement("LucerneValidation", src.dir = "../APSIM2019.10.10/Prototypes/Lucerne/", )
