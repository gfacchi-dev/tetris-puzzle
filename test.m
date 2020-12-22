clear all;
close all;

image = imread("R02.jpg");
imrgb=imresize(image, 0.4);
imycbcr = rgb2ycbcr(imrgb);
imhsv = rgb2hsv(imrgb);
[x, y, ch] = size(imrgb);

c1 = imycbcr(:,:,1) > 190;   % A, H
c2 = imycbcr(:,:,2) > 130;   % F, E
c3 = imycbcr(:,:,3) > 170;   % B, D

c4 = imrgb(:,:,2) > 190; % G
c4 = medfilt2(c4, [9 9]);

c5 = imhsv(:,:,3) < 0.35;   % C

se = strel("square", 10);
c5 = imclose(c5, se);
se = strel("square", 50);
c5 = imerode(c5, se);
c5 = imdilate(c5, se);

%figure, subplot(3,2,1), imshow(c1), subplot(3,2,2), imshow(c2), subplot(3,2,3), imshow(c3), subplot(3,2,4), imshow(c4), subplot(3,2,5), imshow(c5)

imf = c1 + c2 + c3 + c4 + c5;
se = strel("square", 20);
imf = imclose(imf, se);
imf = imerode(imf, se);
imf = medfilt2(imf,[7 7]);
labels = bwlabel(imf);
labels(labels~=0) = 1;

figure;
imagesc(labels);


imConc = cat(3, imrgb(:, :, 2:3),imycbcr);
imConc = im2double(imConc);
[r, c, ch] = size(imConc);

train_values = double(reshape(imConc, r*c, ch));
train_labels = reshape(labels, x*y, 1);

classifier_bayes = fitcnb(train_values,train_labels);
 
image = im2double(imread('P01.jpg'));
imrgb= imresize(image, 0.4);
imycbcr = rgb2ycbcr(imrgb);
imhsv = rgb2hsv(imrgb);

figure, subplot(232), imshow(imhsv), title('original');
subplot(234), imshow(imhsv(:,:,1)), title('Y');
subplot(235), imshow(imhsv(:,:,2)), title('Cb');
subplot(236), imshow(imhsv(:,:,3)), title('C');

imConc = cat(3, imrgb(:, :, 2:3),imycbcr);
imConc = im2double(imConc);
[ir,ic,ich] = size(imConc);
test_values = reshape(imConc,ir*ic,ich);

test_predicted=predict(classifier_bayes,test_values);
% 
% % Ristrutturiamo il vettore delle etichette in una immagine
mask_predicted = reshape(test_predicted,ir,ic);
mask_predicted = medfilt2(mask_predicted,[11 11]);
mask_predicted = imclose(mask_predicted, se);


figure,imshow(mask_predicted);



% cv = cvpartition(labels, "Holdout", 0.2);
% trset = cv.training(1);
% tsset = cv.test(1);
% train_values = values(trset,:);
% test_values=values(tsset,:);
% train_labels = labels(trset);
% test_labels = labels(tsset);
%classifier_bayes = fitcnb(train_values,train_labels);
%save('classifier_Bayes.mat', 'classifier_bayes');