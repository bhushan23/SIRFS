global no_fast
no_fast = true;

% Following is sample test-case for verifying if everything is working
% correctly.

runSIRFS = false;
data_path = './realHD5';
path =  '../Light-Estimation/LDAN/data/real-Cropped/crop_resize_maskout/' %'../data/crop_resize_maskout/';
Files=dir(path);


clear shflatten;
shflatten = [];
im = [];
num = length(Files);
for k=3:num
    disp('K IS --------');
    disp(k);
    filename = strcat(path, Files(k).name); %'000001.jpg.png');
    fileN = imread(filename);
    rotated = permute(fileN, [2, 1, 3]);
    im = cat(4, im, rotated);
    if runSIRFS
        input_image = double(imread(filename))/255;
        input_mask = all(input_image > 0,3);
        output = SIRFS(input_image, input_mask, [], '');    
        disp(output.light);
        shflatten = [ [shflatten] ; reshape(output.light, [27, 1])'];
    end
    
    if mod(k-2, 2500) == 0
        %dataName = strcat(data_path, '/data_');
        dataName = strcat('data_', int2str((k+1) / 2500));
        dataName = strcat(dataName,'.h5')
        h5create(dataName, '/Image', [64 64 3 2500], 'Datatype', 'uint8');
        h5write(dataName, '/Image', im);
        im = [];
    end
    %shfilename = [ [shfilename]; Files(k).name];
end
%csvwrite('RealImage_Celeb_000_SH.csv',shflatten);
%csvwrite('RealImage_Celeb_000_names.csv', shfilename);

%h5create('data.h5', '/Image', [64 64 3 num-2], 'Datatype', 'uint8');
%h5write('data.h5', '/Image', im);

if runSIRFS
    h5create('data.h5', '/SH', [num-3 27], 'Datatype', 'double');
    h5write('data.h5', '/SH', shflatten);
end
