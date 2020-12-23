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

props = regionprops(logical(bwlabel(predicted)), "Centroid", "Eccentricity", "Circularity");
scene_props = [];
for i=1:length(props)
    scene_props = [scene_props; props(i).Centroid props(i).Eccentricity props(i).Circularity];
end

% SCHEMA
imscheme = rgb2gray(im2double(imread("S01.jpg")));
mask = imscheme > 0.39;
mask = medfilt2(mask, [7 7]);
labels = bwlabel(mask);
props = regionprops(logical(labels), "Centroid", "Eccentricity", "Circularity");
scheme_props = [];
for i=1:length(props)
    scheme_props = [scheme_props; props(i).Centroid props(i).Eccentricity props(i).Circularity];
end

% CLUSTERIZATION
is_scheme = [zeros(length(scene_props), 1); ones(length(scheme_props), 1)];
all_props = [scene_props; scheme_props];