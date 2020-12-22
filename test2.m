[x, y,ch] = size(imrgb);
load('bayesian_model.mat');
test_predicted=predict(classifier_bayes,test_values);

%show_result(image,mask_predicted);



cm = confmat(test_labels,test_predicted);