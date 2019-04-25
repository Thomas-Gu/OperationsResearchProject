include("io.jl")

t_3 = [
    3 3 3 2 0 ;
    3 3 0 2 1 ;
    0 1 1 2 1 ;
    2 2 0 0 1 ]

t_0 = [
    0 0 1 ;
    1 1 0 ]

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
    domino[1, 3, 5] = 1
    domino[2, 3, 4] = 1
    domino[2, 1, 3] = 1
    domino[2, 2, 2] = 1





    # domino[1, 1, 3] = 1
    # domino[1, 2, 2] = 1
    # domino[1, 3, 3] = 1
    # domino[1, 4, 2] = 1
    # domino[2, 3, 3] = 1
    # domino[2, 4, 2] = 1
    # domino[3, 3, 3] = 1
    # domino[3, 4, 2] = 1
    # domino[4, 3, 3] = 1
    # domino[4, 4, 2] = 1
    # domino[4, 1, 3] = 1
    # domino[4, 2, 2] = 1
    # domino[2, 1, 5] = 1
    # domino[3, 1, 4] = 1
    # domino[2, 2, 5] = 1
    # domino[3, 2, 4] = 1
    # domino[1, 5, 5] = 1
    # domino[2, 5, 4] = 1
    # domino[3, 5, 5] = 1
    # domino[4, 5, 4] = 1

    disp_sol(domino)

    compteur1 = 0
    compteur2 = 0
    for i in 1:n_domino
        println(dominos_poss[1:2,i])
        for j in 1:n+2
            for l in 1:n+1
                #@show domino[l,j,1]
                
                for k in 2:5
                    if (domino[l,j,1] == dominos_poss[1, i]) 
                        if (k == 2 && j > 1 && domino[l,j-1,1] == dominos_poss[2, i] && domino[l,j,k] == 1 )
                            compteur1 += 1
                            @show i, j, l, k
                        elseif (k == 3 && j < n+2 && domino[l,j+1,1] == dominos_poss[2, i] && domino[l,j,k] == 1 ) 
                            compteur1 += 1
                            @show i, j, l, k
                        elseif (k == 4 && l > 1 && domino[l-1,j,1] == dominos_poss[2, i] && domino[l,j,k] == 1 ) 
                            compteur1 += 1
                            @show i, j, l, k
                        elseif (k == 5 && l < n+1 && domino[l+1,j,1] == dominos_poss[2, i] && domino[l,j,k] == 1 ) 
                            compteur1 += 1
                            @show i, j, l, k
                        end

                    elseif (domino[l,j,1] == dominos_poss[2, i])
                        if (k == 2 && j > 1 && domino[l,j-1,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) 
                            compteur1 += 1
                            @show i, j, l, k
                        
                        elseif (k == 3 && j < n+2 && domino[l,j+1,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) 
                            compteur1 += 1
                            @show i, j, l, k

                        elseif (k == 4 && l > 1 && domino[l-1,j,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) 
                            compteur1 += 1
                            @show i, j, l, k

                        elseif (k == 5 && l < n+1 && domino[l+1,j,1] == dominos_poss[1, i] && domino[l,j,k] == 1 ) 
                            compteur1 += 1
                            @show i, j, l, k
                        end
                    end
                end
            end
        end
        @show compteur1
        @show dominos_poss[1,i], dominos_poss[2,i]

        compteur21 = sum( # Pour chaque emplaçement vertical du domino
                        reduce(+, domino[l, j, 5] + domino[l+1, j, 4] for j in 1:n+2
                            if (
                                (t[l, j] == dominos_poss[1,i] && t[l+1, j] == dominos_poss[2,i]) 
                                || (t[l, j] == dominos_poss[2,i] && t[l+1, j] == dominos_poss[1,i])
                            ) ;
                            init = 0
                        ) 
                    for l in 1:n)
        compteur22 = sum( # Pour chaque emplaçement horizontal du domino
                        reduce(+, domino[l, j, 3] + domino[l, j+1, 2] for l in 1:n+1
                            if (
                                (t[l, j] == dominos_poss[1,i] && t[l, j+1] == dominos_poss[2,i]) 
                                || (t[l, j] == dominos_poss[2,i] && t[l, j+1] == dominos_poss[1,i])
                            ) ;
                            init = 0
                        ) 
                    for j in 1:n+1)
                        

        #dominos_poss[3, i] = compteur1 * 0.5
        dominos_poss[3, i] = (compteur21 + compteur22) * 0.5
        
        @show compteur21+compteur22
        compteur1 = 0
        compteur2 = 0
    end

    return(dominos_poss[3, :])
end

dominos_poss = dominos_solve_test(t_0)
@show dominos_poss
