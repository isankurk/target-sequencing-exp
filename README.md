---
<div align="center">

# Expediting Human Motor Learning in High-dimensional de-Novo Tasks via Online Curriculum Design
  
Ankur Kamboj, Rajiv Ranganathan, Xiaobo Tan, Vaibhav Srivastava | 2025

[![Paper](https://img.shields.io/badge/ACC-2025-red)](https://doi.org/10.23919/ACC63710.2025.11107860)

</div>

_TL;DR_: This work shows how an automated online curriculum design can help accelerate motor skill acquisition in complex human motor tasks using stochastic nonlinear model predictive control.
## Summary
While recent advancements in motor learning have emphasized the critical role of systematic task scheduling in enhancing task learning, the heuristic design of task schedules remains predominant. Random task scheduling can lead to sub-optimal motor learning, whereas performance-based scheduling might not be adequate for complex motor skill acquisition. This paper addresses these challenges by proposing a model-based approach for online skill estimation and individualized task scheduling in *de-novo* (novel) motor learning tasks. We introduce a framework utilizing a personalized human motor learning model and particle filter for skill state estimation, coupled with a stochastic nonlinear model predictive control (SNMPC) strategy to optimize curriculum design for a high-dimensional motor task. Simulation results show the effectiveness of our framework in estimating the latent skill state, and the efficacy of the framework in accelerating skill learning. Furthermore, a human subject study shows that the group with the SNMPC-based curriculum design exhibited expedited skill learning and improved task performance. Our contributions offer a pathway towards expedited motor learning across various novel tasks, with implications for enhancing rehabilitation and skill acquisition processes.  

---

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
