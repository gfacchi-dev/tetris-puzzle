clear all;
close all;

load("classifier_bayes.mat");

% TEST 
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