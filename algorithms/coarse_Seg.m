% Written by Zahra Kamranian, 2019
% Copyright (c) 2019, Zahra Kamranian, University of Isfahan (zahra.kamranian@eng.ui.ac.ir)
% All rights reserved
%
% This Function is to oversegment an image to its regions. Then, the neighboring regios with
% weak boundary are merged to create a bigger one.
% Inputs:
% 'image' is an input image for over-segmentation.
% 'full' = 0: adjacency graph on region layer
%       or 1: full connection
% 'thr' shows a criterion (threshold) for the weakness of the boundaries to merge the regions.
% the default is '-0.15. However, based on the dataset, it can be changed to
% get more accurate results.
% Outputs: 
% 'coarseLabel_05' is the image with the regions. Each region has a label.
% 'coarseSeg_05' is the pixels corresponding to each region of the image.
% 'histSP_05' is the histogram of the oversegmented image.
% 'seg_vals_05' is the mean color of each region of the image.
% 'seg_edges_05' is which neighboring regions are in the image.

function [coarseLabel_05, coarseSeg_05, histSP_05, seg_vals_05, seg_edges_05 ] = coarse_Seg(image,full,thr)

coarseLabel_05 = [];
image=imresize(image,[224 224],'nearest'); 
img = image;
nbins = 20;
img_v = double(reshape(img,[],3));
%% oversegmentation using UCM algorithm, 
% P. Arbelaez, M. Maire, C. Fowlkes, J. Malik, 
% "Contour detection and hierarchical image segmentation", PAMI 33 (2011) 898-916.
scale = 1;
[ucm2,labels2,labels] = im2ucm(image,'fast',scale);

%% merge the regions with the line < thr
diff = labels-ucm2;

for i=1:size(diff,1)
    for j=1:size(diff,2)-1
            if diff(i,j)<0 & diff(i,j)>thr 
                lowValWall=diff(i,j);
                if j>1
                    if diff(i,j-1)>0   
                        if diff(i,j+1)>0 
                            savePast=min(diff(i,j-1),diff(i,j+1));
                            changeVal=max(diff(i,j-1),diff(i,j+1));
                            diff(diff==changeVal)=savePast;
                            diff(diff==lowValWall)=savePast; 
                        else
                            savePast1=diff(i,j-1);
                            j=j+1; flag=1;
                            while(diff(i,j)==lowValWall) & flag==1
                                if j+1<size(diff,2)+1
                                  j=j+1;
                                else 
                                    flag=0;
                                end
                            end
                            if diff(i,j)>0
                                savePast=min(savePast1,diff(i,j));
                                changeVal=max(savePast1,diff(i,j));
                                diff(diff==changeVal)=savePast;
                                diff(diff==lowValWall)=savePast; 
                            end  
                        end
                    end
                end
            end
    end
end

for i=1:size(diff,2)

    for j=1:size(diff,1)-1
            if diff(j,i)<0 & diff(j,i)>thr 
                lowValWall=diff(j,i);
                    if diff(j-1,i)>0   
                        if diff(j+1,i)>0 
                            savePast=min(diff(j-1,i),diff(j+1,i));
                            changeVal=max(diff(j-1,i),diff(j+1,i));
                            diff(diff==changeVal)=savePast;
                            diff(diff==lowValWall)=savePast; 
                        else
                            savePast1=diff(j-1,i);
                            j=j+1;
                            while(diff(j,i)==lowValWall)
                                if j+1<size(diff,1)+1
                                  j=j+1;
                                else 
                                    return;
                                end
                            end
                            if diff(j,i)>0
                                savePast=min(savePast1,diff(j,i));
                                changeVal=max(savePast1,diff(j,i));
                                diff(diff==changeVal)=savePast;
                                diff(diff==lowValWall)=savePast; 
                            end  
                        end
                    end
            end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% merge the regions with no line between them
for i=1:size(diff,1)
    for j=1:size(diff,2)-1
            if diff(i,j)~=diff(i,j+1) & diff(i,j)>0 & diff(i,j+1)>0
    
                    savePast=min(diff(i,j),diff(i,j+1));
                    changeVal=max(diff(i,j),diff(i,j+1));
                    diff(diff==changeVal)=savePast;
                     
            end            
    end
end


for i=1:size(diff,2)
    for j=1:size(diff,1)-1
        
            if diff(j,i)~=diff(j+1,i) & diff(j,i)>0 & diff(j+1,i)>0

                    savePast=min(diff(j,i),diff(j+1,i));
                    changeVal=max(diff(j,i),diff(j+1,i));
                    diff(diff==changeVal)=savePast;
                     
            end            
    end
end

diff(diff<0)=0; 
 %figure,imshow(diff); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
coarseLabel_05 = imresize(diff,[224 224],'nearest'); 
coarseLabel_05 = fill_boundary(coarseLabel_05);                                                                             

%% initialize coarseSeg_05
segVals = unique(coarseLabel_05); 
nseg = size(segVals,1);

for i = 1:nseg
    coarseLabel_05(find(coarseLabel_05 == segVals(i)))=i;
end

coarseSeg_05 = cell(1,size(segVals,1));

for i=1:size(segVals,1)
    coarseSeg_05{i}=find(coarseLabel_05==i);
end
%% initialize seg_edges_05
seg_edges_05 = []; 

[X,Y,Z] = size(img); nseg = max(coarseLabel_05(:)); vals = reshape(img,X*Y,Z);
  
if full == 1,
  [x y] = meshgrid(1:nseg,1:nseg);
  seg_edges_05 = [x(:) y(:)];
else
  [points edges] = lattice(X,Y,0);    clear points;
  d_edges = edges(find(coarseLabel_05(edges(:,1))~=coarseLabel_05(edges(:,2))),:);
  all_seg_edges = [coarseLabel_05(d_edges(:,1)) coarseLabel_05(d_edges(:,2))]; all_seg_edges = sort(all_seg_edges,2);

  tmp = zeros(nseg,nseg);
  tmp(nseg*(all_seg_edges(:,1)-1)+all_seg_edges(:,2)) = 1;
  [edges_x edges_y] = find(tmp==1); seg_edges_05 = [edges_x edges_y];
end

 
%% initializa histogram of the regions, histSP_05 
temp_hist = zeros(nbins*3,nseg);
for j =1:nseg
    temp_index = coarseSeg_05{j};
    SP = img_v(temp_index,:);
    temp_hist(:,j)  = makehist( nbins,SP );
end
histSP_05 = temp_hist;%d x n
clear temp_hist 

seg_vals_05 = zeros(nseg,Z);

for i=1:nseg
    seg{i} = find(coarseLabel_05(:)==i);
    seg_vals_05(i,:) = mean(vals(seg{i},:));
end
  
             