function [props, labels] = getData()
    fileList = dir("./shapes")
   
    props=[];
    labels=[];
     for i=3:length(fileList)
        if(not(strcmp(fileList(i).name, ".")) && not(strcmp(fileList(i).name,"..")))
            for j=1:16
                 path = "./shapes/"+fileList(i).name;
            lettera = char(fileList(i).name);
            lettera= lettera(1);
            image = imread(path);
            image = imrotate(image, 90*j/6);
            %figure,imshow(image),title(lettera);
             im_props = regionprops(image, "All");
             corners = detectHarrisFeatures(image, "MinQuality", 0.5, "FilterSize", 31);
             labels = [labels; lettera];
%im_props.Area/im_props.Perimeter^2
           %props = [props; im_props.Eccentricity numel(im_props.ConvexHull)/im_props.Perimeter  im_props.Solidity im_props.Circularity im_props.EulerNumber im_props.Area/im_props.Perimeter^2];
      props = [props;  im_props.Eccentricity im_props.Area/im_props.Perimeter^2 im_props.Solidity  im_props.Extent  ];
            end
             end
     end
end