clear all;
close all;

load("classifier_bayes.mat");
load("classifier_knn.mat");

% SCENA
image = imread("P01.jpg");
imrgb= imresize(image, 1);
R = imrgb(:,:,1);
G = imrgb(:,:,2);
B = imrgb(:,:,3);
imycbcr = rgb2ycbcr(imrgb);
imhsv = rgb2hsv(imrgb);

test_values = cat(3, imrgb(:, :, 2:3), imycbcr);
[r, c, ch] = size(test_values);
test_values = double(reshape(test_values, r*c, ch));

predicted = predict(classifier_bayes, test_values);
predicted = reshape(predicted, r, c);

se = strel("square", 10);
predicted = imclose(predicted, se);
predicted = medfilt2(predicted, [21 21]);
se = strel("square", 50);
predicted = imerode(predicted, se);
se = strel("square", 15);

predicted = imdilate(predicted, se);



labeled_scene = bwlabel(predicted);
scene_labels = unique(labeled_scene);
scene_props = [];
for i = 2:length(scene_labels)
    im_props = regionprops(labeled_scene == scene_labels(i), "BoundingBox");
    subImage = imcrop(labeled_scene== scene_labels(i),im_props.BoundingBox);
    subImage = padarray(subImage, [100 100], 0 , 'both');
  
   %poly reduction----------------------
    [B, L] = bwboundaries(subImage, 'noholes');
     boundary = B{1};

   
    %Ramer-Douglas-Peucker algorithm
     tolerance = 0.08;
    p_reduced = reducepoly(boundary,tolerance);    
    [X, Y] = size(subImage);
    simplified = zeros(X, Y);
    simplified = roipoly(simplified, p_reduced(:,2),p_reduced(:,1));
    
    %-----------------------------------------
    corners = detectHarrisFeatures(simplified, "MinQuality", 0.35, "FilterSize", 11);
    im_props = regionprops(subImage, "Eccentricity", "Area", "Perimeter");
    scene_props = [scene_props;  corners.Count/8 im_props.Eccentricity  im_props.Area/im_props.Perimeter^2 scene_labels(i)]
    
end

% SCHEMA
imschemergb = im2double(imread("S06.jpg"));
imscheme = rgb2gray(imschemergb);
mask = imscheme > 0.39;
mask = medfilt2(mask, [7 7]);
labeled_scheme = bwlabel(mask);
scheme_labels = unique(labeled_scheme);
scheme_props = [];

for i = 3:length(scheme_labels)
    im_props = regionprops(labeled_scheme == scheme_labels(i),"BoundingBox");
    subImage = imcrop(labeled_scheme == scheme_labels(i),im_props.BoundingBox);
    subImage = padarray(subImage, [100 100], 0 , 'both');
  
   %poly reduction----------------------
     [B, L] = bwboundaries(subImage, 'noholes');
     boundary = B{1};

   
    %Ramer-Douglas-Peucker algorithm
     tolerance = 0.08;
     p_reduced = reducepoly(boundary,tolerance);    
     [X, Y] = size(subImage);
     simplified = zeros(X, Y);
     simplified = roipoly(simplified, p_reduced(:,2),p_reduced(:,1));    
    %-----------------------------------------
    corners = detectHarrisFeatures(simplified, "MinQuality", 0.35, "FilterSize", 11);
    im_props = regionprops(subImage,  "Eccentricity", "Area", "Perimeter");
    scheme_props = [scheme_props;  corners.Count/8 im_props.Eccentricity  im_props.Area/im_props.Perimeter^2 scheme_labels(i)];
end
scene_predicted=[];
for i=1:length(scene_props)
    props = scene_props(i,:);
    if(props(1)~=0 )
        if(props(1) == 0.5 || props(1) == 0.75 || props(1) == 1)
             label=predict(classifier_knn,props(1:end-1));
            %figure, imshow(labeled_scene==props(end)), title(label);
            maskedRgbImage = bsxfun(@times, imrgb, cast(labeled_scene==props(end), class(imrgb)));
       
            scene_predicted = [scene_predicted; props(1) props(2) props(3) props(4) str2double(label)];
            % figure, imshow(maskedRgbImage),  title(label);
        end     
    end
end
scheme_predicted = [];
for i=1:length(scheme_props)
      props = scheme_props(i,:);
      label=predict(classifier_knn,props(1:end-1));
      % figure, imshow(labeled_scheme==props(end)), title(label);
      scheme_predicted = [scheme_predicted; props(1) props(2) props(3) props(4) str2double(label)];
end

for i=1:length(scheme_predicted)
    for j=1:length(scene_predicted)
        if(scheme_predicted(i, 5) == scene_predicted(j, 5))
            scene_res_props = regionprops(labeled_scene == scene_predicted(j, 4), "BoundingBox", "MaxFeretProperties", "Orientation","Centroid");
            scheme_res_props = regionprops(labeled_scheme == scheme_predicted(i, 4), "BoundingBox", "MaxFeretProperties", "Centroid", "Orientation");
            orientationDiff = scene_res_props.Orientation - scheme_res_props.Orientation
            
            scaleF = scheme_res_props.MaxFeretDiameter / scene_res_props.MaxFeretDiameter;
            subImageMask = imcrop(labeled_scene== scene_predicted(j, 4), scene_res_props.BoundingBox);
            subImage = imcrop(image, scene_res_props.BoundingBox);
            
            color_region(subImage, subImageMask);
            
                schemeSubImage = imcrop(labeled_scheme== scheme_predicted(i, 4), scheme_res_props.BoundingBox);
                immagineScena = imresize(subImageMask, scaleF);

                [ angle, mirror] =  bruteForce(immagineScena, schemeSubImage, scene_predicted(j, 5));
                 if(mirror== 1)
                    subImageMask = flip(subImageMask,2);
                    subImage = flip(subImage,2);
                 end
            
%             movingRegistered = imwarp(uint8(subImageMask),tform,'OutputView',imref2d(size(uint8(schemeSubImage))));
         
%             imshowpair(uint8(schemeSubImage), tform,'Scaling','joint')
            
             maskRotated = imrotate(subImageMask,angle);
              imRotated = imrotate(subImage, angle);
%             angle_props = regionprops(maskRotated, "MaxFeretProperties");
%             
%             disp("angolo schema"+ scheme_res_props.MaxFeretAngle);
%             disp("angolo ruotata"+ angle_props.MaxFeretAngle);
             imRotated = imresize(imRotated, scaleF);
             maskRotated = imresize(maskRotated, scaleF);
             %bruteForce(maskRotated, schemeSubImage,scene_predicted(j, 5));

             piece = color_region(imRotated, maskRotated);
%             figure, subplot(1,2,1), imshow(labeled_scheme == scheme_predicted(i, 4)), hold on,plot(scheme_res_props.Centroid(1),scheme_res_props.Centroid(2), "r*");
%             subplot(1,2,2), imshow(imRotated), hold on,plot(scene_res_props.Centroid(1),scene_res_props.Centroid(2), "r*");
            
            
            % Translation
            up = round(scheme_res_props.Centroid(2) - size(imRotated, 1) / 2);
            bottom = round(scheme_res_props.Centroid(2) + size(imRotated, 1) / 2);
            left = round(scheme_res_props.Centroid(1) - size(imRotated, 2) / 2);
            right = round(scheme_res_props.Centroid(1) + size(imRotated, 2) / 2);
            
            sup = imschemergb;
            sup(up:bottom-1, left:right-1, :) = sup(up:bottom-1, left:right-1, :) .* double(1 - maskRotated);
            sup(up:bottom-1, left:right-1, :) = sup(up:bottom-1, left:right-1, :) + piece;
            figure, imshow(sup)
                        
        end    
    end
end

function region = color_region(im, mask)
    mask3 = double(repmat(mask,[1,1,3]));
    region = im2double(im) .* mask3;
    %figure, imshow(region);
end