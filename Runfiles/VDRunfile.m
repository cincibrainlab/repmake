

import_dir = 'E:\onedrive\OneDrive - cchmc\Datashare - EP LAB\EEG\Raw\Visual Discrimination\noaudio';

[results] = utility_htpImportEeg(import_dir, 'nettype', 'EGI128');

[results] = utility_htpImportEeg(import_dir, 'nettype','EGI128', 'outputdir', 'E:\data\VD', 'dryrun', false )