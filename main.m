clear all;
close all;

load("classifier_bayes.mat");

% SCENA
image = imread("P03.jpg");
imrgb= imresize(image, 0.4);
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
se = strel("square", 20);
predicted = imerode(predicted, se);
predicted = imdilate(predicted, se);
% figure, imshow(predicted);

labeled_scene = bwlabel(predicted);
scene_labels = unique(labeled_scene);
scene_props = [];
for i = 2:length(scene_labels)
    props = regionprops(labeled_scene == scene_labels(i), "Circularity", "Extent", "Eccentricity", "Solidity");
    scene_props = [scene_props; props.Circularity props.Eccentricity props.Extent props.Solidity scene_labels(i)];
end

% SCHEMA
imscheme = rgb2gray(im2double(imread("S06.jpg")));
mask = imscheme > 0.39;
mask = medfilt2(mask, [7 7]);
labeled_scheme = bwlabel(mask);
scheme_labels = unique(labeled_scheme);
scheme_props = [];

for i = 3:length(scheme_labels)
    props = regionprops(labeled_scheme == scheme_labels(i), "Circularity", "Extent", "Eccentricity", "Perimeter");
    scheme_props = [scheme_props; props.Circularity props.Eccentricity props.Extent props.Perimeter scheme_labels(i)];
end

% CLUSTERIZATION
is_scheme = [ones(length(scheme_props), 1); zeros(length(scene_props), 1);];
all_props = [scheme_props; scene_props];

% n_clusters = 9;% max(max(length(scheme_labels) - 2, scene_labels));
% idx = kmeans(all_props(:,1:end-1), n_clusters);
% final = [all_props(:,1:end-1) is_scheme idx all_props(:,end)];