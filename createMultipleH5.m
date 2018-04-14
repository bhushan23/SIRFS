global no_fast
no_fast = true;

% Following is sample test-case for verifying if everything is working
% correctly.

runSIRFS = true; %false;
sizePerH5 = 2500;
data_path = './000';
path =  '../Light-Estimation/LDAN/data/real-Cropped/crop_resize_maskout/' %'../data/crop_resize_maskout/';
Files=dir(path);


clear shflatten;
shflatten = [];
im = [];
normals = [];
shadings = [];
finalLoss = [];
reflectances = [];
heights = [];
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
        % Normal is 64 x 64 x 3
        normalOut = permute(output.normal, [2 1 3]);
        normals = cat(4, normals, normalOut);
        % Shading is 64 x 64 x 3
        shadingOut = permute(output.shading, [2 1 3]);
        shadings = cat(4, shadings, shadingOut);
        % Reflectance is 64 x 64 x 3
        reflOut = permute(output.reflectance, [2 1 3]);
        reflectances = cat(4, reflectances, reflOut);
        % Height is 64 x 64
        htOut = permute(output.height, [2 1]);
        heights = cat(3, heights, htOut);
        % Final loss is scalar value
        finalLoss = [[finalLoss]; output.final_loss];
    end
    
    if mod(k-2, sizePerH5) == 0
        dataName = strcat(data_path, '/data_');
        dataName = strcat(dataName, int2str((k-2) / sizePerH5));
        dataName = strcat(dataName,'.h5')
        h5create(dataName, '/Image', [64 64 3 sizePerH5], 'Datatype', 'uint8');
        h5write(dataName, '/Image', im);
        
        if runSIRFS
            shOut = shflatten';
            % Store Lighting
            h5create(dataName, '/Lighting', [27 sizePerH5], 'Datatype', 'double');
            h5write(dataName, '/Lighting', shOut);
            % Store Normal
            h5create(dataName, '/Normal', [64 64 3 sizePerH5] , 'Datatype', 'double');
            h5write(dataName, '/Normal', normals);
            % Store Reflectance
            h5create(dataName, '/Reflectance', [64 64 3 sizePerH5], 'Datatype', 'double');
            h5write(dataName, '/Reflectance', reflectances);
            % Store Shading
            h5create(dataName, '/Shading', [64 64 3 sizePerH5], 'Datatype', 'double');
            h5write(dataName, '/Shading', shadings);
            % Store Height
            h5create(dataName, '/Height', [64 64 sizePerH5], 'Datatype', 'double');
            h5write(dataName, '/Height', heights);
            % Store Final Loss
            h5create(dataName, '/FinalLoss', [sizePerH5], 'Datatype', 'double');
            h5write(dataName, '/FinalLoss', finalLoss);
            
            im = [];
            shflatten = [];
            normals = [];
            reflectances = [];
            heights = [];
            finalLoss = [];
            shadings = [];
        end
    end
    %shfilename = [ [shfilename]; Files(k).name];
end
%csvwrite('RealImage_Celeb_000_SH.csv',shflatten);
%csvwrite('RealImage_Celeb_000_names.csv', shfilename);

%h5create('data.h5', '/Image', [64 64 3 num-2], 'Datatype', 'uint8');
%h5write('data.h5', '/Image', im);


