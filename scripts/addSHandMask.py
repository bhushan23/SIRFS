import h5py
import numpy as np
from scipy.ndimage import imread
import os
import pandas as pd
from skimage.transform import resize

def get_h5_file_names(path):
    h5Files = []                                                                                     
    for file in os.listdir(path):                                                                    
        h5Files.append(path+file)                                                                    
    return h5Files  

old_h5_path = '/home/bsonawane/Thesis/LightEstimation/SIRFS/scripts/SfsNet_SynImage/'   # '/home/bsonawane/Thesis/LightEstimation/SIRFS/SfsNet_SynImage/'
data_path = '/home/bsonawane/Thesis/LightEstimation/synData/Soumyadip/data/DATA_pose_15/'
out_path = './SfSNetData/'

lightingFile = open(data_path +'lightingList', 'r')
maskFile = open(data_path +'maskList', 'r')

size_per_h5 = 300
h5Files = get_h5_file_names(old_h5_path)
h5_index = 0
i = 0

# print(h5Files)
true_sh = np.zeros((size_per_h5, 27))
mask = np.zeros((size_per_h5, 64, 64, 3))
for lFile, mFile in zip(lightingFile, maskFile):
    # print(lFile, mFile)
    mask_image = imread(data_path+mFile.rstrip())
    sh         = pd.read_csv(data_path+lFile.rstrip(), sep='\t', header = None)
    sh_arr     = sh.values
    # print('SH:', sh_arr.shape, mask_image.shape)
    resized    = resize(mask_image, (64, 64, 3))
    # print('RESIZED', resized.shape)
    true_sh[i] = sh_arr
    mask[i]    = resized
    i += 1
    if i % size_per_h5 == 0:
        # print('Done with one file')
        i = 0
        # Open respective H5PY FILE 
        h5 = h5py.File(h5Files[h5_index], 'a')
        dset = h5.create_dataset("trueLighting", (size_per_h5, 27), data = true_sh)     
        dset = h5.create_dataset("mask", (size_per_h5, 64, 64, 3), data = mask)     
        true_sh = np.zeros((size_per_h5, 27))
        mask = np.zeros((size_per_h5, 64, 64, 3))
        h5_index += 1
        if h5_index == len(h5Files):
            break

    
