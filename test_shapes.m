imf = imread("scheme.png");

imshow(bwskel(imf));

% label = 4;
% labeled_im = bwlabel(imf);
% % imagesc(labeled_im);
% imshow(labeled_im == label);
% corners = detectHarrisFeatures(labeled_im == label, "MinQuality", 0.6, "FilterSize", 25);

corners.Count
imshow(labeled_im == label)
hold on
plot(corners);