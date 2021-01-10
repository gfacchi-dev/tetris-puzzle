function [final_image, final_mask] = adjust_piece(scheme_mask, scene_image, scene_mask)
    scene_props = regionprops(scene_mask, "BoundingBox", "MaxFeretProperties");
    scheme_props = regionprops(scheme_mask, "BoundingBox", "MaxFeretProperties", "Centroid");
            
    % MASK FLIP & ROTATION
    % piece_r: rotated
    % piece_r_crop: rotated without resizing (crop overflowing parts)
    % piece_f: flipped
    % piece_fr: flipped and rotated
    % piece_fr_crop: rotated without resizing
    piece_r = imrotate(scene_mask, -(scheme_props.MaxFeretAngle - scene_props.MaxFeretAngle));
    piece_r_crop = imrotate(scene_mask, -(scheme_props.MaxFeretAngle - scene_props.MaxFeretAngle), "crop");
    piece_f = fliplr(scene_mask);
    angle = bwferet(piece_f, "MaxFeretProperties").MaxAngle(1);
    piece_fr = imrotate(piece_f, -(scheme_props.MaxFeretAngle - angle));
    piece_fr_crop = imrotate(piece_f, -(scheme_props.MaxFeretAngle - angle), "crop"); 

    % IMAGE FLIP & ROTATION
    % im_piece_r: rotated
    % im_piece_f: flipped
    % im_piece_fr: flipped and rotated
    im_piece_r = imrotate(scene_image, -(scheme_props.MaxFeretAngle - scene_props.MaxFeretAngle));
    im_piece_f = fliplr(scene_image);
    im_piece_fr = imrotate(im_piece_f, -(scheme_props.MaxFeretAngle - angle));

    % MASK % IMAGE SCALING 
    % Calculate the ratio between feret diameters of scheme and scene shapes
    scaleF = scheme_props.MaxFeretDiameter / scene_props.MaxFeretDiameter;
    im_piece_r = imresize(im_piece_r, scaleF);
    piece_r = imresize(piece_r, scaleF);
    im_piece_fr = imresize(im_piece_fr, scaleF);
    piece_fr = imresize(piece_fr, scaleF);

    % Once the feret of the scene piece and the scheme piece have been
    % aligned with the same angle, the actual right rotation may still be a
    % multiple of 90 degrees of the current one. 
    % Furthermore, we can't know a priori if the piece must be flipped or
    % not.
    % For this reasons, the original piece and the flipped one are checked against
    % the scheme with four possible orientations (steps of 90 degrees).
    % The configuration that produces the highest value of the following
    % ratio, is taken as the best one:
    % (scene_piece INTERSECT scheme_piece) / scene_piece
    
    % max_intersection_R: best ratio produced by original piece
    % max_R: multiplier of 90 that produced the best ratio (among original pieces)
    % max_intersection_FR: best ratio produced by flipped piece
    % max_FR: multiplier of 90 that produced the best ratio (among flipped pieces)
    max_intersection_R = 0;
    max_R = -1;
    max_FR = -1;
    max_intersection_FR = 0;
    
    % Force the piece of the scene to be the same size of the scheme one,
    % in order to make comparison
    piece_r_crop = remove_border(piece_r_crop);
    piece_fr_crop = remove_border(piece_fr_crop);
    processFR = imresize(piece_fr_crop, [size(scheme_mask,1) size(scheme_mask,2)]);
    processR = imresize(piece_r_crop, [size(scheme_mask,1) size(scheme_mask,2)]);
    
    for k = 0:3    
        intersection = sum(sum(imrotate(processFR, k * 90, "crop") .* scheme_mask)) / sum(sum(processFR));
        if (intersection > max_intersection_FR)
            max_intersection_FR = intersection;
            max_FR = k;
        end
    end
    
    for k = 0:3    
        intersection = sum(sum(imrotate(processR, k * 90, "crop") .* scheme_mask)) / sum(sum(processR));
        if (intersection > max_intersection_R)
            max_intersection_R = intersection;
            max_R = k;
        end
    end

    % Return image and its related mask with the best configuration
    if (max_intersection_R > max_intersection_FR)
        final_mask = imrotate(piece_r, max_R * 90);
        final_image = imrotate(im_piece_r, max_R * 90);
    else               
        final_mask = imrotate(piece_fr, max_FR * 90);
        final_image = imrotate(im_piece_fr, max_FR * 90);
    end
end