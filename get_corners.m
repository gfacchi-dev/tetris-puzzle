function corners = get_corners(image, label)
    props = regionprops(image==label,"BoundingBox");
    subImage = imcrop(image==label, props.BoundingBox);
    subImage = padarray(subImage, [20 20], 0 , 'both');
    %imshow(subImage);
     %poly reduction----------------------
     [B, L] = bwboundaries(image==label, 'noholes');
     boundary = B{1};

   logical = image==label;
    %Ramer-Douglas-Peucker algorithm
     tolerance = 0.08;
     p_reduced = reducepoly(boundary,tolerance);    
     [X, Y] = size(logical);
     simplified = zeros(X, Y);
     simplified = roipoly(simplified, p_reduced(:,2),p_reduced(:,1));    
    %-----------------------------------------
     corners = detectHarrisFeatures(simplified, "MinQuality", 0.35, "FilterSize", 11);
end