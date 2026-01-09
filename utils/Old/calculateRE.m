function [re] = calculateRE(state, endPt, dt, varargin)

    if isempty(varargin)
        RE_t = 2;
    else
        RE_t = varargin{1};
    end

    re_idx = int32( min(size(state, 2), RE_t/dt) );
    re = norm(endPt - state(:, re_idx), 2);

end