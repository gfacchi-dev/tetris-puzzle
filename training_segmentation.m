% training_segmentation binarizes imrgb in order to mark tetris pieces as
% foreground and the rest as background.
function [values, labels] = training_segmentation(imrgb)
    imycbcr = rgb2ycbcr(imrgb);
    imhsv = rgb2hsv(imrgb);

    c1 = imycbcr(:,:,1) > 190;   
    c2 = imycbcr(:,:,2) > 130;   
    c3 = imycbcr(:,:,3) > 170;   
    c4 = imrgb(:,:,2) > 190; 
    c5 = imhsv(:,:,3) < 0.35;
    
    se = strel("square", 10);
    c5 = imclose(c5, se);
    se = strel("square", 50);
    c5 = imerode(c5, se);
    c5 = imdilate(c5, se);
    
    imf = c1 + c2 + c3 + c4 + c5;
    se = strel("square", 20);
    imf = imclose(imf, se);
    imf = imopen(imf, se);
    imf = medfilt2(imf,[7 7]);
    labels = bwlabel(imf);
    labels(labels~=0) = 1;
    
    % Create Descriptor (G, B, Y, Cb, Cr)
    values = double(cat(3, imrgb(:, :, 2:3), imycbcr));
    [r, c, ch] = size(values);
    values = reshape(values, r*c, ch);
    labels = reshape(labels, r*c, 1);
end