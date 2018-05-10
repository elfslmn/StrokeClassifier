classdef Shape
    properties
        strokeData = []; % struct('Vertices',[],'X',[],'Y',[],'Pressure', [],'Time',[],'Label',0,'Frequency',0);
    end
    properties (Dependent = true, SetAccess = private)
        strokeCount
    end

    methods (Static = true)
        function shape = CreateShapeFromMatrix(data, labelVec, freqBin, strs) 
            shape = Shape();
            if nargin < 4
                strs = unique(data(:,1))'; 
            end
            n = length(strs);
                                 
            for i = 1: n
               indices = find(data(:,1) == strs(1,i));
               if(isempty(labelVec))
                   label = inf;
               else
                   label = labelVec(strs(1,i)+1);
               end
               shape = shape.AddStroke(data(indices,2:5),label);
            end 
            
            % calculate frequency features
            freqs = zeros(n,1);
            strokes = shape.strokeData;
            for i = 1: n - freqBin +1
                fftCount = Helper.getFrequencyFeature(strokes(i:i+freqBin-1));
                freqs(i:i+freqBin-1) = freqs(i:i+freqBin-1)+ fftCount;
            end  
             % scale frequency features
            for i = 2: freqBin-1
                freqs(i) = freqs(i)/i;
                freqs(n-i+1) = freqs(n-i+1)/i;
            end
            for i = freqBin:n-freqBin+1
                freqs(i) = freqs(i)/freqBin;
            end
            %assign frequency features
            for i = 1: n
                shape.strokeData(i).Frequency = freqs(i);
            end
                  
        end
    end
    
    methods
        function shape = Shape()
        end
        
        function value = get.strokeCount(shape)
            value = length(shape.strokeData);
        end
        
        function stroke = GetStroke(shape, strokeId)
            if strokeId <= shape.strokeCount
                stroke = shape.strokeData(strokeId).Vertices;
            end
        end
        
        function shape = AddStroke(shape, points, label)
            if ~ismatrix(points)
                error('Shape:AddStroke', 'points should be a matrix');
            end
            if isempty(shape.strokeData)
               shape.strokeData = struct('Vertices',[],'X',[],'Y',[],'Pressure', [],'Time',[],'Label',0,'Frequency',0);
               shape.strokeData(1).Vertices = [points(:,1)', points(:,2)'] ;
               shape.strokeData(1).X = points(:,1);
               shape.strokeData(1).Y = points(:,2);
               shape.strokeData(1).Pressure = points(:,3);
               shape.strokeData(1).Time = points(:,4);
               shape.strokeData(1).Label = label;
     
            else
                index =length(shape.strokeData) + 1;
                shape.strokeData(index).Vertices = [points(:,1)', points(:,2)'] ;
                shape.strokeData(index).X = points(:,1);
                shape.strokeData(index).Y = points(:,2);
                shape.strokeData(index).Pressure = points(:,3);
                shape.strokeData(index).Time = points(:,4);
                shape.strokeData(index).Label = label;
                
            end
        end
   
        function shape = PlotOutline(shape, createNewFigure)
             if nargin < 2
                createNewFigure = true;
            end
            if createNewFigure
                figure, hold on;
            else 
                hold on;
            end
            
            for i = 1:shape.strokeCount
                L = shape.strokeData(i).Label;
                if L == 1
                     stroke = shape.GetStroke(i);  
                     X = GetX(stroke);
                     Y = GetY(stroke);
                    for j = 1:length(X)-1
                        %p = plot([X(j), X(j+1)], [Y(j), Y(j+1)], '-', 'LineWidth',7);
                        p=plot([X(j), X(j+1)], [-Y(j), -Y(j+1)]);
                        set(p, 'Color',[0,0,0]);
                        p.LineWidth = 2;
                    end
                end
            end
            title("True Labels(Bold-outline , Thin-shading)");
            if createNewFigure
                hold off;
            end            
        end
              
        function shape = AddShadingToPlot(shape)
            hold on;
            for i = 1:shape.strokeCount
                L = shape.strokeData(i).Label;
                if L == -1
                     stroke = shape.GetStroke(i);  
                     X = GetX(stroke);
                     Y = GetY(stroke);
                    for j = 1:length(X)-1
                        %p = plot([X(j), X(j+1)], [Y(j), Y(j+1)], '-', 'LineWidth',7);
                        p=plot([X(j), X(j+1)], [-Y(j), -Y(j+1)]);
                        set(p, 'Color',[0.5,0.5,0.5]);
                    end
                end
            end
            hold off;
        end
        
        function shape = PlotTestShape(shape, predictions)
            figure, hold on;
            for i = 1:shape.strokeCount
                truth = shape.strokeData(i).Label;
                predicted = predictions(i);
                if truth == 1
                     stroke = shape.GetStroke(i);  
                     X = GetX(stroke);
                     Y = GetY(stroke);
                    for j = 1:length(X)-1
                        %p = plot([X(j), X(j+1)], [Y(j), Y(j+1)], '-', 'LineWidth',7);
                        p=plot([X(j), X(j+1)], [-Y(j), -Y(j+1)]);
                        if predicted == 1
                            set(p, 'Color',[0,0,0]);
                        else
                            set(p, 'Color',[0.7,0,0]);
                        end
                        p.LineWidth = 2;
                    end
                end
                if truth == -1
                     stroke = shape.GetStroke(i);  
                     X = GetX(stroke);
                     Y = GetY(stroke);
                    for j = 1:length(X)-1
                        %p = plot([X(j), X(j+1)], [Y(j), Y(j+1)], '-', 'LineWidth',7);
                        p=plot([X(j), X(j+1)], [-Y(j), -Y(j+1)]);
                        if predicted == 1
                            set(p, 'Color',[0.7,0,0]);
                        else
                            set(p, 'Color',[0.5,0.5,0.5]);
                        end
                        
                    end
                end
                title("Predicted Labels(Bold-outline , Thin-shading),(Black-true, Red-false)");
                
            end
            hold off;
        end
    end
end

function X = GetX(stroke)
    n = length(stroke) / 2;
    X = stroke(1:n);
end

function Y = GetY(stroke)
    n = length(stroke) / 2;
    Y = stroke(n+1:end);
end
