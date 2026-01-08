# Expediting Human Motor Learning in High-dimensional de-Novo Tasks via Online Curriculum Design
This repository contains MATLAB files for running the online curriculum for novel motor skill learning human subject experiment using SenseGlove DK1.  
The novel motor skill acquisition experiment is posed as a target capture video game.

### Note:
The SenseGlove DK1 data acquisition interface was designed for Windows. So you need a Windows system to run the experiment.

## STEPS TO RUN EXPERIMENT
* Connect the SenseGlove DK1 (or any other SenseGlove exoskeleton) to your Windows system
* Run `/SenseGlove/SenseCom.exe` and wait for connection to be established
* Run `/DaqCpp/M3X.exe` to start data acquisition from the connected exoskeleton
* Strap the exoskeleton to the human participant to start the experiment
* Run `/main_ballistic_MPC.m` to start the experiment. This launches a GUI to select various parameters and hyperparameters

The calibration data is saved in `/Calibration` and the subject data is saved in `/SubjectData` for further analysis and processing.
