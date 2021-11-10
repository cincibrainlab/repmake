Meeting 11/8/2021
Mouse EEG Analysis Layout

Final Step:
    Table outputs of EEG Features of Interest
    Figures for publications
    Access to Raw Data

Specific Analysis:
	Spectral Power 
		Ratio of Power
		Normalization: 
			Gamma (Sum 30-55 Hz)  

	10 seconds of Epoch data
	FFT based on 0 to 100 ( .5 or 1 Hz steps, resolution?)
	Default band grouping 
		delta  .5-4
		theta  4-8
		alpha1 8-12
		sigma  12-16
		beta   16-24
		gamma1 24-90 (usually 30-55 Hz and 65 to 90 Hz)
		gamma2 ?

	MEA 30 channels, length usually shorter 5 minutes
	1-2 second bin and do our poper

## Big Picture:
	Data upload of Raw data (Blinding of the IDs and upload to CCHMC Onedrive)
			Size much is smaller
	Preprocessing
		Goal is for resting data to have the cleanest sample of 5 mintues
			Aim for 30-60 seconds (multiple 30 second periods over longer)
			Focus on development of a best pipeline for mouse cleaning
				camera
				movement 
				etc
		Other analysis could include other behavioral states
		
	Quality control
		# amount of rejected data
		# numer of reject electrodes < less 10%
		# noisiness of the data/movement artifacts
		# ICA - number of artifact components removed (i.e. Heart rate)
		# what is the state or condition of the animal during record (health?) (scale)

	Results are cleaned datasets that are uniform in length and can be used for
	any type of analysis we need. Sampling 500 Hz, channel, it will also have the channel 
	map which specifies locations. SET/FDT EEGLAB common EEG format. 

	Folder:
		EEGID (blinded M0431)
		Results will be a spreadsheet of EEG and what ever feature we are interest
			if it is high dimension channel X frequency band X power
			channel X frequency band X time X some feature (power connectivity)
			channel X channel X frequency band X time
			results called MAT in Matlab, scripts to convert to CSV when you need analyze	
		Figures
			show how to code visualation in MATLAB (Binder)
			orther statistical scripts in R
		Statistics
			Once data is available in CSV format we can demonstrate
			code for linear models, to calcualte significant difference
					
	Feature by Feature Analysis
		Resting Analysis
		Spectral Power (topographical power)
			relative
			absolute
			proportion
		Connectivity (topographical power)
			DWPLI
			Coherence
		Auditory chirp
			ITPC (trial coherence)
			Onset ERP
			background gamma power (unsyncrhonized gamma)
		Exploratory 
			Phase amplitude coupling
			hubness ETC

	Start with Example
		working through this pipeline towards the final outputs
				
	Confirm channel maps and grid layout
	Photograph figure with labels of our final layout to include in publications
	Software list and code to download from Github
	
