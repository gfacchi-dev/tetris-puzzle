% TRAINING 
im1 = imread("R01.jpg");
im2 = imread("R02.jpg");

% Colors
% [v1, l1] = training_segmentation(im1);
% [v2, l2] = training_segmentation(im2);
% train_values = [v1; v2];
% train_labels = [l1; l2];
% classifier_bayes = fitcnb(train_values, train_labels);

% Shapes
[p1, l1] = training_shapes(im1);
[p2, l2] = training_shapes(im2);
train_props_values = [p1; p2];
train_props_labels = [l1; l2];
classifier_knn = fitcknn(train_props_values, train_props_labels);

% save("classifier_bayes.mat", "classifier_bayes");
save("classifier_knn.mat", "classifier_knn");