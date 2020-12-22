clear all;
close all;

imrgb = imread("R02.jpg");
imycbcr = rgb2ycbcr(imrgb);
imhsv = rgb2hsv(imrgb);

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

imf = c1 + c2 + c3 + c4 + c5;
se = strel("square", 20);
imf = imclose(imf, se);
imf = imerode(imf, se);

labels = bwlabel(imf);
% imagesc(labels);

p = regionprops(imf);

% final = im2double(imrgb) .* double(repmat(imf,[1,1,3]));
% figure
% subplot(1, 2, 1), imshow(imrgb);
% subplot(1, 2, 2), imshow(final);

figure
subplot(1, 2, 1), imshow(imrgb);
subplot(1, 2, 2), imshow(imf);