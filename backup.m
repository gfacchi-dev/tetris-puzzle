clear all;
close all;

load("classifier_bayes.mat");

% SCENA
image = imread("P02.jpg");
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

figure,imshow(predicted)
%BW2 = bwareaopen(BW, 50);

% figure, imshow(predicted);

labeled_scene = bwlabel(predicted);
figure, imshow(labeled_scene);
labels = unique(labeled_scene);
scene_props = [];
max_label= max(labels);
for i = 2:length(labels)
    sup = regionprops(labeled_scene == labels(i), "Extrema", 'Perimeter' ,"Area","Eccentricity", "Circularity",'BoundingBox');
   % scene_props = [scene_props;sup.Eccentricity sup.Area/sup.Perimeter^2 sup.Circularity  labels(i)];
   scene_props=[scene_props; sup.Extrema];
   subImage = imcrop(labeled_scene== labels(i),sup.BoundingBox);
    subImage = padarray(subImage, [100 100], 0 , 'both');
end

% SCHEMA
imscheme = rgb2gray(im2double(imread("S01.jpg")));
mask = imscheme > 0.39;
mask = medfilt2(mask, [7 7]);
labeled_scheme = bwlabel(mask);
labels = unique(labeled_scheme);
scheme_props = [];

for i = 3:length(labels)
    sup = regionprops(labeled_scheme == labels(i), "Extent", 'Perimeter',"Area", "Eccentricity", "Circularity", "BoundingBox");
   % scheme_props = [scheme_props; sup.Eccentricity sup.Area/sup.Perimeter^2 sup.Circularity    labels(i)];
    scheme_props = [scheme_props; sup.Extrema]
     subImage = imcrop(labeled_scheme== labels(i),sup.BoundingBox);
    subImage = padarray(subImage, [100 100], 0 , 'both');
    sub_labeled= bwlabel(subImage);
    sub_labels = unique(sub_labeled);

end
min = 0;
min_index=zeros(length(scheme_props), 1);
for i=1:length(scheme_props)
    min=0;
    for j=1:length(scene_props)
        dist = sqrt((scheme_props(i,1) - scene_props(j,1))^2 + (scheme_props(i,2) - scene_props(j,2))^2+ (scheme_props(i,3) - scene_props(j,3))^2);
        if min==0 || dist<min
            min=dist;
            min_index(i) =j;
        end
    end

end

for i=1:length(min_index)
       figure,subplot(1,2,1),imshow(labeled_scheme == scheme_props(i,4))
       subplot(1,2,2),imshow(labeled_scene==scene_props(min_index(i),4));
end

