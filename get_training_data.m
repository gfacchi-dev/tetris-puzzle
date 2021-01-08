function [props, labels] = get_training_data()
    % training_shapes directory contains all 20 tetris pieces extracted by
    % segmentation from training images
    file_list = dir("./training_shapes");
    props = [];
    labels = [];
     for i = 3:length(file_list)
        if(not(strcmp(file_list(i).name, ".")) && not(strcmp(file_list(i).name,"..")))
            path = "./shapes/" + file_list(i).name;
            % Associate a label in relation to filename
            lettera = char(file_list(i).name);
            lettera = lettera(1);
            image = imread(path);
            
            % Create descriptor (# corners, eccentricity and ratio area/perimeter^2)
            im_props = regionprops(image, "Eccentricity", "Area", "Perimeter");
            corners = get_corners(image);
            labels = [labels; lettera];
            props = [props; corners.Count/8  im_props.Eccentricity  im_props.Area/im_props.Perimeter^2];
        end
     end
end