![mpn logo](img/mpn_banner.png)

# Montréal Paris Neurobanque (MPN) 7T MRI Data Processing Pipeline

[![version](https://img.shields.io/github/v/tag/rcruces/7T_pipeline)](https://github.com/rcruces/7T_pipeline)
[![Docker Image Version](https://img.shields.io/docker/v/rcruces/7T_pipeline?color=blue&label=docker%20version)](https://hub.docker.com/r/rcruces/7T_pipeline)
[![Docker Pulls](https://img.shields.io/docker/pulls/rcruces/7T_pipeline)](https://hub.docker.com/r/rcruces/7T_pipeline)
[![License: GPL v3](https://img.shields.io/github/license/rcruces/7T_pipeline?color=blue)](https://www.gnu.org/licenses/gpl-3.0)
[![GitHub issues](https://img.shields.io/github/issues/rcruces/7T_pipeline)](https://github.com/rcruces/7T_pipeline/issues)
[![GitHub stars](https://img.shields.io/github/stars/rcruces/7T_pipeline.svg?style=flat&label=⭐%EF%B8%8F%20stars&color=brightgreen)](https://github.com/rcruces/7T_pipeline/stargazers)

## Overview

This repository hosts scripts and tools for processing and managing high-resolution 7T MRI data as part of the MPN initiative. The aim is to facilitate open data sharing and streamline quality control (QC) and preprocessing using an integrated pipeline that connects [LORIS](https://loris.ca/), [CBRAIN](https://cbrain.ca/), and [micapipe](https://micapipe.readthedocs.io/en/latest/), following  [BIDS standards](https://bids.neuroimaging.io/).

| <a href="https://loris.ca/"><img src="https://mcin.ca/wp-content/uploads/2017/06/LORIS-logo-small-300x170.png" alt="loris" style="width:90%;"></a> | <a href="https://cbrain.ca/"><img src="https://portal.conp.ca/static/img/cbrain-long-logo-blue.png" alt="cbrain" style="width:75%;"></a> | [![micapipe](https://raw.githubusercontent.com/MICA-MNI/micapipe/refs/heads/master/docs/figures/micapipe_small_black.png)](https://micapipe.readthedocs.io/en/latest/) |
|:---:|:---:|:---:|
| Seamlessly manages raw and BIDS-formatted data, facilitating initial QC annotation. | Connects to LORIS to run QC and preprocessing tools, extracting and feeding back QC metrics and initial derivatives. | Performs standardized preprocessing of MRI data and generates derivatives. |


## Repository Contents

| **File**       | **Description**                                                                 |
|:--------------:|:--------------------------------------------------------------------------------|
| `README`       | Detailed documentation on the project's goals, setup instructions, and usage guidelines. |
| `LICENSE`      | Information on the repository's licensing terms for open-source distribution.   |
| `Dockerfile`   | Configuration to containerize the pipeline for reproducibility and easy deployment. |
| `Functions`    | Directory with the functions.                                                    |


## Workflow
The data processing workflow begins by transferring raw MRI data, in both BIDS and MINC format, to the `LORIS` platform. Once uploaded, initial quality control (QC) annotations are performed on `LORIS` using both automated tools and human evaluations. The data is then linked to `CBRAIN`, where automated QC metrics are extracted for further analysis. Following this, the QC reports on `LORIS` are reviewed and classified as either "pass" or "fail." Once the data is approved, it is transferred back to LORIS for preprocessing with `micapipe`. `micapipe` then generates initial derivatives while applying additional QC measures to ensure the integrity of the data throughout the entire pipeline.

![mpn workflow](img/mpn_workflow.png)

## MRI transfering steps

### 1. DICOM Sorting: Organizes raw DICOM into a temporary structurated directories
```bash
dcmSort.sh
```

### 2. Sorted DICOM to NIfTI BIDS
```bash
mpn_sorted2bids.sh
```

### 3. Integrated BIDS validation
```python
from bids_validator import BIDSValidator
BIDSValidator().is_bids('path/to/mpn_rawdata')

```

### Running `micapipe v0.2.3` with container
```bash
micapipe_q1k.sh Q1K004 01 <path to singularity image>
```

# Requirements

| **Package**       |  **Version**  |
|:-----------------:|:-------------:|
| dcm2niix          | v1.0.20240202 |
| bids_validator    |               |



