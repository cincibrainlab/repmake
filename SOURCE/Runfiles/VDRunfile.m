

import_dir = 'E:\onedrive\OneDrive - cchmc\Datashare - EP LAB\EEG\Raw\Visual Discrimination\noaudio';
output_dir = 'E:\data\VD';

[results] = utility_htpImportEeg(import_dir, 'nettype', 'EGI128');

[results] = utility_htpImportEeg(import_dir, 'nettype','EGI128', 'outputdir', 'E:\data\VD', 'dryrun', false )

[results] = utility_htpEegInfo(output_dir, 'nettype','EGI128', 'csvout', 'VD_noaudio_info.csv' )