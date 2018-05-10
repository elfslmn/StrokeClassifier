%
%% 1- Read data files
close all
clear

d=dir('data');
folders=d(~ismember({d.name},{'.','..'}));
drawings = cell(24,1);
labels= cell(24,1);
index =1;
for i = 1:length(folders)
    paths = dir( fullfile( folders(i).folder, folders(i).name, '*.csv') );
    for j = 1: length(paths)
        drawings{index,1}= csvread(fullfile(paths(j).folder,paths(j).name));
        C=strsplit(paths(j).name,'.');
        c = strcat(C{1,1},'.txt');
        try
        id = fileread(fullfile(paths(j).folder, c )) ;
        l =textscan(id,'%d');
        labels{index,1} = l{1,1} ; 
        catch
            labels{index,1} = []; 
        end
        index = index+1;
    end
end

%% 2- Construct shape objects
freqBin = 5;
shapes = cell(24,1);
for i = 1: 24
    data = Helper.reducePointsByTime(drawings{i,1});
    shapes{i,1} = Shape.CreateShapeFromMatrix(data, labels{i,1}, freqBin);
end

%% 3- Group strokes
% 1= outline , -1=Shading

posStrokes = []; 
posInd=1;
posStrokes = struct('Vertices',[],'X',[],'Y',[],'Pressure', [],'Time',[] ,'Label',0,'Frequency',0);

negStrokes = []; 
negInd=1;
negStrokes = struct('Vertices',[],'X',[],'Y',[],'Pressure', [],'Time',[] ,'Label',0,'Frequency',0);

test = 1;
for i = 1:24
    if i==test  % remove one of them for test drawing
        continue;
    end
    for j = 1: shapes{i,1}.strokeCount
        label = shapes{i,1}.strokeData(j).Label;
        if(label == 1)
            posStrokes(posInd) = shapes{i,1}.strokeData(j);
            posInd = posInd + 1;
        end
        if (label == -1)
%             if(negInd == 1179)
%                 continue;
%             end
            negStrokes(negInd) = shapes{i,1}.strokeData(j);
            negInd = negInd + 1;         
        end           
    end
end
Npos = posInd-1;
Nneg = negInd -1;

%% 4- Get features ( pathLength + 20 curvature + 20 speed + 20 pressure = 61 features )
binSize = 20;
fsize = 3*binSize +2;
fstr =sprintf('pathLength + fftCount+ %d curvature + %d speed + %d pressures= %d',binSize,binSize,binSize,fsize );

posFeatures = zeros(length(posStrokes) , fsize );
for i = 1: length(posStrokes)
    stroke = posStrokes(i);
    posFeatures(i,1) = Helper.getPathLength(stroke);
    posFeatures(i,2) = stroke.Frequency;
    
    curvatures = Helper.getCurvatures(stroke);
    posFeatures(i,3:(binSize+2)) = Helper.equalizeFeatureSizes(curvatures, binSize);
    
    speeds = Helper.getSpeeds(stroke);
    posFeatures(i,(binSize+3):(2*binSize+2)) = Helper.equalizeFeatureSizes(speeds, binSize);
    
    posFeatures(i,(2*binSize+3):(3*binSize+2)) = Helper.equalizeFeatureSizes(stroke.Pressure, binSize);
end

negFeatures = zeros(length(negStrokes) , fsize );
for i = 1: length(negStrokes)
    stroke = negStrokes(i);
    negFeatures(i,1) = Helper.getPathLength(stroke);
    negFeatures(i,2) = stroke.Frequency;
    
    curvatures = Helper.getCurvatures(stroke);
    negFeatures(i,3:(binSize+2)) = Helper.equalizeFeatureSizes(curvatures, binSize);
    
    speeds = Helper.getSpeeds(stroke);
    negFeatures(i,(binSize+3):(2*binSize+2)) = Helper.equalizeFeatureSizes(speeds, binSize);
    
    negFeatures(i,(2*binSize+3):(3*binSize+2)) = Helper.equalizeFeatureSizes(stroke.Pressure, binSize);
end

%% 5- normalize data
input = vertcat(posFeatures, negFeatures);
input(:,1) = (input(:,1) - mean(input(:,1)))./ std(input(:,1));
input(:,2) = (input(:,2) - mean(input(:,2)))./ std(input(:,2));

%% 6- train classifier
posFeatures = input(1:Npos,:);
negFeatures = input(Npos+1:end,:);

lambda = 0.0001;

training_ratio = 0.9;
Ntrain_pos = ceil(Npos * training_ratio) ;
Ntrain_neg = ceil(Nneg * training_ratio) ;
%Ntrain_neg = ceil(Npos * training_ratio) ; %make equal size pos and neg 
X = vertcat(posFeatures(1:Ntrain_pos,:), negFeatures(1:Ntrain_neg,:))';

%Y is 1 for positive features and -1 for negative features
Y = horzcat(ones(1, Ntrain_pos), ones(1, Ntrain_neg) * -1);

% create a structure with kernel map parameters
hom.kernel = 'KChi2';
hom.order = 2;  %-> makes w = 336 (48*7)
dataset = vl_svmdataset(X, 'homkermap', hom);
[w, b, info,conf] = vl_svmtrain(dataset, Y, lambda);
% [w, b, info,conf] = vl_svmtrain(X, Y, lambda);
disp(info);

%% 7- Training Accuracy
fprintf('Initial classifier performance on train data:\n')

confidences = conf';
label_vector = [ones(Ntrain_pos,1); -1*ones(Ntrain_neg,1)];
[train_tp, train_fp, train_tn, train_fn, train_acc] =  calculate_accuracy( confidences, label_vector );

%% 8 - Test
Ntest_pos = Npos - Ntrain_pos;
Ntest_neg = Nneg - Ntrain_neg;

pos_test = posFeatures(Ntrain_pos+1:end,:);
neg_test = negFeatures(Ntrain_neg+1:end,:);

pos_scores = (vl_homkermap((pos_test'),2)')*w + b;
neg_scores = (vl_homkermap((neg_test'),2)')*w + b;
% pos_scores = pos_test*w + b;
% neg_scores = neg_test*w + b;

pos_predict = zeros(Ntest_pos,1);
trues=find(pos_scores>=0);
tp = size(trues,1);
pos_predict(trues)=1;

neg_predict = zeros(Ntest_neg,1);
trues=find(neg_scores<0);
fp = size(trues,1);
neg_predict(trues)=1;

scores= vertcat(pos_scores, neg_scores );
label= [ones(Ntest_pos,1); -1*ones(Ntest_neg,1)];
fprintf('performance on test data:\n')
[test_tp, test_fp, test_tn, test_fn, test_acc] =  calculate_accuracy(scores , label);

%% 9 - Write the report to text file
fid = fopen ('report_accuracy.txt','a');
fprintf(fid, strcat(datestr(datetime('now')),'\n\n'));

fprintf(fid, sprintf('Total stroke = %d \n',Npos+Nneg));
fprintf(fid, sprintf('Positive = %d \n',Npos));
fprintf(fid, sprintf('Negative = %d \n\n',Nneg));

fprintf(fid, sprintf('Training ratio = %.2f\n',training_ratio));
fprintf(fid, sprintf('Positive strokes: Training=%d  Test=%d \n',Ntrain_pos, Ntest_pos));
fprintf(fid, sprintf('Negative strokes: Training=%d  Test=%d \n\n',Ntrain_neg, Ntest_neg));

fprintf(fid, sprintf('Frequency calculation bin size = %d \n',freqBin));
fprintf(fid, sprintf('lambda = %.1E \n',lambda));
fprintf(fid, strcat('Features: ',fstr,'\n')); %features
fprintf(fid, strcat('Kernel: ',hom.kernel, sprintf('  Order=%d',hom.order),'\n\n')); %features

fprintf(fid, 'PERFORMANCE\n');
fprintf(fid, 'On Training Data\n');
fprintf(fid,'accuracy:   %.3f\n', train_acc);
fprintf(fid,'true  positive rate: %.3f\n',train_tp);
fprintf(fid,'false  positive rate: %.3f\n',train_fp);
fprintf(fid,'true  negative rate: %.3f\n',train_tn);
fprintf(fid,'false  negative rate: %.3f\n\n',train_fn);

fprintf(fid, 'On Test Data\n');
fprintf(fid,'accuracy:   %.3f\n', test_acc);
fprintf(fid,'true  positive rate: %.3f\n',test_tp);
fprintf(fid,'false  positive rate: %.3f\n',test_fp);
fprintf(fid,'true  negative rate: %.3f\n',test_tn);
fprintf(fid,'false  negative rate: %.3f\n\n',test_fn);

fprintf(fid,'--------------------------------------\n\n');
fclose(fid);

%% Extra- try a test shape and plot
shape = shapes{test,1};
PlotOutline(shape,true);
AddShadingToPlot(shape);
strokes = shape.strokeData;
features = zeros(length(strokes) , fsize );
truth = zeros(length(strokes), 1);

for i = 1: length(strokes)
    stroke = strokes(i);
    features(i,1) = Helper.getPathLength(stroke);
    features(i,2) = stroke.Frequency;
    
    curvatures = Helper.getCurvatures(stroke);
    features(i,3:(binSize+2)) = Helper.equalizeFeatureSizes(curvatures, binSize);
    
    speeds = Helper.getSpeeds(stroke);
    features(i,(binSize+3):(2*binSize+2)) = Helper.equalizeFeatureSizes(speeds, binSize);
    
    features(i,(2*binSize+3):(3*binSize+2)) = Helper.equalizeFeatureSizes(stroke.Pressure, binSize);
    
    truth(i,1)= stroke.Label;
end

features(:,1) = (features(:,1) - mean(features(:,1)))./ std(features(:,1));
features(:,2) = (features(:,2) - mean(features(:,2)))./ std(features(:,2));

scores = (vl_homkermap((features'),2)')*w + b;

predictions = zeros(length(strokes), 1);
for i = 1: length(strokes)
    if scores(i) >= 0
        predictions(i) = 1;
    else
        predictions(i) = -1;
    end
end

PlotTestShape(shape,predictions);
calculate_accuracy(scores , truth);







