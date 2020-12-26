clear all;
close all;

load("classifier_bayes.mat");

% SCENA
image = imread("P02.jpg");
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
% se = strel("square", 30);
% predicted = imerode(predicted, se);
% figure, imshow(predicted);

labeled_scene = bwlabel(predicted);
labels = unique(labeled_scene);
scene_props = [];
for i = 2:length(labels)
    sup = regionprops(labeled_scene == labels(i), "BoundingBox");
    crop = imcrop(predicted, sup.BoundingBox);
    props = regionprops(crop, "Circularity");
    [cx, cy] = normalize_centroid(props.Centroid, sup.BoundingBox);
    scene_props = [scene_props; cx cy props.Circularity labels(i)];
end

% SCHEMA
imscheme = rgb2gray(im2double(imread("S02.jpg")));
mask = imscheme > 0.39;
mask = medfilt2(mask, [7 7]);
labeled_scheme = bwlabel(mask);
labels = unique(labeled_scheme);
scheme_props = [];
for i = 3:length(labels)
    sup = regionprops(labeled_scheme == labels(i), "BoundingBox");
    crop = imcrop(labeled_scheme == labels(i), sup.BoundingBox);
    props = regionprops(crop, "Centroid", "Circularity");
    [cx, cy] = normalize_centroid(props.Centroid, sup.BoundingBox);
    scheme_props = [scheme_props; cx cy props.Circularity labels(i)];
end

% CLUSTERIZATION
is_scheme = [zeros(length(scene_props), 1); ones(length(scheme_props), 1)];
all_props = [scene_props; scheme_props];

n_clusters = length(labels) - 2;
idx = kmeans(all_props(:,1:end-1), n_clusters);
final = [all_props(:,1:end-1) is_scheme idx all_props(:,end)];

for i=1:n_clusters
    scene = labeled_scene * 0;
    for j=1:length(final)
        if (final(j, 5) == i && final(j, 4) == 0)
            scene = scene + labeled_scene == final(j, 6);
        end
    end
    
    scheme = labeled_scheme * 0;
    for j=1:length(final)
        if (final(j, 5) == i && final(j, 4) == 1)
            scheme = scheme + labeled_scheme == final(j, 6);
        end
    end
    
    figure
    subplot(1, 2, 1), imshow(scene);
    subplot(1, 2, 2), imshow(scheme);
end

function [centroid_x, centroid_y] = normalize_centroid(centroid, boundingBox)
    centroid_x = centroid(1) / boundingBox(3);
    centroid_y = centroid(2) / boundingBox(4);
end