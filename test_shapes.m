load("classifier_knn.mat");

imrgb = imread("R01.jpg");
imycbcr = rgb2ycbcr(imrgb);
imhsv = rgb2hsv(imrgb);

c1 = imycbcr(:,:,1) > 190;   % A, H
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
imf = medfilt2(imf,[7 7]);

label = 10;
labeled_im = bwlabel(imf);
corners = detectHarrisFeatures(labeled_im == label, "MinQuality", 0.5, "FilterSize", 23);
p = regionprops(labeled_im == label, "all");
props = [corners.Count p.Circularity p.Eccentricity p.Extent];

predicted = predict(classifier_knn, props);