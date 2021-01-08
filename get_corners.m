function corners = get_corners(image)
    [B, L] = bwboundaries(image, "noholes");
    boundary = B{1};

    %Ramer-Douglas-Peucker Algorithm (Polygon reduction)
    tolerance = 0.08;
    p_reduced = reducepoly(boundary,tolerance);    
    [X, Y] = size(image);
    simplified = zeros(X, Y);
    simplified = roipoly(simplified, p_reduced(:,2),p_reduced(:,1));

    corners = detectHarrisFeatures(simplified, "MinQuality", 0.35, "FilterSize", 11);
end