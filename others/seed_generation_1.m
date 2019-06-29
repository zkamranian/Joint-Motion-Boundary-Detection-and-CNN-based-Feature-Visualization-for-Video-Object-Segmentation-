function [lines seeds labels] = seed_generation(ref_name)
% ref_name=[scribbles_path img_names_t{i} '.bmp']; opt=type_of_seed
ref=imread(ref_name);    [X Y Z] = size(ref);    N=X*Y;
L{1} = find(ref(:,:,1)==255 & ref(:,:,2)==0.0 & ref(:,:,3)==0.0);
L{2} = find(ref(:,:,1)==0.0 & ref(:,:,2)==255 & ref(:,:,3)==0.0);
L{3} = find(ref(:,:,1)==0.0 & ref(:,:,2)==0.0 & ref(:,:,3)==255);

seeds = [L{1}; L{2}; L{3}];
labels = [ones(1,size(L{1},1)), 2*ones(1,size(L{2},1)), 3*ones(1,size(L{3},1))];

nlabels = 1;
for i=1:3
    nL = size(L{i},1);
    if nL > 0
        lines(:,nlabels)    = zeros(N,1);
        lines(L{i},nlabels) = 1;
        nlabels = nlabels + 1;
    end
end