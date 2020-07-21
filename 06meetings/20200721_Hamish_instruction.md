---

Title: "Summary of 20th July catch up with Hamish"

---


1. `Cut` will bring the plant phenology back to inductive phase. To check how it
has been set up - go to the Mower script and check the
`Remove.SetPhenologyStage`. Number 4 represents the end of Juvenile

2. It is not worth to implement a logic which represents the real Juvenile phase
in the apsimx model. This is because no one would really want to cut the crop
until the crop has reach late vegetative or even reproductive.

3. Use report in replacement and delete the redundant information inside the
experiments. 

4. Move the `Fw` 2 levels up to reduce duplications in the `LEAR` node

5. RFV in different stages can be setup in a multiplication function. Use a
scale approach to scale down the RFV from its maximum value to different values
in different growth stages.

6. Tried to have an understanding of how other crop models deal with RFVs. e.g.
Wheat and Maize

7. RFV values could be a function of Temperature or 
more appropriate $RFV = f(Potential Growth)$. The latter takes account of `Fw` 
already.

8. Read Micheal Robinson's paper(s) to understand the interaction between root
length density and enviornment.

9. Optimise the relationship between `Fw` and `Supply/Demand` or `Fw` and `Root
water potential` (wheat model as a starting point).

10. Apsimx file managment. At least version control two files: Slurp and Lucerne
   Think backward from how to structure the thesis.  
   - What are the necessary graphs that will be needed.  
   - Use the order of the graphs as the instruction of the git commit histroy
   
11. Re-analysis Richard's data for double check the extinction coefficient.

12. Fix the problem before moving on to the next phase, otherwise it would be
garateened that the problem needs to be revisited.

   