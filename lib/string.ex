defmodule StringDiff do
    alias String, as: S

    ########################
    # Levenshtein Distance #
    ########################
    
    def levenshtein(a, b) do
        levenshtein_(a, S.length(a), b, S.length(b))
    end


    defp levenshtein_(a, i, b, j) when i == 0 or j == 0 do
        max(i, j)
    end

    defp levenshtein_(a, i, b, j) do
        cost =  if  S.at(a, i - 1) == S.at(b, j - 1) do
            0
        else
            1
        end
        # lev(i - 1, j) + 1
        x = levenshtein_(a, i - 1, b, j) + 1
        # lev(i, j - 1) + 1
        y = levenshtein_(a, i, b, j - 1) + 1
        # lev(i - 1, j - 1) + 1
        z = levenshtein_(a, i - 1, b, j - 1) + cost

        min(x, min(y, z)) 
    end

end