% Apply binary mask to RGB image
function region = color_region(im, mask)
    mask3 = double(repmat(mask,[1,1,3]));
    region = im2double(im) .* mask3;
end