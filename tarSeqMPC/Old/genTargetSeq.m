function [seq, iter] = genTargetSeq(ts_index, sp_index, pk, varargin) %#codegen

    % This function generates the target sequence given the start point (sp_index)
    % index, target_indices (ts_index), and the prediction horizon length (pk)
    
    if ~isempty(varargin)
        seq = varargin{1};
        seq_temp = varargin{2};
        iter = varargin{3};
    else
        seq = [];
        seq_temp = sp_index;
        iter = 1;
    end

    if length(seq_temp) ~= pk+1
        ep_index = ts_index;
        ep_index(ep_index == sp_index) = [];
    end

    for i = 1:length(ep_index)

        seq_temp = [seq_temp, ep_index(i)];
        
        if length(seq_temp) == pk+1
            seq(iter, :) = seq_temp;
            iter = iter+1;
            seq_temp(end) = [];
            continue;
        end
        [seq, iter] = genTargetSeq(ts_index, ep_index(i), pk, seq, seq_temp, iter);
        seq_temp(end) = [];
    end

end