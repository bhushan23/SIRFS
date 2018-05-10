global no_fast
no_fast = true;

% Following is sample test-case for verifying if everything is working
% correctly.

runSIRFS = true; %false;
sizePerH5 = 3;
path = './synImages/';
data_path = '/home/bsonawane/Thesis/LightEstimation/synData/Soumyadip/data/DATA_pose_15/'   % '../Light-Estimation/LDAN/data/synthetic/'; %'../data/crop_resize_maskout/';
maskFile = strcat(data_path, 'maskList');
faceFile = strcat(data_path, 'faceList');
lightingFile = strcat(data_path, 'lightingList');
normalFile = strcat(data_path, 'normalList');
%Files=dir(path);
aF = fopen(faceFile);
lF = fopen(lightingFile);
nF = fopen(normalFile);
mF = fopen(maskFile);

clear shflatten;
shflatten = [];
im = [];
iMask = [];
normals = [];
shadings = [];
finalLoss = [];
reflectances = [];
heights = [];
trueNormal = [];
trueLighting = [];

k = 0;
while feof(aF) == false
    disp('Processing....');
    disp(k);
    filename = fgetl(aF);
    normalName = fgetl(nF);
    lightName = fgetl(lF);
    mName = fgetl(mF);
    
    temp = strsplit(filename, '/');
    H5Name = temp{1,2};
    filename = strcat(data_path, filename);
    normalName = strcat(data_path, normalName);
    lightName = strcat(data_path, lightName);
    maskName = strcat(data_path, mName);
    % fileN = imread(filename);
    % data = h5read(filename, '/data_1');
    % reading and converting synthetic images
    % allFiles = uint8(permute(data, [3, 2, 1, 4]));
    % enf of reading
    % [~, ~, ~, Size] = size(allFiles);
    %fileN = allFiles(:,:,:,j);
    
    faceFile = imread(filename);
    faceFile = imresize(faceFile, [64, 64]);
    rotated = permute(faceFile, [2, 1, 3]);
    im = cat(4, im, rotated);
    
    
    fileM = imread(maskName);
    fileM = imresize(fileM, [64, 64]);
    maskFile = rgb2gray(fileM) == 255;
    
    nMask = []
    nMask = cat(3, nMask, maskFile);
    nMask = cat(3, nMask, maskFile);
    nMask = cat(3, nMask, maskFile);
    rotatedM = permute(nMask, [2, 1, 3]);
    iMask = cat(4, iMask, rotatedM);
    

    fileN = faceFile.* uint8(nMask);
    normalImg = imread(normalName);
    normalImg = imresize(normalImg, [64, 64]);
    rotated = permute(normalImg, [2, 1, 3]);
    trueNormal = cat(4, trueNormal, rotated);
    
    %trueSH = readtable(lightName, 'Delimiter', '\t');
    %trueSH = table2array(trueSH);
    trueSH = dlmread(lightName, '\t')
    trueLighting = [ [trueLighting] ; reshape(trueSH, [27, 1])'];
    size(trueLighting)
    if runSIRFS
        input_image = double(fileN)/255;
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
    if mod(k, sizePerH5) == 0
        dataName = strcat(path, '/data_');
        dataName = strcat(dataName, int2str(k / sizePerH5));
        dataName = strcat(dataName,'.h5');
        h5create(dataName, '/Image', [64 64 3 sizePerH5], 'Datatype', 'uint8');
        h5write(dataName, '/Image', im);

        h5create(dataName, '/Mask', [64 64 3 sizePerH5], 'Datatype', 'uint8');
        h5write(dataName, '/Mask', iMask);

        im = [];
        iMask = [];
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

            % Store Final Loss
            h5create(dataName, '/TrueNormal', [64 64 3 sizePerH5], 'Datatype', 'double');
            h5write(dataName, '/TrueNormal', trueNormal);
            
            % Store Final Loss
            trueLighting = trueLighting';
            h5create(dataName, '/TrueLighting', [27 sizePerH5], 'Datatype', 'double');
            h5write(dataName, '/TrueLighting', trueLighting);
            
            shflatten = [];
            normals = [];
            reflectances = [];
            heights = [];
            finalLoss = [];
            shadings = [];
            trueNormal = [];
            trueLighting = [];
        end
    end
    %shfilename = [ [shfilename]; Files(k).name];
end
%csvwrite('RealImage_Celeb_000_SH.csv',shflatten);
%csvwrite('RealImage_Celeb_000_names.csv', shfilename);

%h5create('data.h5', '/Image', [64 64 3 num-2], 'Datatype', 'uint8');
%h5write('data.h5', '/Image', im);
if runSIRFS
    input_image = double(fileN)/255;
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

%{
k = k + 1
dataName = strcat(path, '/data_');
dataName = strcat(dataName, int2str(k / sizePerH5));
dataName = strcat(dataName,'.h5');
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

    % Store Final Loss
    h5create(dataName, '/TrueNormal', [64 64 3 sizePerH5], 'Datatype', 'double');
    h5write(dataName, '/TrueNormal', trueNormal);

    % Store Final Loss
    h5create(dataName, '/TrueLighting', [27 sizePerH5], 'Datatype', 'double');
    h5write(dataName, '/TrueLighting', trueLighting);
    im = [];
    shflatten = [];
    normals = [];
    reflectances = [];
    heights = [];
    finalLoss = [];
    shadings = [];
    trueNormal = [];
    trueLighting = [];
end

%}
