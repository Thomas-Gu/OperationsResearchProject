include("io.jl")

t_3 = [
    3 3 3 2 0 ;
    3 3 0 2 1 ;
    0 1 1 2 1 ;
    2 2 0 0 1 ]

function dominos_solve_test(t::Array{Int, 2})

    n = Int(size(t, 1)) - 1
    n_domino = floor(Int, (((n+1) * (n+2)) * 0.5))
    domino = zeros(Int, n+1, n+2, 5)
    dominos_poss = zeros(Int, 3, n_domino)

    debut = 1
    n_domino_i = n + 1

    for i in 0:n #boucle sur les chiffres des dominos

        for j in debut:(debut + n_domino_i - 1)
            dominos_poss[1, j] = i #on a n_domino_i premiers chiffres constants
            dominos_poss[2, j] = j - debut + i #chacun associés avec des chiffres variables
        end

        debut = debut + n_domino_i
        n_domino_i = n_domino_i - 1
        #@show debut:(debut + n_domino_i - 1)

        if n_domino_i == 0
            break
        end
    end
    @show dominos_poss


    for i in 1:n+1
        for j in 1:n+2
            domino[i, j, 1] = t[i, j] # Lecture de valeur générée
        end
    end

    # Solution :
    # domino[i, j, :] = [valeur, (j-1), (j+1), (i-1), (i+1)]
    domino[1, 1, 3] = 1
    domino[1, 2, 2] = 1

    domino[1, 3, 3] = 1
    domino[1, 4, 2] = 1
    domino[2, 3, 3] = 1
    domino[2, 4, 2] = 1
    domino[3, 3, 3] = 1
    domino[3, 4, 2] = 1
    domino[4, 3, 3] = 1
    domino[4, 4, 2] = 1
    domino[4, 1, 3] = 1
    domino[4, 2, 2] = 1

    domino[2, 1, 5] = 1
    domino[3, 1, 4] = 1
    domino[2, 2, 5] = 1
    domino[3, 2, 4] = 1

    domino[1, 5, 5] = 1
    domino[2, 5, 4] = 1
    domino[3, 5, 5] = 1
    domino[4, 5, 4] = 1

    disp_sol(domino)

    compteur = 0
    for i in 1:n_domino
        println(dominos_poss[1:2,i])
        for j in 1:n+2
            for l in 1:n+1
                #@show domino[l,j,1]
                for k in 2:5
                    if (domino[l,j,1] == dominos_poss[1, i]) 
                        if (k == 2 && j > 1 && domino[l,j-1,1] == dominos_poss[2, i] && domino[l,j,k] == 1 )
                            compteur += 1
                            @show i, j, l, k
                        elseif (k == 3 && j < n+2 && domino[l,j+1,1] == dominos_poss[2, i] && domino[l,j,k] == 1 ) 
                            compteur += 1
                            @show i, j, l, k
                        elseif (k == 4 && l > 1 && domino[l-1,j,1] == dominos_poss[2, i] && domino[l,j,k] == 1 ) 
                            compteur += 1
                            @show i, j, l, k
                        elseif (k == 5 && l < n+1 && domino[l+1,j,1] == dominos_poss[2, i] && domino[l,j,k] == 1 ) 
                            compteur += 1
                            @show i, j, l, k
                        end

                    elseif (domino[l,j,1] == dominos_poss[2, i])
                        if (k == 2 && j > 1 && domino[l,j-1,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) 
                            compteur += 1
                            @show i, j, l, k
                        
                        elseif (k == 3 && j < n+2 && domino[l,j+1,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) 
                            compteur += 1
                            @show i, j, l, k

                        elseif (k == 4 && l > 1 && domino[l-1,j,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) 
                            compteur += 1
                            @show i, j, l, k

                        elseif (k == 5 && l < n+1 && domino[l+1,j,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) 
                            compteur += 1
                            @show i, j, l, k
                        end
                    end
                end
            end
        end
        dominos_poss[3, i] = compteur * 0.5
        compteur = 0
    end

    compteur = 0
    for i in 1:n_domino
        compteur = sum(sum(reduce(+, domino[l,j,k] for k in 2:5 if (domino[l,j,1] == dominos_poss[1, i]) && ((k == 2 && j > 1 && domino[l,j-1,1] == dominos_poss[2, i] && domino[l,j,k] == 1 ) || (k == 3 && j < n+2 && domino[l,j+1,1] == dominos_poss[2, i] && domino[l,j,k] == 1 ) || (k == 4 && l > 1 && domino[l-1,j,1] == dominos_poss[2, i] && domino[l,j,k] == 1 ) || (k == 5 && l < n+1 && domino[l+1,j,1] == dominos_poss[2, i] && domino[l,j,k] == 1 ) || (domino[l,j,1] == dominos_poss[2, i]) && ((k == 2 && j > 1 && domino[l,j-1,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) || (k == 3 && j < n+2 && domino[l,j+1,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) || (k == 4 && l > 1 && domino[l-1,j,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) || (k == 5 && l < n+1 && domino[l+1,j,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) )); init = 0) for l in 1:n+1) for j in 1:n+2)
        
        println(dominos_poss[1:2,i])
        @show(compteur)
        #dominos_poss[3, i] = compteur * 0.5
        compteur = 0
    end




    @show compteur
    println(dominos_poss[1,:])
    println(dominos_poss[2,:])
    println(dominos_poss[3,:])
end

dominos_solve_test(t_3)
