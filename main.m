clear all;
close all;

load("classifier_bayes.mat");

% SCENA
image = imread("P10.jpg");
imrgb= imresize(image, 0.4);
imycbcr = rgb2ycbcr(imrgb);
imhsv = rgb2hsv(imrgb);

test_values = cat(3, imrgb(:, :, 2:3), imycbcr);
[r, c, ch] = size(test_values);
test_values = double(reshape(test_values, r*c, ch));

predicted = predict(classifier_bayes, test_values);
predicted = reshape(predicted, r, c);

se = strel("square", 10);
predicted = imclose(predicted, se);
predicted = medfilt2(predicted, [19 19]);
se = strel("square", 30);
predicted = imerode(predicted, se);
figure, imshow(predicted);

labeled_scene = bwlabel(predicted);
labels = unique(labeled_scene);
scene_props = [];
for i = 1:length(labels)
    sup = regionprops(labeled_scene == labels(i), "Centroid", "Eccentricity", "Circularity");
    scene_props = [scene_props; sup.Centroid sup.Eccentricity sup.Circularity labels(i)];
end

% SCHEMA
imscheme = rgb2gray(im2double(imread("S01.jpg")));
mask = imscheme > 0.39;
mask = medfilt2(mask, [7 7]);
labeled_scheme = bwlabel(mask);
labels = unique(labeled_scheme);
scheme_props = [];
for i = 1:length(labels)
    sup = regionprops(labeled_scheme == labels(i), "Centroid", "Eccentricity", "Circularity");
    scheme_props = [scheme_props; sup.Centroid sup.Eccentricity sup.Circularity labels(i)];
end

% CLUSTERIZATION
% is_scheme = [zeros(length(scene_props), 1); ones(length(scheme_props), 1)];
% all_props = [scene_props; scheme_props];