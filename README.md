
# Repository deprecated 
# see: https://github.com/BIC-MNI/mni-7t-dicom-to-bids/tree/main 

![mpn logo](img/mpn_banner.png)

# Montréal Paris Neurobanque (MPN) 7T MRI Data Processing Pipeline

[![version](https://img.shields.io/github/v/tag/rcruces/7T_pipeline)](https://github.com/rcruces/7T_pipeline)
[![Docker Image Version](https://img.shields.io/docker/v/rcruces/mpn?color=blue&label=docker%20version)](https://hub.docker.com/r/rcruces/mpn)
[![Docker Pulls](https://img.shields.io/docker/pulls/rcruces/mpn)](https://hub.docker.com/r/rcruces/mpn)
[![License: GPL v3](https://img.shields.io/github/license/rcruces/7T_pipeline?color=blue)](https://www.gnu.org/licenses/gpl-3.0)
[![GitHub issues](https://img.shields.io/github/issues/rcruces/7T_pipeline)](https://github.com/rcruces/7T_pipeline/issues)
[![GitHub stars](https://img.shields.io/github/stars/rcruces/7T_pipeline.svg?style=flat&label=⭐%EF%B8%8F%20stars&color=brightgreen)](https://github.com/rcruces/7T_pipeline/stargazers)

## Overview

This repository hosts scripts and tools for processing and managing high-resolution 7T MRI data for the [C-BIG](https://cbigr-open.loris.ca)'s Healthy-Controls component ([Montreal-Paris Neurobank:](https://open-mpn.biobank.mcgill.ca). 

The aim is to facilitate open data sharing and streamline quality control (QC) and preprocessing using an integrated pipeline that connects [LORIS](https://loris.ca/), [CBRAIN](https://cbrain.ca/), and [micapipe](https://micapipe.readthedocs.io/en/latest/), following  [BIDS standards](https://bids.neuroimaging.io/).

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


## MRI transfering steps

### Option 1. Raw DICOM to to NIfTI BIDS
1. Organizes raw DICOM into a temporary structurated directories
2. Transforms the sorted dicoms into BIDS
3. Run BIDS validator through `deno`

```bash
dcm2bids.py --dicoms_dir MPN00001_sorted/ --bids_dir /BIDS_MPN/rawdata --sub MPN00001 --ses v1
```

### Option 2. Sorted DICOM to NIfTI BIDS
```bash
dcm2bids.py --dicoms_dir MPN00001_sorted/ --sorted_dir MPN00001_sorted/ --bids_dir /BIDS_MPN/rawdata --sub MPN00001 --ses v1
```

### 3. Integrated BIDS validation
```bash
deno run --allow-write -ERN jsr:@bids/validator {bids_dir} --ignoreWarnings --outfile {bids_dir}/bids_validator_output.txt
```

# Naming dictionary
## Anatomical
## BIDS naming dictionary

### Anatomical

| **N** | **7T Terra Siemens sequence name ** | **BIDS** | **Directory** |**BIDSignore**|
|:-----:|:------------------------------------|:---------|:-------------:|:------------:|
| 1     | `anat-flair_acq-0*7iso_UPAdia`      | `acq_UPAdia07_FLAIR` | `anat` |         |
| 2     | `anat-flair_acq-0*7mm_UPAdia`       | `acq_UPAdia07_FLAIR` | `anat` |         |
| 3     | `anat-flair_acq-0*7iso_dev3_5SD_UP` | `acq_5SDUP07_FLAIR`  | `anat` |         |
| 4     | `*anat-T1w_acq-mp2rage_0*7mm_CSptx_UNI_Images`    | ` acq-mp2rageCSPtx07_UNIT1` | `anat` | |
| 5     | `*anat-T1w_acq-mp2rage_0*7mm_CSptx_UNI-DEN`       | `acq-mp2rageCSPtx07_rec-denoised_UNIT1` | `anat` | |
| 6     | `*anat-T1w_acq-mp2rage_0*7mm_CSptx_T1_Images`     | `acq-mp2rageCSPtx07_T1map` | `anat` | |
| 7     | `anat-T1w_acq_mprage_0*8mm_CSptx`   | `acq-mprageCSPtx08_T1w` | `anat` | |
| 8     | `anat-T1w_acq_mprage_0*8mm_CSx_ND`  | `acq-mprageCSPtx08_T1w` | `anat` | |
| 9     | `*anat-T1w_acq-mprage_0*7mm_UP`     | `acq-mprageCSPtx08_T1w` | `anat` | |
| 10    | `*CLEAR-SWI_anat-T2star_acq-me_gre_0*7iso_ASPIRE` | `acq-megre07_rec_CLEARSWI_swi` | `anat` | `YES `|
| 11    | `*Romeo_P_anat-T2star_acq-me_gre_0*7iso_ASPIRE`   | `acq-megre07_rec_romeo_phase` | `anat` |  `YES ` |
| 12    | `*Romeo_Mask_anat-T2star_acq-me_gre_0*7iso_ASPIRE`| `acq-megre07_rec_romeo_mask` | `anat` | `YES ` |
| 13    | `*Romeo_B0_anat-T2star_acq-me_gre_0*7iso_ASPIRE`  | `acq-megre07_rec_romeounwrap_phase` | `anat` | `YES ` |
| 14    | `Aspire_M_anat-T2star_acq-me_gre_0*7iso_ASPIRE`   | `acq-megre07_rec_aspire_echo-{1:5}-part-mag_T2starw` | `anat` | |
| 15    | `Aspire_P_anat-T2star_acq-me_gre_0*7iso_ASPIRE`   | `acq-megre07_rec_aspire_echo-{1:5}-part-phase_T2starw` | `anat` | |
| 16    | `*T2star_anat-T2star_acq-me_gre_0*7iso_ASPIRE`    | `acq-megre07_rec_aspire_T2starw` | `anat` | |
| 17    | `*EchoCombined_anat-T2star_acq-me_gre_0*7iso_ASPIRE`              | `acq-megre07_rec_aspirecombined_T2sarw` | `anat` | |
| 18    | `*sensitivity_corrected_mag_anat-T2star_acq-me_gre_0*7iso_ASPIRE` | `acq-megre07_rec_aspirecombinedsenscor_T2sar` | `anat`| | 
| 19    | `*T2Star_Images`                   | `T2map` | `anat` | |
| 20    | `*anat-T2star_acq-me_gre_07mm*`    | `acq-megre07_T2starw` | `anat` | |
| 21    | `*anat-T1w_acq-mp2rage_0*7mm_CSptx_INV1`          | `acq-mp2rageCSPtx07_inv-1_MP2RAGE` | `anat` | |
| 22    | `*anat-T1w_acq-mp2rage_0*7mm_CSptx_INV2`          | `acq-mp2rageCSPtx07_inv-2_MP2RAGE` | `anat` | |
| 23    | `*anat-T1w_acq-mp2rage_05mm_UP*_INV1*`            | `acq-mp2rage05_inv-1_MP2RAGE` | `anat` | |
| 24    | `*anat-T1w_acq-mp2rage_05mm_UP*_INV2*`            | `acq-mp2rage05_inv-2_MP2RAGE` | `anat` | |
| 25    | `*anat-T1w_acq-mp2rage_05mm_UP*_T1_Images*`       | `acq-mp2rage05_T1map` | `anat` | |
| 26    | `*anat-T1w_acq-mp2rage_05mm_UP*_UNI_Images*`      | `acq-mp2rage_UNIT1` | `anat` | |
| 27    | `*cstfl-mp2rage-05mm_INV1`                        | `acq-cstfl_inv-1_MP2RAGE` | `anat` | |
| 28    | `*cstfl-mp2rage-05mm_INV2`                        | `acq-cstfl_inv-2_MP2RAGE` | `anat` | |
| 29    | `*cstfl-mp2rage-05mm_T1_Images`                   | `acq-mp2ragecstfl05_T1map` | `anat` | |
| 30    | `*cstfl-mp2rage-05mm_UNI_Images`                  | `acq-mp2ragecstfl05_UNIT1` | `anat` | |
| 31    | `*cstfl-mp2rage-05mm_UNI-DEN`                     | `acq-mp2ragecstfl05_rec_Denoised_UNIT1` | `anat` | |
| 32    | `*anat-mtw_acq-T1w_07mm`                          | `acq-mtw07_T1w` | `anat` | |
| 33    | `*anat-mtw_acq-MTON_07mm`                         | `acq-mtw07_mt-on_MTR` | `anat` | |
| 34    | `*anat-mtw_acq-MTOFF_07mm`                        | `acq-mtw07_mt-off_MTR` | `anat` | |
| 35    | `*_T1W`                            | `acq-MTR_T1w` | `anat` |  `NOT SURE ` |
| 36    | `anat-nm_acq-MTboost_sag_0.55mm`   | `acq-neuromelaninMTw_T1w` | `anat` | |
| 37    | `CR_tfl_MTboost_sag7deg_0.55mm`    | `acq-neuromelaninMTw_T1w` | `anat` | |
| 38    | `*anat-angio_acq-tof_03mm_inplane` | `acq-tof03_angio` | `anat` | |
| 39    | `*anat-angio_acq-tof_03mm_inplane_MIP_COR` | `acq-tof03_rec-MIPcor_angio` | `anat` | |
| 40    | `*anat-angio_acq-tof_03mm_inplane_MIP_SAG` | `acq-tof03_rec-MIPsag_angio` | `anat` | |
| 41    | `*anat-angio_acq-tof_03mm_inplane_MIP_TRA` | `acq-tof03_rec-MIPtra_angio` | `anat` | |

### Diffusion-weighted images

| **N** | **7T Terra Siemens acquisition pattern** | **BIDS** | **Directory** |
|:-----:|:------------------------------------------|:---------|:-------------:|
| 1     | `dwi_acq_b0_PA_SBRef` | `acq-b0_dir-PA_sbref` | `dwi` |
| 2     | `dwi_acq_b0_PA_acc9_SBRef` | `acq-b0_dir-PA_sbref` | `dwi` |
| 3     | `*dwi_acq_b0*_PA_SBRef` | `acq-b0_dir-PA_sbref` | `dwi` |
| 4     | `*dwi_acq_b0*_PA` | `acq-b0_dir-PA_dwi` | `dwi` |
| 5     | `dwi_acq_b0_PA_acc9` | `acq-b0_dir-PA_dwi` | `dwi` |
| 6     | `*dwi_acq_b0_PA_1p5iso_SBRef` | `acq-b01p5_dir-PA_sbref` | `dwi` |
| 7     | `*dwi_acq_b0_PA_1p5iso` | `acq-b01p5_dir-PA_dwi` | `dwi` |
| 8     | `*dwi_acq_multib_38dir_AP_acc9_SBRef` | `acq-multib38_dir-AP_sbref` | `dwi` |
| 9     | `*dwi_acq_multib_38dir_AP_acc9_test_SBRef` | `acq-multib38Test_dir-AP_sbref` | `dwi` |
| 10 | `*dwi_acq_multib_38dir_AP_acc9_1p5iso_SBRef` | `acq-multib381p5_dir-AP_sbref` | `dwi` |
| 11 | `*dwi_acq_multib_70dir_AP_acc9_SBRef` | `acq-multib70_dir-AP_sbref` | `dwi` |
| 12 | `dwi_acq_multib_108dir_AP_acc9_SBRef` | `acq-multib108_dir-AP_sbref` | `dwi` |
| 13 | `*dwi_acq_multib_70dir_AP_acc9_1p5iso_SBRef` | `acq-multib701p5_dir-AP_sbref` | `dwi` |
| 14 | `*dwi_acq_b300_10d-dir_AP_SBRef` | `acq-b300_dir-AP_sbref` | `dwi` |
| 15 | `*dwi_acq_b700_40d-dir_AP_SBRef` | `acq-b700_dir-AP_sbref` | `dwi` |
| 16 | `*dwi_acq_b2000_90d-dir_AP_SBRef` | `acq-b2000_dir-AP_sbref` | `dwi` |
| 17 | `*dwi_acq_multib_38dir_AP_acc9` | `acq-multib38_dir-AP_dwi` | `dwi` |
| 18 | `*dwi_acq_multib_38dir_AP_acc9_1p5iso` | `acq-multib381p5_dir-AP_dwi` | `dwi` |
| 19 | `*dwi_acq_multib_38dir_AP_acc9_test` | `acq-multib38Test_dir-AP_dwi` | `dwi` |
| 20 | `*dwi_acq_multib_70dir_AP_acc9` | `acq-multib70_dir-AP_dwi` | `dwi` |
| 21 | `*dwi_acq_multib_70dir_AP_acc9_1p5iso` | `acq-multib701p5_dir-AP_dwi` | `dwi` |
| 22 | `dwi_acq_multib_108dir_AP_acc9` | `acq-multib108_dir-AP_dwi` | `dwi` |
| 23 | `*dwi_acq_b300_10d-dir_AP` | `acq-b300_dir-AP_dwi` | `dwi` |
| 24 | `*dwi_acq_b700_40d-dir_AP` | `acq-b700_dir-AP_dwi` | `dwi` |
| 25 | `*dwi_acq_b2000_90d-dir_AP` | `acq-b2000_dir-AP_dwi` | `dwi` |

### Field maps

| **N** | **7T Terra Siemens acquisition pattern** | **BIDS** | **Directory** |
|:-----:|:------------------------------------------|:---------|:-------------:|
| 1 | `fmap-b1_tra_p2` | `acq-anat_TB1TFL` | `fmap` |
| 2 | `fmap-b1_acq-sag_p2` | `acq-anat_TB1TFL` | `fmap` |
| 3 | `*fmap-b1_acq-*_p2` | `acq-anat_TB1TFL` | `fmap` |
| 4 | `*fmap-fmri_acq-mbep2d_SE_19mm_dir-AP` | `acq-fmri_dir-AP_epi` | `fmap` |
| 5 | `*fmap-fmri_acq-mbep2d_SE_19mm_dir-PA` | `acq-fmri_dir-PA_epi` | `fmap` |
| 6 | `*fmap-fmri_acq-mbep2d_SE_19mm_dir-AP_Q1K` | `acq-fmriQ1K_dir-AP_epi` | `fmap` |
| 7 | `*fmap-fmri_acq-mbep2d_SE_19mm_dir-PA_Q1K` | `acq-fmriQ1K_dir-PA_epi` | `fmap` |

### Functional

| **N** | **7T Terra Siemens acquisition pattern** | **BIDS** | **Directory** |
|:-----:|:------------------------------------------|:---------|:-------------:|
| 1 | `func-cloudy_acq-ep2d_MJC_19mm` | `task-cloudy_bold` | `func` |
| 2 | `func-present_acq-ep2d_MJC_19mm` | `task-present_bold` | `func` |
| 3 | `*func-semphon1_acq-mbep2d_ME_19mm` | `task-semphon1_bold` | `func` |
| 4 | `*func-semphon2_acq-mbep2d_ME_19mm` | `task-semphon2_bold` | `func` |
| 5 | `func-cross_acq-ep2d_MJC_19mm` | `task-rest_bold` | `func` |
| 6 | `func-rsfmri_acq-multiE_1.9mm` | `task-rest_bold` | `func` |
| 7 | `*func-rsfmri_acq-mbep2d_ME_19mm` | `task-rest_bold` | `func` |
| 8 | `*func-rsfmri_acq-singleE_1*` | `task-rest_acq-singleE_bold` | `func` |
| 9 | `*func-rsfmri_acq-mbep2d_ME_19mm_Q1K` | `task-rest_acq-Q1K_bold` | `func` |
| 10 | `*func-epiencode_acq-mbep2d_ME_19mm*` | `task-epiencode_bold` | `func` |
| 11 | `*func-epiretrieve_acq-mbep2d_ME_19mm` | `task-epiretrieve_bold` | `func` |
| 12 | `*func-pattersep1_acq-mbep2d_ME_19mm` | `task-patternsep1_bold` | `func` |
| 13 | `*func-patter*sep2_acq-mbep2d_ME_19mm` | `task-patternsep2_bold` | `func` |
| 14 | `*func-semantic1_acq-mbep2d_ME_19mm` | `task-semantic1_bold` | `func` |
| 15 | `*func-semantic2_acq-mbep2d_ME_19mm` | `task-semantic2_bold` | `func` |
| 16 | `*func-spatial1_acq-mbep2d_ME_19mm` | `task-spatial1_bold` | `func` |
| 17 | `*func-spatial2_acq-mbep2d_ME_19mm` | `task-spatial2_bold` | `func` |
| 18 | `*func-movie*1_acq-mbep2d_ME_19mm` | `task-movies1_bold` | `func` |
| 19 | `*func-movie*2_acq-mbep2d_ME_19mm` | `task-movies2_bold` | `func` |
| 20 | `*func-movies3_acq-mbep2d_ME_19mm` | `task-movies3_bold` | `func` |
| 21 | `*func-movies4_acq-mbep2d_ME_19mm` | `task-movies4_bold` | `func` |
| 22 | `*func-caddy_acq-mbep2d_ME_19mm` | `task-caddy_bold` | `func` |
| 23 | `*func-harsh_acq-mbep2d_ME_19mm` | `task-harsh_bold` | `func` |
| 24 | `*func-pines_acq-mbep2d_ME_19mm` | `task-pines_bold` | `func` |
| 25 | `*func-bathroom_acq-mbep2d_ME_19mm` | `task-bathroom_bold` | `func` |
| 26 | `*func-audiobook1_acq-mbep2d_ME_19mm` | `task-audiobook1_bold` | `func` |
| 27 | `*func-audiobook2_acq-mbep2d_ME_19mm` | `task-audiobook2_bold` | `func` |
| 28 | `*func-oceans11_acq-mbep2d_ME_19mm` | `task-oceans11_bold` | `func` |
| 29 | `*func-social_acq-mbep2d_ME_19mm` | `task-social_bold` | `func` |
| 30 | `*func-sens1_acq-mbep2d_ME_19mm` | `task-sens2_bold` | `func` |
| 31 | `*func-sens2_acq-mbep2d_ME_19mm` | `task-sens1_bold` | `func` |
| 32 | `*func-slient1_acq-mbep2d_ME_19mm` | `task-salient_bold` | `func` |

### Abbreviation Glossary

| **Abbreviation** | **Description**                                               |
|------------------|---------------------------------------------------------------|
| **AP**           | Anterio-Posterior                                             |
| **PA**           | Postero-anterior                                              |
| **mtw**          | Magnetic transfer weighted                                    |
| **sfmap**        | Scaled flip angle map                                         |
| **tof**          | Time of flight                                                |
| **multib**       | Multi shell N directions                                      |
| **semphon**      | Semantic-phonetic                                             |
| **romeo**        | Rapid Opensource Minimum-spanning treE algOrithm              |
| **aspire**       | A Simple Phase Image Reconstruction for multi-Echo data       |
| **Comb**         | ASPIRE Echo Combined                                          |
| **CombSensCor    | ASPIRE Echo Combines Sensitivity Corrected                    |
| **MIP**           | Maximum Intensity Projection                                 |


## Field maps
| **N** | **7T Terra Siemens acquisition**             | **BIDS**                              | **Directory** |
|:-----:|:--------------------------------------------:|:-------------------------------------:|:-------------:|
|  1    | fmap-b1_tra_p2                              | acq-[anat,sfam]_TB1TFL                | fmap          |
|  2    | fmap-b1_acq-sag_p2                          | acq-[anat,sfam]_TB1TFL                | fmap          |
|  3    | fmap-fmri_acq-mbep2d_SE_19mm_dir-AP         | acq-fmri_dir-AP_epi                   | fmap          |
|  4    | fmap-fmri_acq-mbep2d_SE_19mm_dir-PA         | acq-fmri_dir-PA_epi                   | fmap          |

## Functional
| **N** | **7T Terra Siemens acquisition**             | **BIDS**                              | **Directory** |
|:-----:|:--------------------------------------------:|:-------------------------------------:|:-------------:|
|  1    | func-cross_acq-ep2d_MJC_19mm                | task-rest_bold                        | func          |
|  2    | func-cloudy_acq-ep2d_MJC_19mm               | task-cloudy_bold                      | func          |
|  3    | func-present_acq-mbep2d_ME_19mm             | task-present_bold                     | func          |

> Each functional MRI acquisition includes three echoes and a phase. The final string will contain the identifier `echo-` followed by the echo number (e.g., `task-rest_echo-1_bold`). Additionally, the string `part-phase` will be included to identify the phase (e.g., `task-rest_echo-1_part-phase_bold`).

# Naming convention | Diffusion weighted Images
| **N** | **7T Terra Siemens acquisition**             | **BIDS**                              | **Directory** |
|:-----:|:--------------------------------------------:|:-------------------------------------:|:-------------:|
|  1    | *dwi_acq_b0_PA                               | acq-b0_dir-PA_dwi                     | dwi           |
|  2    | *dwi_acq_b0_PA_SBRef                         | acq-b0_dir-PA_sbref                   | dwi           |
|  3    | *dwi_acq_multib_38dir_AP_acc9                | acq-multib38_dir-AP_dwi               | dwi           |
|  4    | *dwi_acq_multib_38dir_AP_acc9_SBRef          | acq-multib38_dir-AP_sbref             | dwi           |
|  5    | *dwi_acq_multib_70dir_AP_acc9                | acq-multib70_dir-AP_dwi               | dwi           |
|  6    | *dwi_acq_multib_70dir_AP_acc9_SBRef          | acq-multib70_dir-AP_sbref             | dwi           |

> The string `part-phase` will be included to identify the phase acquisitions (e.g., `acq-multib38_dir-AP_part-phase_dwi`).

### Abbreviation Glossary

| **Abbreviation** | **Description**                                               |
|-------------------|---------------------------------------------------------------|
| **AP**           | Anterio-Posterior                                             |
| **PA**           | Postero-anterior                                              |
| **mtw**          | Magnetic transfer weighted                                    |
| **sfmap**         | Scaled flip angle map                                        |
| **tof**          | Time of flight                                                |
| **multib**       | Multi shell N directions                                      |
| **semphon**      | Semantic-phonetic                                             |
| **romeo**        | Rapid opensource minimum spanning tree algorithm              |
| **aspire**       | Combination of multi-channel phase data from multi-echo acquisitions |

# References

1. Eckstein K, Dymerska B, Bachrata B, Bogner W, Poljanc K, Trattnig S, Robinson SD. Computationally efficient combination of multi‐channel phase data from multi‐echo acquisitions (ASPIRE). Magnetic resonance in medicine. 2018 Jun;79(6):2996-3006. https://doi.org/10.1002/mrm.26963

2. Dymerska B, Eckstein K, Bachrata B, Siow B, Trattnig S, Shmueli K, Robinson SD. Phase unwrapping with a rapid opensource minimum spanning tree algorithm (ROMEO). Magnetic resonance in medicine. 2021 Apr;85(4):2294-308. https://doi.org/10.1002/mrm.28563

3. Sasaki M, Shibata E, Tohyama K, Takahashi J, Otsuka K, Tsuchiya K, Takahashi S, Ehara S, Terayama Y, Sakai A. Neuromelanin magnetic resonance imaging of locus ceruleus and substantia nigra in Parkinson's disease. Neuroreport. 2006 Jul 31;17(11):1215-8. https://doi.org/10.1097/01.wnr.0000227984.84927.a7 

## Target software version

| **Software**       | **Version**     |
|--------------------|-----------------|
| BIDS Specification | `v1.11.1`       |
| BIDS Validator     | `v2.4.1`        |
| dcm2niix           | `v1.0.20260416` |
| python             |  3.8            |

# Runing singularity
```bash
# Define directories
bids=/BIDS_MPN/rawdata/
dicoms=/BIDS_MPN/dicoms

# Path to singularity image
img=<path_to_image>/dcm2bids_v0.1.2.sif

# Define subject and session 
sub=MPNphantom
ses=v1

# Call singularity
singularity run --writable-tmpfs --containall \
	-B ${bids}:/bids -B ${dicoms}:/dicoms \
    ${img} --sub $sub --ses $ses --dicoms_dir /dicoms --sorted_dir /dicoms --bids_dir /bids
```
