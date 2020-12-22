clear all;
close all;

imrgb = imread("R02.jpg");

imycbcr = rgb2ycbcr(imrgb);
imhsv = rgb2hsv(imrgb);

[x, y, ch] = size(imrgb);

c1 = imycbcr(:,:,1) > 185;   % A, H
c2 = imycbcr(:,:,2) > 130;   % F, E
c3 = imycbcr(:,:,3) > 170;   % B, D
c4 = imrgb(:,:,2) > 190; % G
c5 = imhsv(:,:,3) < 0.35;   % C

se = strel("square", 10);
c5 = imclose(c5, se);
se = strel("square", 50);
c5 = imerode(c5, se);
c5 = imdilate(c5, se);

imConc = cat(3, imrgb,imycbcr,imhsv(:,:,2:end));

imf = c1 + c2 + c3 + c4 + c5;
se = strel("square", 20);
imf = imclose(imf, se);
imf = imerode(imf, se);
imf = medfilt2(imf,[5 5]);

labels = bwlabel(imf);
imagesc(labels);


values = double(reshape(imycbcr(:,:,2:3), x*y, 2));
labels = reshape(labels, x*y, 1);

cv = cvpartition(labels, "Holdout", 0.2);


trset = cv.training(1);
tsset = cv.test(1);

train_values = values(trset,:);
test_values=values(tsset,:);

train_labels = labels(trset);
test_labels = labels(tsset);

%classifier_bayes = fitcnb(train_values,train_labels);

save('classifier_Bayes.mat', 'classifier_bayes');

