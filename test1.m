clear all;
close all;

im = rgb2gray(im2double(imread("S01.jpg")));
% plot(imhist(im));

mask = im > 0.39;
imshow(mask)
labels = bwlabel(mask);
imagesc(labels);


% mask = sauvola(im, [5, 5]);
% imshow(mask);