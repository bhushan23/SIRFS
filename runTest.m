global no_fast
no_fast = true;

% Following is sample test-case for verifying if everything is working
% correctly.



path = '../data/crop_resize_maskout/';
Files=dir(path);
clear shflatten;
clear shfilename;
shflatten = []
%shflatten = zeros(length(Files)-1, 27);
shfilename = [] %repmat(' ',[length(Files)-1,1]);
for k=3:length(Files)
    disp('K IS --------');
    disp(k);
    filename = strcat(path, Files(k).name); %'000001.jpg.png');
    input_image = double(imread(filename))/255;
    input_mask = all(input_image > 0,3);
    output = SIRFS(input_image, input_mask, [], '');    
    disp(output.light);
    shflatten = [ [shflatten] ; reshape(output.light, [27, 1])'];
    shfilename = [ [shfilename]; Files(k).name];
end
csvwrite('RealImage_Celeb_000_SH.csv',shflatten);
csvwrite('RealImage_Celeb_000_names.csv', shfilename);


