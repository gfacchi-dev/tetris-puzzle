clear all;
close all;

load("classifier_bayes.mat");
load("classifier_knn.mat");

% SCENA
image = imread("P02.jpg");
imrgb= imresize(image, 1);
R = imrgb(:,:,1);
G = imrgb(:,:,2);
B = imrgb(:,:,3);
imycbcr = rgb2ycbcr(imrgb);
imhsv = rgb2hsv(imrgb);

test_values = cat(3, imrgb(:, :, 2:3), imycbcr);
[r, c, ch] = size(test_values);
test_values = double(reshape(test_values, r*c, ch));

predicted = predict(classifier_bayes, test_values);
predicted = reshape(predicted, r, c);

se = strel("square", 10);
predicted = imclose(predicted, se);
predicted = medfilt2(predicted, [21 21]);
se = strel("square", 50);
predicted = imerode(predicted, se);
se = strel("square", 15);

predicted = imdilate(predicted, se);



labeled_scene = bwlabel(predicted);
scene_labels = unique(labeled_scene);
scene_props = [];
for i = 2:length(scene_labels)
    im_props = regionprops(labeled_scene == scene_labels(i), "BoundingBox");
    subImage = imcrop(labeled_scene== scene_labels(i),im_props.BoundingBox);
    subImage = padarray(subImage, [100 100], 0 , 'both');
  
   %poly reduction----------------------
    [B, L] = bwboundaries(subImage, 'noholes');
     boundary = B{1};

   
    %Ramer-Douglas-Peucker algorithm
     tolerance = 0.08;
    p_reduced = reducepoly(boundary,tolerance);    
    [X, Y] = size(subImage);
    simplified = zeros(X, Y);
    simplified = roipoly(simplified, p_reduced(:,2),p_reduced(:,1));
    
    %-----------------------------------------
    corners = detectHarrisFeatures(simplified, "MinQuality", 0.35, "FilterSize", 11);
    im_props = regionprops(subImage, "Eccentricity", "Area", "Perimeter");
    scene_props = [scene_props;  corners.Count/8 im_props.Eccentricity  im_props.Area/im_props.Perimeter^2 scene_labels(i)]
    
end

% SCHEMA
imschemergb = im2double(imread("S04.jpg"));
imscheme = rgb2gray(imschemergb);
mask = imscheme > 0.39;
mask = medfilt2(mask, [7 7]);
labeled_scheme = bwlabel(mask);
scheme_labels = unique(labeled_scheme);
scheme_props = [];

for i = 3:length(scheme_labels)
    im_props = regionprops(labeled_scheme == scheme_labels(i),"BoundingBox");
    subImage = imcrop(labeled_scheme == scheme_labels(i),im_props.BoundingBox);
    subImage = padarray(subImage, [100 100], 0 , 'both');
  
   %poly reduction----------------------
     [B, L] = bwboundaries(subImage, 'noholes');
     boundary = B{1};

   
    %Ramer-Douglas-Peucker algorithm
     tolerance = 0.08;
     p_reduced = reducepoly(boundary,tolerance);    
     [X, Y] = size(subImage);
     simplified = zeros(X, Y);
     simplified = roipoly(simplified, p_reduced(:,2),p_reduced(:,1));    
    %-----------------------------------------
    corners = detectHarrisFeatures(simplified, "MinQuality", 0.35, "FilterSize", 11);
    im_props = regionprops(subImage,  "Eccentricity", "Area", "Perimeter");
    scheme_props = [scheme_props;  corners.Count/8 im_props.Eccentricity  im_props.Area/im_props.Perimeter^2 scheme_labels(i)];
end
scene_predicted=[];
for i=1:length(scene_props)
    props = scene_props(i,:);
    if(props(1)~=0 )
        if(props(1) == 0.5 || props(1) == 0.75 || props(1) == 1)
             label=predict(classifier_knn,props(1:end-1));
            %figure, imshow(labeled_scene==props(end)), title(label);
            maskedRgbImage = bsxfun(@times, imrgb, cast(labeled_scene==props(end), class(imrgb)));
       
            scene_predicted = [scene_predicted; props(1) props(2) props(3) props(4) str2double(label)];
            % figure, imshow(maskedRgbImage),  title(label);
        end     
    end
end
scheme_predicted = [];
for i=1:length(scheme_props)
      props = scheme_props(i,:);
      label=predict(classifier_knn,props(1:end-1));
      % figure, imshow(labeled_scheme==props(end)), title(label);
      scheme_predicted = [scheme_predicted; props(1) props(2) props(3) props(4) str2double(label)];
end

for i=1:length(scheme_predicted)
    for j=1:length(scene_predicted)
        if(scheme_predicted(i, 5) == scene_predicted(j, 5))
            scene_res_props = regionprops(labeled_scene == scene_predicted(j, 4), "BoundingBox", "MaxFeretProperties");
            scheme_res_props = regionprops(labeled_scheme == scheme_predicted(i, 4), "BoundingBox", "MaxFeretProperties", "Centroid");
        
            scaleF = scheme_res_props.MaxFeretDiameter / scene_res_props.MaxFeretDiameter;
            subImage = imcrop(labeled_scene== scene_predicted(j, 4), scene_res_props.BoundingBox);
            
            schemeSubImage = imcrop(labeled_scheme== scheme_predicted(i, 4), scheme_res_props.BoundingBox);
            
            imRotated = imrotate(subImage, -(scheme_res_props.MaxFeretAngle - scene_res_props.MaxFeretAngle));
            imRotated = imresize(imRotated, scaleF);
            
            % Translation
            up = round(scheme_res_props.Centroid(2) - size(imRotated, 1) / 2);
            bottom = round(scheme_res_props.Centroid(2) + size(imRotated, 1) / 2);
            left = round(scheme_res_props.Centroid(1) - size(imRotated, 2) / 2);
            right = round(scheme_res_props.Centroid(1) + size(imRotated, 2) / 2);
            
            sup = imscheme;
            sup(up:bottom-1, left:right-1) = sup(up:bottom-1, left:right-1) .* (1 - imRotated);
            figure, imshow(sup)
        end    
    end
end