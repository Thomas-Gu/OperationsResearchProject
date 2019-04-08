# This file contains methods to generate a data set of instances (i.e., dominosa grids)
include("io.jl")

"""
Let n be the maximal number reached on the domino tiles.
Beware that 0 is also on the domino tiles.

Generate an (n+1)*(n+2) grid
"""


function generateInstance(n::Int64)
"""
this function generates an array which corresponds to the grid to be paved
"""

	"cette grille représente la grille à paver"	
	grille = zeros(n+1,n+2)
	"remplissage[i] = nbr de fois que le chiffre i a été placé dans la grille"
	remplissage = zeros(n+1)
	"probabilité de placer i à l'instant t"
	proba = ones(n+1)*(1/(n+1))
	
	for nl in 1:(n+1)
		for nc in 1:(n+2)
			p = rand()
			i = 0
			seuil=proba[1]
			while p>seuil
				i = i+1
				seuil = seuil+proba[i]
			end	
			grille[nl,nc] = i
			proba[i+1] = proba[i+1] - 1/((n+1)*(n+2))
			proba= proba + 1/((n+1)*(n+1)*(n+2))*ones(n+1)
			"Normaliser différement les probas : diviser plutôt qu'additioner"
		end
	end
	return grille
    println("In file generation.jl, in method generateInstance(), TODO: generate an instance")
    
end 

println(generateInstance(6))
"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""



function generateDataSet(Array{Int64})
"""
This function takes as an argument the array previously generated.
This function returns a .txt file containing all the informations
"""

    # TODO
    println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
    
end



