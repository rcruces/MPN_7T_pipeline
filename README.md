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
# Naming convention
| **N** | **7T Terra Siemens acquisition**                | **BIDS**                            | **Directory** |
|:-----:|:-----------------------------------------------:|:-----------------------------------:|:-------------:|
|  1    | *anat-T1w_acq_mprage_0.8mm_CSptx             | T1w                                   | anat          |
|  2    | *fmap-b1_tra_p2                              | acq-[anat|famp]_TB1TFL                | fmap          |
|  3    | *fmap-b1_acq-sag_p2                          | acq-[anat|famp]_TB1TFL                | fmap          |
|  4    | *fmap-fmri_acq-mbep2d_SE_19mm_dir-AP         | dir-AP_epi                            | fmap          |
|  5    | *fmap-fmri_acq-mbep2d_SE_19mm_dir-PA         | dir-PA_epi                            | fmap          |
|  6    | *func-cloudy_acq-ep2d_MJC_19mm               | task-cloudy_bold                      | func          |
|  7    | *func-cross_acq-ep2d_MJC_19mm                | task-rest_bold                        | func          |
|  8    | *func-present_acq-mbep2d_ME_19mm             | task-present_bold                     | func          |
| 12    | *anat-T1w_acq-mp2rage_0.7mm_CSptx_INV1       | inv-1_MP2RAGE                         | anat          |
| 13    | *anat-T1w_acq-mp2rage_0.7mm_CSptx_INV2       | inv-2_MP2RAGE                         | anat          |
| 14    | *anat-T1w_acq-mp2rage_0.7mm_CSptx_T1_Images  | T1map                                 | anat          |
| 15    | *anat-T1w_acq-mp2rage_0.7mm_CSptx_UNI_Images | UNIT1                                 | anat          |
| 16    | *anat-T1w_acq-mp2rage_0.7mm_CSptx_UNI-DEN    | acq-denoised_UNIT1                    | anat          |
| 17    | *anat-flair_acq-0p7iso_UPAdia                | FLAIR                                 | anat          |
| 18    | *Romeo_Mask_anat-T2star_acq-me_gre_0*7iso_ASPIRE | acq-mask_T2starw                  | anat          |
| 19    | *Aspire_M_anat-T2star_acq-me_gre_0*7iso_ASPIRE | acq-aspire_part-mag_T2starw         | anat          |
| 20    | *Aspire_P_anat-T2star_acq-me_gre_0*7iso_ASPIRE | acq-aspire_part-phase_T2starw       | anat          |
| 21    | *EchoCombined_anat-T2star_acq-me_gre_0*7iso_ASPIRE | acq-combined_part-echo_T2starw  | anat          |
| 22    | *T2star_anat-T2star_acq-me_gre_0*7iso_ASPIRE | T2starw                               | anat          |
| 23    | *Romeo_P_anat-T2star_acq-me_gre_0*7iso_ASPIRE | acq-romeo_part-phase_T2starw         | anat          |
| 24    | *Romeo_B0_anat-T2star_acq-me_gre_0*7iso_ASPIRE | acq-romeoUnwrapped_T2starw          | anat          |
| 25    | *sensitivity_corrected_mag_anat-T2star_acq-me_gre_0*7iso_ASPIRE | acq-SensitivityCorrected_part-mag_T2starw | anat |
| 26    | *CLEAR-SWI_anat-T2star_acq-me_gre_0*7iso_ASPIRE | acq-clearSWI_T2starmap             | anat          |
| 27    | *anat-mtw_acq-MTON_07mm                      | mt-on_MTR                             | anat          |
| 28    | *anat-mtw_acq-MTOFF_07mm                     | mt-off_MTR                            | anat          |
| 29    | *anat-mtw_acq-T1w_07mm                       | acq-MTR_T1w                           | anat          |
| 30    | *anat-nm_acq-MTboost_sag_0.55mm              | acq-neuromelaninMTw_T1w               | anat          |
| 31    | *anat-angio_acq-tof_03mm_inplane             | acq-tof_angio                         | anat          |
| 32    | *anat-angio_acq-tof_03mm_inplane_MIP_SAG     | acq-tofSag_angio                      | anat          |
| 33    | *anat-angio_acq-tof_03mm_inplane_MIP_COR     | acq-tofCor_angio                      | anat          |
| 34    | *anat-angio_acq-tof_03mm_inplane_MIP_TRA     | acq-tofTra_angio                      | anat          |
| 35    | *dwi_acq_b0_PA                               | acq-b0_dir-PA_dwi                     | dwi           |
| 36    | *dwi_acq_b0_PA_SBRef                         | acq-b0_dir-PA_sbref                   | dwi           |
| 37    | *dwi_acq_multib_38dir_AP_acc9                | acq-multib38_dir-AP_dwi               | dwi           |
| 38    | *dwi_acq_multib_38dir_AP_acc9_SBRef          | acq-multib38_dir-AP_sbref             | dwi           |
| 39    | *dwi_acq_multib_70dir_AP_acc9                | acq-multib70_dir-AP_dwi               | dwi           |
| 40    | *dwi_acq_multib_70dir_AP_acc9_SBRef          | acq-multib70_dir-AP_sbref             | dwi           |

### Abbreviation Glossary

> **MTw**: Magnetic transfer weighted
> **fmap**: scaled flip angle map
> **tof**: time of flight
> **multib**: multi shell N directions
> **semphon**: semantic-phonetic
> **romeo**: rapid opensource minimum spanning tree algorithm
> **aspire**: Combination of multi-channel phase data from multi-echo acquisitions

# References

1. Eckstein K, Dymerska B, Bachrata B, Bogner W, Poljanc K, Trattnig S, Robinson SD. Computationally efficient combination of multi‐channel phase data from multi‐echo acquisitions (ASPIRE). Magnetic resonance in medicine. 2018 Jun;79(6):2996-3006. https://doi.org/10.1002/mrm.26963

2. Dymerska B, Eckstein K, Bachrata B, Siow B, Trattnig S, Shmueli K, Robinson SD. Phase unwrapping with a rapid opensource minimum spanning tree algorithm (ROMEO). Magnetic resonance in medicine. 2021 Apr;85(4):2294-308. https://doi.org/10.1002/mrm.28563

3. Sasaki M, Shibata E, Tohyama K, Takahashi J, Otsuka K, Tsuchiya K, Takahashi S, Ehara S, Terayama Y, Sakai A. Neuromelanin magnetic resonance imaging of locus ceruleus and substantia nigra in Parkinson's disease. Neuroreport. 2006 Jul 31;17(11):1215-8. https://doi.org/10.1097/01.wnr.0000227984.84927.a7 

# Requirements

| **Package**       |  **Version**  |
|:-----------------:|:-------------:|
| python            |  3.8          |
| dcm2niix          |  1.0.20240202 |
| jq                |  1.6          |
| bids_validator    |  2.0.0        |
| deno              |  2.0.6        |
