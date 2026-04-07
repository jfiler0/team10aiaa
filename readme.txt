You thought this would be a helpful readme? No. Just ranting

TODO:
-Berguet simple max range and endurance starting from MTOW
-Max turn rate, deg/s
-A single function that will get set of aircraft data and show in a nice table
-Geometry visualizer

THE ESTIMATED L/D IS NOT CLOSE AT ALL >:$

Mission analysis should break down long range or endurance segments into smaller ones to be more accurate

Might want some checks for resonable values

4/5/26 - TODO:
- linking in sizing + weight info into the loop
- finishing the constraint functions
- implement F414 engine (complete f18 validation)
	- F135 two pretty please? any just throw more data points
- double check mission
- any ways to predict internal volume?
    - get predictions from current
    - current volume that we are modeling
    - compare the f18 model
- FORTRAN? idrag?
- link with simulation (stability derivatives) (not as important)  -> how to get this in the loop
-Add twisting and incidence angles to surfaces
	- control power required to make turns
- improve store drag estimation
- better flap -> max cl model
	- 8 deg limit is mean
	- how does this limit fuel volume
	- making sure flap size has some sensitivity to max cl
- making a new openvsp

(CFD, get tunnel geometry)