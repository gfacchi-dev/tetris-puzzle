function [props, labels] = training_shapes(imrgb, imageNumber)
    imycbcr = rgb2ycbcr(imrgb);
    imhsv = rgb2hsv(imrgb);

    c1 = imycbcr(:,:,1) > 190;   % A, H
    c2 = imycbcr(:,:,2) > 130;   % F, E
    c3 = imycbcr(:,:,3) > 170;   % B, D
    c4 = imrgb(:,:,2) > 190; % G
    c5 = imhsv(:,:,3) < 0.35;   % C
    
    se = strel("square", 10);
    c5 = imclose(c5, se);
    se = strel("square", 50);
    c5 = imerode(c5, se);
    c5 = imdilate(c5, se);
    
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
    j=0;
    if(imageNumber == 1)
        j=2;
    else
        j=1;
    end
    for i=j:length(cclabels)
        %figure;imshow(labeled_im == cclabels(i));title(cclabels(i)); 
        
            corners = detectHarrisFeatures(labeled_im == cclabels(i), "MinQuality", 0.7, "FilterSize", 15);
            im_props = regionprops(labeled_im == cclabels(i), "Circularity","Eccentricity","Extent");
            
            props = [props; corners.Count im_props.Circularity im_props.Eccentricity im_props.Extent];
            if(imageNumber==1)
                if(i==8||i==10)
                    labels=[labels;cclabels(i-1)];
                else
                    labels = [labels;cclabels(i)];
                end
            elseif(i<11)
                  if(i == 2 || i==4)
             labels = [labels; cclabels(11-i+1)];
            else
                labels = [labels;cclabels(11-i)];
            end
            end
          
            
    end
end