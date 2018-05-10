function [tpr, fpr, tnr, fnr, accuracy] = calculate_accuracy( confidences, labels)

correct_classification = sign(confidences .* labels);
accuracy = 1 - sum(correct_classification <= 0)/length(correct_classification);
fprintf('  accuracy:   %.3f\n', accuracy);

true_positives = (confidences >= 0) & (labels >= 0);
tp = sum( true_positives ) ;

false_positives = (confidences >= 0) & (labels < 0);
fp = sum( false_positives );

true_negatives = (confidences < 0) & (labels < 0);
tn = sum( true_negatives );

false_negatives = (confidences < 0) & (labels >= 0);
fn = sum( false_negatives );

tpr = tp/(tp+fn);
fpr = fp/(fp+tn);
tnr = tn/(fp+tn);
fnr = fn/(tp+fn);

fprintf('  true  positive rate: %.3f\n', tpr);
fprintf('  false positive rate: %.3f\n', fpr);
fprintf('  true  negative rate: %.3f\n', tnr);
fprintf('  false negative rate: %.3f\n', fnr);



