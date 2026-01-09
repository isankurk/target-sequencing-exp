function curvature = calculateCurvature(dataPoints)
    dataPoints = dataPoints';
    % Initialize variables
    numPoints = size(dataPoints, 1);
    h = 1; % Step size, you can adjust this as needed
    curvature = 0;

    % Loop through each data point
    for t = 2:numPoints-1
        
        % Calculate the approximate derivative of the unit tangent vector
        da_x = (dataPoints(t+1, 1) - 2 * dataPoints(t, 1) + dataPoints(t-1, 1)) / h^2;
        da_y = (dataPoints(t+1, 2) - 2 * dataPoints(t, 2) + dataPoints(t-1, 2)) / h^2;
        
        % Calculate the squared magnitude of the approximate derivative
        da_magnitude_squared = da_x^2 + da_y^2;
        
        % Add the contribution to curvature
        curvature = curvature + h * da_magnitude_squared;
    end
    
    % Normalize curvature by the number of points (optional)
    curvature = curvature / numPoints;
end
