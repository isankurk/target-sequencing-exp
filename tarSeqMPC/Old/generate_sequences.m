function sequences = generate_sequences(points, n)
    % Generate all possible n-length sequences of points from a given list of points.
    % Parameters:
    %   points: Cell array, the list of points.
    %   n: Integer, the length of the sequence to be generated.
    % Returns:
    %   sequences: Cell array, a cell array of all possible n-length sequences.

    function backtrack(curr_sequence)
        if length(curr_sequence) == n
            sequences{end+1} = curr_sequence; % Append the current sequence to the cell array
            return
        end

        for i = 1:length(points)
            point = points{i};
            if isempty(curr_sequence) || ~isequal(point, curr_sequence{end})
                curr_sequence{end+1} = point; % Append the current point to the current sequence
                backtrack(curr_sequence);
                curr_sequence(end) = []; % Remove the last point to backtrack
            end
        end
    end

    sequences = {}; % Initialize an empty cell array
    backtrack({});
end
