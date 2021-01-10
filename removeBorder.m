function out = removeBorder(image)
    
   props=regionprops(image, 'BoundingBox');
   out = imcrop(image, props.BoundingBox);
   
end
