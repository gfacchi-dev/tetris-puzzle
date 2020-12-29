clear all;
close all;

load("classifier_bayes.mat");
load("classifier_knn.mat");

% SCENA
image = imread("P05.jpg");
imrgb= imresize(image, 1);
imycbcr = rgb2ycbcr(imrgb);
imhsv = rgb2hsv(imrgb);

test_values = cat(3, imrgb(:, :, 2:3), imycbcr);
% test_values = cat(3, imycbcr(:,:,2:3), imhsv(:,:,2));
[r, c, ch] = size(test_values);
test_values = double(reshape(test_values, r*c, ch));

predicted = predict(classifier_bayes, test_values);
predicted = reshape(predicted, r, c);

se = strel("square", 10);
predicted = imclose(predicted, se);
predicted = medfilt2(predicted, [19 19]);
se = strel("square", 50);
predicted = imerode(predicted, se);
se = strel("square", 15);

predicted = imdilate(predicted, se);


% figure, imshow(predicted);

labeled_scene = bwlabel(predicted);
scene_labels = unique(labeled_scene);
scene_props = [];
for i = 2:length(scene_labels)
    im_props = regionprops(labeled_scene == scene_labels(i), "BoundingBox");
    subImage = imcrop(labeled_scene== scene_labels(i),im_props.BoundingBox);
    subImage = padarray(subImage, [100 100], 0 , 'both');
  
    %subImage = imresize(subImage, 0.3, 'nearest');
   %poly reduction----------------------
    [B, L] = bwboundaries(subImage, 'noholes');
     boundary = B{1};

    tolerance = 0.08;
    %Ramer-Douglas-Peucker algorithm
    p_reduced = reducepoly(boundary,tolerance);    
    [X, Y] = size(subImage);
    simplified = zeros(X, Y);
    simplified = roipoly(simplified, p_reduced(:,2),p_reduced(:,1));
    
    %-----------------------------------------
    corners = detectHarrisFeatures(simplified, "MinQuality", 0.35, "FilterSize", 11);
    im_props = regionprops(subImage, "Eccentricity", "Area", "Perimeter");
    scene_props = [scene_props;  corners.Count/8 im_props.Eccentricity  im_props.Area/im_props.Perimeter^2 scene_labels(i)];
    
end

% SCHEMA
imscheme = rgb2gray(im2double(imread("S06.jpg")));
mask = imscheme > 0.39;
mask = medfilt2(mask, [7 7]);
labeled_scheme = bwlabel(mask);
scheme_labels = unique(labeled_scheme);
scheme_props = [];

for i = 3:length(scheme_labels)
    im_props = regionprops(labeled_scheme == scheme_labels(i),"BoundingBox");
    subImage = imcrop(labeled_scheme == scheme_labels(i),im_props.BoundingBox);
    subImage = padarray(subImage, [100 100], 0 , 'both');
  
    %subImage = imresize(subImage, 0.3, 'nearest');
   %poly reduction----------------------
    [B, L] = bwboundaries(subImage, 'noholes');
     boundary = B{1};

    tolerance = 0.08;
    %Ramer-Douglas-Peucker algorithm
    p_reduced = reducepoly(boundary,tolerance);    
    [X, Y] = size(subImage);
    simplified = zeros(X, Y);
    simplified = roipoly(simplified, p_reduced(:,2),p_reduced(:,1));
    
    %-----------------------------------------
    corners = detectHarrisFeatures(simplified, "MinQuality", 0.35, "FilterSize", 11);
    im_props = regionprops(subImage,  "Eccentricity", "Area", "Perimeter");
    scheme_props = [scheme_props;  corners.Count/8 im_props.Eccentricity  im_props.Area/im_props.Perimeter^2 scene_labels(i)];
end

for i=1:length(scene_props)
    props = scene_props(i,:);
    label=predict(classifier_knn,props(1:end-1));
    figure, imshow(labeled_scene==props(end)), title(label);
end

for i=1:length(scheme_props)
      props = scheme_props(i,:);
      label=predict(classifier_knn,props(1:end-1));
      figure, imshow(labeled_scheme==props(end)), title(label);

end

