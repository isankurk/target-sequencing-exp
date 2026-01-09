function prob = my_softmax(vals, temp)

    v_max = max(vals);
    prob = exp((vals-v_max)/temp)./sum(exp((vals-v_max)/temp));

end