% TRAINING 
im1 = imread("training/R01.jpg");
im2 = imread("training/R02.jpg");

% Pixel-Based (colors)
% Bayesian Classifier
[v1, l1] = training_segmentation(im1);
[v2, l2] = training_segmentation(im2);
train_values = [v1; v2];
train_labels = [l1; l2];
classifier_bayes = fitcnb(train_values, train_labels);

% Shapes properties
% KNN Classifier
[train_props_values, train_props_labels] = load_shapes("./training_shapes/");
classifier_knn = fitcknn(train_props_values, train_props_labels, 'NumNeighbors' , 1);

save("classifier_bayes.mat", "classifier_bayes");
save("classifier_knn.mat", "classifier_knn");