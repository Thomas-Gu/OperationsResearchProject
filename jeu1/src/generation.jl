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
	"probabilité de placer i à l'instant t"
	proba = ones(n+1)*(1/(n+1))
	"n_t[i] = nbr de fois que le chiffre i a été placé dans la grille à l'instant t"
	n_t= zeros(n+1)
	t = 0

	for nl in 1:(n+1)
		for nc in 1:(n+2)
			"mise à jour duvecteur des probabilités"
			for k in 1:(n+1)
				proba[k] = ((n+2)-n_t[k])/((n+1)*(n+2)-t)
			end

			p = rand()
			i = 1
			seuil=proba[1]
			while p>seuil			
				seuil = seuil+proba[i+1]
				i = i+1
			end	
			grille[nl,nc] = i-1
			n_t[i] = n_t[i] + 1
			t = t + 1			
		end
	end
	return grille
    println("In file generation.jl, in method generateInstance(), TODO: generate an instance")
    
end 

println(generateInstance(4))
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



