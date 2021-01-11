clear all;
close all;

load("classifier_knn");

% Load Ground Truths (file name represents the label)
[gt_props, gt_labels] = load_shapes("./shapes_gt/");

% Predict Labels with KNN Classifier
pred_labels = predict(classifier_knn, gt_props);

cm = confmat(gt_labels, pred_labels);

figure, heatmap(cm.cm), title("Confusion Matrix");
figure, heatmap(cm.cm_raw), title("Confusion Matrix");