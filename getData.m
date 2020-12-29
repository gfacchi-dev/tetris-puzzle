function [props, labels] = getData()
close all
    fileList = dir("./shapes")
    props=[];
    labels=[];
     for i=3:length(fileList)
        if(not(strcmp(fileList(i).name, ".")) && not(strcmp(fileList(i).name,"..")))
            for j=1:1
                path = "./shapes/"+fileList(i).name;
                lettera = char(fileList(i).name);
                lettera= lettera(1);
                image = imread(path);
                image = imrotate(image, 90*j/2);
                %poly reduction ---------------------------------
                [B, L] = bwboundaries(image, 'noholes');
                boundary = B{1};

                tolerance = 0.08;
                p_reduced = reducepoly(boundary,tolerance);
                [X, Y] = size(image);
                simplified = zeros(X, Y);
                simplified = roipoly(simplified, p_reduced(:,2),p_reduced(:,1));                
                %-----------------------------------------------------
                 im_props = regionprops(image, "Eccentricity", "Area", "Perimeter");
                 corners = detectHarrisFeatures(simplified, "MinQuality", 0.35, "FilterSize", 11);
                 labels = [labels; lettera];
                props = [props; corners.Count/8  im_props.Eccentricity   im_props.Area/im_props.Perimeter^2  ];
            end
             end
     end
end