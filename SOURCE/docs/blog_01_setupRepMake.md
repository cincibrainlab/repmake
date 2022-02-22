# Setting Up REPMAKE Analysis Pipeline
## Quick start to reproducible research

There are thousands of research tools and framework available for almost every use case. No single framework is optimal for every analysis. This particular framework, REPMAN, was designed for a relatively narrow subset of neuroscience research.

Consider investigating REPMAKE if you:
1. Routinely work with large clinical datasets
2. Uniformily apply analyses to multiple datasets
3. Need a high degree of customization
4. Require the use of multiple EEG toolkits without having to switch workflows
5. Desire high dimensional outputs of EEG features to be used in other software (R)
6. Can perform high-volume analysis on "headless" servers (commandline tools)
7. Interested in high-speed, parallel or GPU acceleration of large dataset analysis

There is no avoiding the complexity of setting up an analysis environment. That being said we optimized the setup for a modern workflow across multiple computers and researchers. Let's review the main components:

As analysis files get larger, we realize that most people have smaller datasets that they use for generating publication materials where as the larger products of an analysis may reside on a server. For example, I like to keep my manuscript files and statistical datasets in cloud storage to work on my laptop but keep the remainder of my analysis on our server (which is behind a firewall). So the RepMake platform is split into two parts:

	"Small" Component: Source code, project configuration, selected datasets
	"Big" Component: Toolkits, raw data, all analysis results, toolkit output

If your workflow doesn't need a "small" and "big" just put the directories in the same place. For size estimates, I would set aside at least a 1 TB storage drive for all the temporary and redundant files common to high-dimensional data such as EEGs.

## Directory Structure - The components of the REPMAKE platform

"Small" Storage Directories
* REPMAKE/              Makefiles, config files
* REPMAKE/SOURCE/       Scripts for analysis (Small)
* REPMAKE/BUILD/        Selected outputs only (Small)

"Large" Storage Directories
* RAWDATA/	Original/Preprocessed Datasets (Large)
* BIGBUILD/     All output of REPMAKE scripts (Large)
* TOOLKITS/     Toolkit directories (including HTP)

## Key configuration file - Need to define paths for a specific system!
We have tried to consolidate and minimize the need for multiple configuration files. There is likely a need for a single software specific configuration file for each language you are working in. For example, the MATLAB include file will contain information on the location of specific paths of analysis software on your computer. For R, this may be a common file for loading packages that are used across scripts or setting uniform colors for groups.

* REPMAKE/Matlab_Config_SystemName.m
* REPMAKE/R_Config_SystemName.R

As these files may be used by different users across different machines, different Configs can be saved with the _SystemName tag (with your actual system name) and then copied to a common name (so it doesn't have to be changed for every script).

* REPMAKE/Matlab_Config.m
* REPMAKE/R_Config.R

## So, where are project specific files stored?
We noticed that having multiple separate project folders (and duplicated analysis scripts) for many datasets has been an inefficent from a productivity standpoint. Instead, we have opted for a new model:
1. The REPMAKE/SOURCE folder contains a PROJECT folder which contains subdirectories of project specific files. The scientist is then able to see all active projects at a single glance.
2. The PROJECT folder name is used as a tag across all stages of the analysis:
	a. The PROJECT folder is the study title and protocol name in Brainstorm
	b. The PROJECT folder is the prefix/suffix used on all project specific files
	c. The PROJECT folder is also found in every BUILD folder
	d. If you are combining multiple projects, the PROJECT folder name can be used
		as a column variable to identify analyses. 

 For an example, consider the following:
	REPMAKE/SOURCE/RestEEG_DS    Resting EEG study in Down Syndrome
	REPMAKE/SOURCE/RestEEG_ASD   Resting EEG study in FXS

	REPMAKE/SOURCE/RestEEG_DS/config_RestEEG_DS.m  Matlab configuration and file locations
	REPMAKE/Makefile-RestEEG_DS  Makefile for RestEEG_DS
	REPMAKE/BUILD/RestEEG_DS     Selected Outputs for RestEEG_DS
	REPMAKE/BIGBUILD/RestEEG_DS  All Outputs for RestEEG_DS

	And assume a similar pattern for RestEEG_ASD

However, notice that the source code for the analysis scripts does not get modified for the Project. Rather the scripts are written in such a way that the config file will define project specific parameters. In the case you might need a modified version of script, a copy of the main script can be modified and placed in the project directory and then referenced in the Makefile.

To summarize, a project specific folder will need to be created in each of the following directories:
* RAWFILES/      EEG files
* REPMAKE/SOURCE/        Project specific startup and configuration
* BIGBUILD/         All (default) project specific output
* REPMAKE/BUILD

## The use of Testing and Templates

To validate an installation, we have provided a test set of data and template files. This test set can be used with the packaged functions or used with custom functions. Good computer science practice recommends the use of unit testing to ensure the code is functioning properly. By asserting statements of a standardized dataset prior to any customization, even a small change in a computational code can be picked up and troubleshooted.

### The power of unit testing
The ability to check and run small aspects of the pipeline should help with setting up and understanding the prerequistics for each analysis type. The test makefile can automatically run through all the analysis scripts, create outputs, and allow for close examination of the process.

The test analysis folder is EEGTEST and contains 10 (2 groups) of 128-channel deidentified data whichcan run through all aspects of analysis pipeline.

## Walkthrough of Key Files
REPMAKE
+ setupMathlabPaths.m: Run first to setup host directories
					   Define root_dir <- Important
+ SOURCE/Proj_NameOfProject/Proj_NameOfProject_Startup.m: Project-specific data/analysis directory
					   Define name of project directory.
 

