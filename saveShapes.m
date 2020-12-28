function saveShapes(imrgb, numberImage)
     imycbcr = rgb2ycbcr(imrgb);
    imhsv = rgb2hsv(imrgb);

    c1 = imycbcr(:,:,1) > 190;   % A, H
    c2 = imycbcr(:,:,2) > 130;   % F, E
    c3 = imycbcr(:,:,3) > 170;   % B, D
    c4 = imrgb(:,:,2) > 190; % G
    c5 = imhsv(:,:,3) < 0.35;   % C
    
    se = strel("square", 10);
    c5 = imclose(c5, se);
    se = strel("square", 100);
    c5 = imerode(c5, se);
    %c5 = imdilate(c5, se);
    
    imf = c1 + c2 + c3 + c4 + c5;
    se = strel("square", 20);
    imf = imclose(imf, se);
    imf = imerode(imf, se);
    imf = medfilt2(imf,[7 7]);
    
    labeled_im = bwlabel(imf);
    % imagesc(labeled_im);
    cclabels = unique(labeled_im);
    props = [];
    labels = [];
 
    for i=1:length(cclabels)
        figure;imshow(labeled_im == cclabels(i));title(cclabels(i)); 
        box = regionprops(labeled_im == cclabels(i), "BoundingBox");
        subImage = imcrop(labeled_im == cclabels(i), box.BoundingBox);
        subImage = padarray(subImage, [100 100], 0 , 'both');
        imwrite(subImage, "./shapes/"+i+"-"+numberImage+".png");
    end

end