clear all;
close all;

load("classifier_bayes.mat");
load("classifier_knn.mat");

% SCENA
image = imread("P02.jpg");
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
    scene_props = [scene_props;  corners.Count/8 im_props.Eccentricity  im_props.Area/im_props.Perimeter^2 scene_labels(i)];
    
end

% SCHEMA
imschemergb = im2double(imread("S04.jpg"));
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
            scene_res_props = regionprops(labeled_scene == scene_predicted(j, 4), "BoundingBox", "MaxFeretProperties");
            scheme_res_props = regionprops(labeled_scheme == scheme_predicted(i, 4), "BoundingBox", "MaxFeretProperties", "Centroid");
                    
            % Scene CROP
            subSceneMask = imcrop(labeled_scene == scene_predicted(j, 4), scene_res_props.BoundingBox);
            subSceneImage = imcrop(image, scene_res_props.BoundingBox);
            
            % Scheme CROP
            subSchemeMask = imcrop(labeled_scheme == scheme_predicted(i, 4), scheme_res_props.BoundingBox);
                      
            % Scene ROTATION          
            sceneMaskRotated = imrotate(subSceneMask, -(scheme_res_props.MaxFeretAngle - scene_res_props.MaxFeretAngle));
            sceneMaskFlipped = fliplr(subSceneMask);
            angle = bwferet(sceneMaskFlipped, "MaxFeretProperties").MaxAngle(1);
            sceneMaskFR = imrotate(sceneMaskFlipped, -(scheme_res_props.MaxFeretAngle - angle)); 
            
            subSceneRotated = imrotate(subSceneImage, -(scheme_res_props.MaxFeretAngle - scene_res_props.MaxFeretAngle));
            subSceneFlipped = fliplr(subSceneImage);
            subSceneFR = imrotate(subSceneFlipped, -(scheme_res_props.MaxFeretAngle - angle));
            
            
            %%% ROTATIONS %%%
            figure
            
            out = bwferet(sceneMaskRotated, "MaxFeretProperties");
            subplot(2, 2, 1), h = imshow(sceneMaskRotated), title("RUOTATA  " + out.MaxAngle(1))
            axis = h.Parent;
            xmin = [out.MaxCoordinates{1}(1,1) out.MaxCoordinates{1}(2,1)];
            ymin = [out.MaxCoordinates{1}(1,2) out.MaxCoordinates{1}(2,2)];
            imdistline(axis,xmin,ymin); 
                       
            out = bwferet(sceneMaskFR, "MaxFeretProperties");
            subplot(2, 2, 2), h = imshow(sceneMaskFR), title("FLIPPED E RUOTATA  " + out.MaxAngle(1))
            axis = h.Parent;
            xmin = [out.MaxCoordinates{1}(1,1) out.MaxCoordinates{1}(2,1)];
            ymin = [out.MaxCoordinates{1}(1,2) out.MaxCoordinates{1}(2,2)];
            imdistline(axis,xmin,ymin); 
            
            out = bwferet(subSchemeMask, "MaxFeretProperties");
            subplot(2, 2, 3), h = imshow(subSchemeMask), title("SCHEMA  " + scheme_res_props.MaxFeretAngle)
            axis = h.Parent;
            xmin = [out.MaxCoordinates{1}(1,1) out.MaxCoordinates{1}(2,1)];
            ymin = [out.MaxCoordinates{1}(1,2) out.MaxCoordinates{1}(2,2)];
            imdistline(axis,xmin,ymin); 
            
            % SCALING
            scaleF = scheme_res_props.MaxFeretDiameter / scene_res_props.MaxFeretDiameter;
            
            subSceneRotated = imresize(subSceneRotated, scaleF);
            sceneMaskRotated = imresize(sceneMaskRotated, scaleF);
            sceneMaskFR = imresize(sceneMaskFR, scaleF);
                        
%             isFlipped = (sum(sum(subSchemeMask .* sceneMaskFR)) > sum(sum(subSchemeMask .* sceneMaskRotated)));
%              
%             if (isFlipped)
%                 piece = color_region(subSceneFR, sceneMaskFR);
%             else
%                 piece = color_region(subSceneRotated, sceneMaskRotated);
%             end          
            
            piece = color_region(subSceneRotated, sceneMaskRotated);

            % Translation
            up = round(scheme_res_props.Centroid(2) - size(subSceneRotated, 1) / 2);
            bottom = round(scheme_res_props.Centroid(2) + size(subSceneRotated, 1) / 2);
            left = round(scheme_res_props.Centroid(1) - size(subSceneRotated, 2) / 2);
            right = round(scheme_res_props.Centroid(1) + size(subSceneRotated, 2) / 2);
            
            sup = imschemergb;
            sup(up:bottom-1, left:right-1, :) = sup(up:bottom-1, left:right-1, :) .* double(1 - sceneMaskRotated);
            sup(up:bottom-1, left:right-1, :) = sup(up:bottom-1, left:right-1, :) + piece;
            % figure, imshow(sup)
        end    
    end
end

function region = color_region(im, mask)
    mask3 = double(repmat(mask,[1,1,3]));
    region = im2double(im) .* mask3;
    %figure, imshow(region);
end