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
    scene_props = [scene_props;  corners.Count/8 im_props.Eccentricity  im_props.Area/im_props.Perimeter^2 scene_labels(i)]
    
end

% SCHEMA
imscheme = rgb2gray(im2double(imread("S04.jpg")));
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
            figure, imshow(maskedRgbImage),  title(label);
        end     
    end
end
scheme_predicted = [];
for i=1:length(scheme_props)
      props = scheme_props(i,:);
      label=predict(classifier_knn,props(1:end-1));
      figure, imshow(labeled_scheme==props(end)), title(label);
      scheme_predicted = [scheme_predicted; props(1) props(2) props(3) props(4) str2double(label)];
end
% 
% scene_corners= [];
% 
% for i=1:length(scene_predicted)
%     props = regionprops(labeled_scene==scene_predicted(i,4),"BoundingBox");
%     subImage = imcrop(labeled_scene==scene_predicted(i,4), props.BoundingBox);
%     subImage = padarray(subImage, [20 20], 0 , 'both');
%     imshow(subImage);
%      %poly reduction----------------------
%      [B, L] = bwboundaries(subImage, 'noholes');
%      boundary = B{1};
% 
%    
%     %Ramer-Douglas-Peucker algorithm
%      tolerance = 0.08;
%      p_reduced = reducepoly(boundary,tolerance);    
%      [X, Y] = size(subImage);
%      simplified = zeros(X, Y);
%      simplified = roipoly(simplified, p_reduced(:,2),p_reduced(:,1));    
%     %-----------------------------------------
%      corners = detectHarrisFeatures(simplified, "MinQuality", 0.35, "FilterSize", 11);
%      scene_corners = [scene_corners; corners.Location(1)  corners.Location(2)];
% end
% scheme_corners = [];
% for i=1:length(scheme_predicted)
%     props = regionprops(labeled_scheme==scheme_predicted(i,4),"BoundingBox");
%     subImage = imcrop(labeled_scheme==scheme_predicted(i,4), props.BoundingBox);
%     subImage = padarray(subImage, [20 20], 0 , 'both');
%     imshow(subImage);
%      %poly reduction----------------------
%      [B, L] = bwboundaries(subImage, 'noholes');
%      boundary = B{1};
% 
%    
%     %Ramer-Douglas-Peucker algorithm
%      tolerance = 0.08;
%      p_reduced = reducepoly(boundary,tolerance);    
%      [X, Y] = size(subImage);
%      simplified = zeros(X, Y);
%      simplified = roipoly(simplified, p_reduced(:,2),p_reduced(:,1));    
%     %-----------------------------------------
%      corners = detectHarrisFeatures(simplified, "MinQuality", 0.35, "FilterSize", 11);
%      scheme_corners = [scheme_corners; corners];
% end

for i=1:length(scheme_predicted)
    for j=1:length(scene_predicted)
        if(scene_predicted(j, 5) == scheme_predicted(i, 5))
              corners_scene=get_corners(labeled_scene, scene_predicted(j, 4));
              corners_scheme=get_corners(labeled_scheme, scheme_predicted(i, 4));
%               transform = pcregistercpd(corners_scene.Location, corners_scheme.Location );
% %               Rfixed = imref2d(size(imscheme));
% %               registered = imwarp(subImage,transform,'OutputView',Rfixed);
% %               imshowpair(imscheme,registered,'blend')
%               pcshowpair(transform ,corners_scheme.Location,'MarkerSize',50)
%                 [mp,fp] = cpselect(labeled_scene==scene_predicted(j, 4), imscheme ,'Wait',true);
%                 t = fitgeotrans(mp,fp,'projective');
%                 Rfixed = imref2d(size(imscheme));
%                 registered = imwarp(labeled_scene==scene_predicted(j, 4),t,'OutputView',Rfixed);
%                 imshowpair(imscheme,registered,'blend')
                     indexPairs = matchFeatures(corners_scheme.Location, corners_scene.Location);
                     [tform, inlierIdx] = estimateGeometricTransform2D(...
                                corners_scene, corners_scheme, 'similarity');
                            
                      outputView = imref2d(size(imscheme));
                        recovered  = imwarp(labeled_scene==scene_predicted(j, 4),tform,'OutputView',outputView);
                        figure, imshowpair(imscheme,recovered,'montage')

        end
    
    
    end
end



