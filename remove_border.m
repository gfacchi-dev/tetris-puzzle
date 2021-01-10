function out = remove_border(image)
   props = regionprops(image, "BoundingBox");
   out = imcrop(image, props.BoundingBox);
end
