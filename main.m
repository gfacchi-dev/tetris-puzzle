clear all;
close all;

load("classifier_bayes.mat");
load("classifier_knn.mat");

% SCENA
image = imread("P05.jpg");
imrgb= imresize(image, 1);
imycbcr = rgb2ycbcr(imrgb);
imhsv = rgb2hsv(imrgb);

% figure
% subplot(3, 3, 1), imshow(imrgb(:,:,1));
% subplot(3, 3, 2), imshow(imrgb(:,:,2));
% subplot(3, 3, 3), imshow(imrgb(:,:,3));
% subplot(3, 3, 4), imshow(imycbcr(:,:,1));
% subplot(3, 3, 5), imshow(imycbcr(:,:,2));
% subplot(3, 3, 6), imshow(imycbcr(:,:,3));
% subplot(3, 3, 7), imshow(imhsv(:,:,1));
% subplot(3, 3, 8), imshow(imhsv(:,:,2));
% subplot(3, 3, 9), imshow(imhsv(:,:,3));

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
    im_props = regionprops(labeled_scene == scene_labels(i), "Circularity", "Solidity", "Eccentricity", "BoundingBox", "Area", "Perimeter");
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
    im_props = regionprops(subImage, "All");
    scene_props = [scene_props;  corners.Count/8 im_props.Eccentricity  im_props.Area/im_props.Perimeter^2 scene_labels(i)]
    
end

% SCHEMA
imscheme = rgb2gray(im2double(imread("S06.jpg")));
mask = imscheme > 0.39;
mask = medfilt2(mask, [7 7]);
labeled_scheme = bwlabel(mask);
scheme_labels = unique(labeled_scheme);
scheme_props = [];

for i = 3:length(scheme_labels)
    props = regionprops(labeled_scheme == scheme_labels(i), "Circularity", "Extent", "Eccentricity", "Perimeter","BoundingBox");
    
    scheme_props = [scheme_props; props.Circularity props.Eccentricity props.Extent props.Perimeter scheme_labels(i)];
end

% CLUSTERIZATION
is_scheme = [ones(length(scheme_props), 1); zeros(length(scene_props), 1);];
%all_props = [scheme_props; scene_props];

for i=1:length(scene_props)
    props = scene_props(i,:)
    label=predict(classifier_knn,props(1:end-1));
    figure, imshow(labeled_scene==props(end)), title(label);

end

% n_clusters = 9;% max(max(length(scheme_labels) - 2, scene_labels));
% idx = kmeans(all_props(:,1:end-1), n_clusters);
% final = [all_props(:,1:end-1) is_scheme idx all_props(:,end)];