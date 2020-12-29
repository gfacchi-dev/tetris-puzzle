function [props, labels] = getData()
close all
    fileList = dir("./shapes")
   
    props=[];
    labels=[];
     for i=3:length(fileList)
        if(not(strcmp(fileList(i).name, ".")) && not(strcmp(fileList(i).name,"..")))
            for j=1:8
                path = "./shapes/"+fileList(i).name;
                lettera = char(fileList(i).name);
                lettera= lettera(1);
                image = imread(path);
                image = imrotate(image, 90*j/2);
                %poly reduction ---------------------------------
                [B, L] = bwboundaries(image, 'noholes');
                boundary = B{1};
              %  figure; imshow(image)
%                 hold on
%                 visboundaries({boundary})
%                 xlim([min(boundary(:,2))-10 max(boundary(:,2))+10])
%                 ylim([min(boundary(:,1))-10 max(boundary(:,1))+10])

                tolerance = 0.08;
                p_reduced = reducepoly(boundary,tolerance);
%                 line(p_reduced(:,2),p_reduced(:,1), 'color','b','linestyle','-','linewidth',1.5, 'marker','o','markersize',5);
%                 hold off

                [X, Y] = size(image);
                simplified = zeros(X, Y);
                simplified = roipoly(simplified, p_reduced(:,2),p_reduced(:,1));
%                 figure,subplot(1,2,1), imshow(image),subplot(1,2,2), imshow(simplified);
                
                %-----------------------------------------------------
                 im_props = regionprops(image, "All");
                 corners = detectHarrisFeatures(simplified, "MinQuality", 0.35, "FilterSize", 11);
                 labels = [labels; lettera];
%im_props.Area/im_props.Perimeter^2
           %props = [props; im_props.Eccentricity numel(im_props.ConvexHull)/im_props.Perimeter  im_props.Solidity im_props.Circularity im_props.EulerNumber im_props.Area/im_props.Perimeter^2];
      props = [props; corners.Count/8  im_props.Eccentricity   im_props.Area/im_props.Perimeter^2  ];
            end
             end
     end
end