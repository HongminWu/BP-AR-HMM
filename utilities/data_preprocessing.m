function [cellData, meanSigma] = data_preprocessing(cellData)
%--------Preprocess data  mean = 0; variance = 1-----------------
%Smooth trajectory
radius = 10;
for i=1:length(cellData)
     [dims,len] = size(cellData{i});
     smoothed = zeros(dims,len);
     for j=1:dims
         for k=1:len
             low = max(1,k-radius);
             high = min(len,k+radius);
             smoothed(j,k) = mean(cellData{i}(j,low:high));
         end
     end
     cellData{i} = smoothed;
 end
Ybig1 = [];
for ii=1:length(cellData)
    Ybig1 = [Ybig1 cellData{ii}];
end
%Adjust each dim to mean 0
mY = mean((Ybig1'));
for i=1:length(cellData)
    for j=1:length(mY)
        cellData{i}(j,:) = cellData{i}(j,:) - mY(j);
    end
end
Ybig2 = [];
for ii=1:length(cellData)
    Ybig2 = [Ybig2 cellData{ii}];
end
%Renormalize so for each feature, the variance of the first diff is 1.0
%vY = var(diff(Ybig2'));
vY = var(Ybig2');
for i=1:length(cellData)
    for j=1:length(vY)
        cellData{i}(j,:) = cellData{i}(j,:) ./ sqrt(vY(j));
    end
end

Ybig3 = [];
for ii=1:length(cellData)
    Ybig3 = [Ybig3 cellData{ii}];
end
%meanSigma = 5.0 * cov(diff(Ybig3'));  %default: If bad segmentation, try values between 0.75 and 5.0
meanSigma =  5.0 * cov(Ybig3');  %Hongmin Wu: If bad segmentation, try values between 0.75 and 5.0
for i=1:size(meanSigma,1)
    for j=1:size(meanSigma,2)
        if(i~=j) 
            meanSigma(i,j) = 0;
        end
    end
end
sig0 = meanSigma;  %Only needed for MNIW-N prior
end