#!/bin/bash
#
# ---------------------------------------------------------------------------------
# dicoms_sorted to BIDS v.2.0.0
# ---------------------------------------------------------------------------------

Col="38;5;83m" # Color code
#---------------- FUNCTION: HELP ----------------#
help() {
echo -e "\033[38;5;141m
Usage:    $(basename $0)\033[0m  \033[38;5;197m-in\033[0m <DICOMS_directory> \033[38;5;197m-id\033[0m <control_01> \033[38;5;197m-bids\033[0m <BIDS directory path>\n
\t\t\033[38;5;197m-in\033[0m 	Input directory with the subject's DICOMS directories (FULL PATH)
\t\t\033[38;5;197m-id\033[0m 	Subject identification for the new BIDS directory
\t\t\t  -id CAN be different than -in DICOMS directory
\t\t\033[38;5;197m-ses\033[0m 	flag to specify the session number (DEFAULT is 'ses-pre')
\t\t\033[38;5;197m-bids\033[0m 	Path to BIDS directory ( . or FULL PATH)

\t\t\033[38;5;197m-force\033[0m 	flag that will overwrite the directory

Check output with: http://bids-standard.github.io/bids-validator/

NOTE: This script REQUIRES dcm2niix to work: https://github.com/rordenlab/dcm2niix

RRC
McGill University, MNI, MICA-lab, November 2024
raul.rodriguezcrcues@mcgill.ca
"
}

cmd() {
    # Prepare the command for logging
    local str="$(whoami) @ $(uname -n) $(date)"
    local l_command=""
    local logfile=""
    for arg in "$@"; do
        case "$arg" in
            -fake|-no_stderr) ;; # Ignore -fake and -no_stderr
            -log) logfile="$2"; shift ;; # Capture logfile and skip to next argument
            *) l_command+="${arg} " ;; # Append arguments to the command
        esac
        shift
    done

    # Print the command with timestamp
    [[ ${quiet} != TRUE ]] && echo -e "\033[38;5;118m\n${str}:\ncommand: \033[38;5;122m${l_command}  \033[0m"

    # Execute the command if not in test mode
    [[ -z "$TEST" ]] && eval "$l_command"
}

# Print error message in red
Error() {
    echo -e "\033[38;5;9m\n-------------------------------------------------------------\n\n[ ERROR ]..... $1\n-------------------------------------------------------------\033[0m\n"
}

# Print warning message with black background and yellow text
Warning() {
    echo -e "\033[48;5;0;38;5;214m\n[ WARNING ]..... $1 \033[0m\n"
}

# Print informational message in blue
Info() {
    local Col="38;5;75m" # Color code
    [[ ${quiet} != TRUE ]] && echo -e "\033[$Col\n[ INFO ]..... $1 \033[0m"
}

#------------------------------------------------------------------------------#
#			ARGUMENTS
# Number of inputs
if [ "$#" -gt 10 ]; then Error "Too may arguments"; help; exit 0; fi
# Create VARIABLES
for arg in "$@"
do
  case "$arg" in
  -h|-help)
    help
    exit 1
  ;;
  -in)
   SUBJ_DIR=$2
   shift;shift
  ;;
  -id)
   Subj=${2/sub-/}
   shift;shift
  ;;
  -force)
   force=TRUE
   shift;shift
  ;;
  -bids)
   BIDS_DIR=$2
   shift;shift
  ;;
  -ses)
   SES=$2
   shift;shift
  ;;
   esac
done

# argument check out & WARNINGS
arg=($SUBJ_DIR $Subj $BIDS_DIR)
if [ "${#arg[@]}" -lt 3 ]; then help
Error "One or more mandatory arguments are missing:
         -id    $Subj
         -in    $SUBJ_DIR
         -bids  $BIDS_DIR"
exit 0; fi

# Add the real path to the directories
SUBJ_DIR=$(realpath "$SUBJ_DIR")
BIDS_DIR=$(realpath "$BIDS_DIR")

# Sequence names and variables (ses is for default "ses-pre")
if [ -z ${SES} ]; then
  id="sub-${Subj}_"
  SES="SINGLE"
  BIDS="${BIDS_DIR}/sub-${Subj}"
else
  SES="ses-${SES/ses-/}";
  id="sub-${Subj}_${SES}_"
  BIDS="${BIDS_DIR}/sub-${Subj}/${SES}"
fi

echo -e "\n\033[38;5;141m
-------------------------------------------------------------
        DICOM to BIDS - Subject $Subj - Session $SES
-------------------------------------------------------------\033[0m"

# argument check out & WARNINGS
if [ "${#arg[@]}" -eq 0 ]; then help; exit 0; fi
if [[ -z $(which dcm2niix) ]]; then Error "dcm2niix NOT found"; exit 0; else Info "dcm2niix was found and is ready to work."; fi

# Check mandatory inputs: -id
arg=("$Subj")
if [ "${#arg[@]}" -lt 1 ]; then Error "Subject id is missing: $Subj"; help; exit 0; fi
if [[ "$Subj" =~ ['!@#$%^&*()_+'] ]]; then Error "Subject id shouldn't contain special characters:\n\t\t\t['!@#\$%^&*()_+']"; exit 0; fi

# check mandatory inputs: -bids
if [[ -z "$BIDS_DIR" ]]; then Error "BIDS directory is empty"; exit 0; fi

# check mandatory inputs: -in Is $SUBJ_DIR found?
if [ ! -d "${SUBJ_DIR}" ]; then Error "Subject DICOMS directory doesn't exist: \n\t ${Subj}"; exit 0; fi

# overwrite BIDS-SUBJECT
if [[ "${force}" == TRUE ]]; then rm -rf "${BIDS}"; fi
if [ -d ${BIDS} ]; then Error "Output directory already exist, use -force to overwrite it. \n\t    ${BIDS}\t    "; exit 0; fi

# Save actual path
here=$(pwd)

# -----------------------------------------------------------------------------------------------
# New BIDS-naming, follow the BIDS specification:
# https://bids-specification.readthedocs.io/en/stable/04-modality-specific-files/01-magnetic-resonance-imaging-data.html
orig=(
    "*anat-T1w_acq_mprage_0.8mm_CSptx"
    "*fmap-b1_*_p2"
    "*fmap-fmri_acq-mbep2d_SE_19mm_dir-AP"
    "*fmap-fmri_acq-mbep2d_SE_19mm_dir-PA"
    "*func-cloudy_acq-ep2d_MJC_19mm"
    "*func-present_acq-ep2d_MJC_19mm"
    "*func-cross_acq-ep2d_MJC_19mm"
    "*func-semphon1_acq-mbep2d_ME_19mm"
    "*func-semphon2_acq-mbep2d_ME_19mm"
    "*func-rsfmri_acq-multiE_1.9mm"
    "*func-rsfmri_acq-mbep2d_ME_19mm"
    "*anat-T1w_acq-mp2rage_0.7mm_CSptx_INV1"
    "*anat-T1w_acq-mp2rage_0.7mm_CSptx_INV2"
    "*anat-T1w_acq-mp2rage_0.7mm_CSptx_T1_Images"
    "*anat-T1w_acq-mp2rage_0.7mm_CSptx_UNI_Images"
    "*anat-T1w_acq-mp2rage_0.7mm_CSptx_UNI-DEN"
    "*anat-flair_acq-0p7iso_UPAdia"
    "*CLEAR-SWI_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*Romeo_P_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*Romeo_Mask_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*Romeo_B0_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*Aspire_M_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*Aspire_P_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*EchoCombined_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*sensitivity_corrected_mag_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*T2star_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*anat-mtw_acq-MTON_07mm"
    "*anat-mtw_acq-MTOFF_07mm"
    "*anat-mtw_acq-T1w_07mm"
    "*anat-nm_acq-MTboost_sag_0.55mm"
    "*anat-angio_acq-tof_03mm_inplane"
    "*anat-angio_acq-tof_03mm_inplane_MIP_SAG"
    "*anat-angio_acq-tof_03mm_inplane_MIP_COR"
    "*anat-angio_acq-tof_03mm_inplane_MIP_TRA"
)

bids=(
    T1w
    acq-anat_TB1TFL
    acq-fmri_dir-AP_epi
    acq-fmri_dir-PA_epi
    task-cloudy_bold
    task-present_bold
    task-rest_bold
    task-semphon1_bold
    task-semphon2_bold
    task-rest_bold
    task-rest_bold
    inv-1_MP2RAGE
    inv-2_MP2RAGE
    T1map
    UNIT1
    desc-denoised_UNIT1
    FLAIR
    acq-SWI_GRE
    acq-romeo_T2starw
    acq-romeo_desc-mask_T2starw
    acq-romeo_desc-unwrapped_T2starw
    acq-aspire_T2starw
    acq-aspire_T2starw
    acq-aspire_desc-echoCombined_T2starw
    acq-aspire_desc-echoCombinedSensitivityCorrected_T2starw
    acq-aspire_T2starw
    acq-mtw_mt-on_MTR
    acq-mtw_mt-off_MTR
    acq-mtw_T1w
    acq-neuromelaninMTw_T1w
    angio
    acq-sag_angio
    acq-cor_angio
    acq-tra_angio
)

origDWI=(
  "*dwi_acq_b0_PA"
  "*dwi_acq_b0_PA_SBRef"
  "*dwi_acq_multib_38dir_AP_acc9"
  "*dwi_acq_multib_38dir_AP_acc9_SBRef"
  "*dwi_acq_multib_70dir_AP_acc9"
  "*dwi_acq_multib_70dir_AP_acc9_SBRef"
)

bidsDWI=(
  acq-b0_dir-PA_dwi
  acq-b0_dir-PA_sbref
  acq-multib38_dir-AP_dwi
  acq-multib38_dir-AP_sbref
  acq-multib70_dir-AP_dwi
  acq-multib70_dir-AP_sbref
)

#-----------------------------------------------------------------------------------------------
# Create BIDS/subj_dir
cmd mkdir -p "$BIDS"/{anat,func,dwi,fmap}
if [ ! -d "$BIDS" ]; then Error "Could not create subject BIDS directory, check permissions \n\t     ${BIDS}\t    "; exit 0; fi

# Change working directory
cmd cd $SUBJ_DIR

# dicomx to Nifti with BIDS Naming
for k in "${!orig[@]}"; do
  bids_name=${bids[k]}
  mri="${bids_name##*_}"                                                                                                                                                      
  acq="${bids_name%_*}"
  # Check if acq_string is not empty
  if [[ ${acq} == ${mri} ]]; then acq=""; else acq="${acq}_"; fi
  # Find the number of dicoms_sorted with the sequence name (quiet)
  N=$(ls -d ${orig[k]} 2>/dev/null | wc -l)
  if [ "$N" -gt 1 ]; then
    Names=($(ls -d ${orig[k]}))
    for i in "${!Names[@]}"; do
       out_name="${id}${acq}run-$((i+1))_${mri}"
       dcm2niix -z y -b y -o "$BIDS" -f "$out_name" ${Names[i]}
    done
  elif [ "$N" -eq 1 ]; then
     dcm2niix -z y -b y -o "$BIDS" -f ${id}${bids_name} ${orig[k]}
  fi
done

# Moving files to their correct directory location
if ls "$BIDS"/*MP2RAGE* 1> /dev/null 2>&1; then mv "$BIDS"/*MP2RAGE* "$BIDS"/anat; fi
if ls "$BIDS"/*UNIT1* 1> /dev/null 2>&1; then mv "$BIDS"/*UNIT1* "$BIDS"/anat; fi
if ls "$BIDS"/*bold* 1> /dev/null 2>&1; then mv "$BIDS"/*bold* "$BIDS"/func; fi
if ls "$BIDS"/*T1* 1> /dev/null 2>&1; then mv "$BIDS"/*T1* "$BIDS"/anat; fi
if ls "$BIDS"/*T2* 1> /dev/null 2>&1; then mv "$BIDS"/*T2* "$BIDS"/anat; fi
if ls "$BIDS"/*fieldmap* 1> /dev/null 2>&1; then mv "$BIDS"/*fieldmap* "$BIDS"/fmap; fi
if ls "$BIDS"/*TB1TFL* 1> /dev/null 2>&1; then mv "$BIDS"/*TB1TFL* "$BIDS"/fmap; fi
if ls "$BIDS"/*FLAIR* 1> /dev/null 2>&1; then mv "$BIDS"/*FLAIR* "$BIDS"/anat; fi
if ls "$BIDS"/*angio* 1> /dev/null 2>&1; then mv "$BIDS"/*angio* "$BIDS"/anat; fi
if ls "$BIDS"/*MTR* 1> /dev/null 2>&1; then mv "$BIDS"/*MTR* "$BIDS"/anat; fi
# SWI | GRE https://docs.google.com/document/d/1kyw9mGgacNqeMbp4xZet3RnDhcMmf4_BmRgKaOkO2Sc/edit?tab=t.0#heading=h.kc8slmd5olof
if ls "$BIDS"/*GRE* 1> /dev/null 2>&1; then mv "$BIDS"/*GRE* "$BIDS"/anat; fi

# Rename echos: echo-1_bold.nii.gz
if ls ${BIDS}/func/*bold_e* 1> /dev/null 2>&1; then
for i in {1..3}; do
    str="bold_e${i}"
    for f in ${BIDS}/func/*${str}*; do
        mv $f ${f/${str}/echo-${i}_bold}
    done
done
fi

# Rename T2starw: echo-?_T2starw_.nii.gz
if ls ${BIDS}/anat/*T2starw_e* 1> /dev/null 2>&1; then
for i in {1..5}; do
    str="T2starw_e${i}"
    for f in ${BIDS}/anat/*${str}*; do
        mv $f ${f/${str}/echo-${i}_part-mag_T2starw}
    done
done
fi

# REPLACE "_ph" with "part-phase"
replace_suffix() {
    local pattern=$1
    local replacement=$2
    local dir=$3

    if ls "$dir"/*"$pattern"* 1> /dev/null 2>&1; then
        for file in "$dir"/*"$pattern"*; do
            mv "$file" "${file/$pattern/$replacement}"
        done
    fi
}

# Apply replacements
replace_suffix "bold_ph" "part-phase_bold" "$BIDS/func"
replace_suffix "MTR_ph" "part-phase_MTR" "$BIDS/anat"
replace_suffix "part-mag_T2starw_ph" "part-phase_T2starw" "$BIDS/anat"
replace_suffix "unwrapped_T2starw_ph" "unwrapped_part-phase_T2starw" "$BIDS/anat"
replace_suffix "T1w_ph" "part-phase_T1w" "$BIDS/anat"

# Remove the run-? from the task-rest when there is only 1 run
func_rename() {
  func_acq=$1
  # remove run-? from echo-?_bold if there are 6 files (ONLY 1 run)
  if [ $(ls "$BIDS"/func/*${func_acq}_run-?_echo-?_bold* 2>/dev/null | wc -l) -eq 6 ]; then
    # run-1 is the fMRI and run-2 is the phase
    for func in $(ls "$BIDS"/func/*"${func_acq}_run-1_echo-"?_bold*); do mv "$func" "${func/_run-1/}"; done
    for func in $(ls "$BIDS"/func/*"${func_acq}_run-2_echo-"?_part-phase_bold*); do mv "$func" "${func/_run-2/}"; done
  fi
}
func_rename "task-rest"

# Remove runs from MTR acquisitions
if ls "$BIDS"/anat/*acq-mtw_mt-off_run-?_MTR.json 1> /dev/null 2>&1; then
  # Info "REMOVE the run-? from MTR"
  for mtr in $(ls "$BIDS"/anat/*"*acq-mtw*"*); do
    mv "$mtr" "${mtr/_run-?/}"
  done
fi

# Remove bvals and bvecs from MP2RAGE
if ls "$BIDS"/anat/*MP2RAGE.bv* 1> /dev/null 2>&1; then
  Info "Remove MP2RAGE bval and bvecs"
  rm "$BIDS"/anat/*MP2RAGE.bv*
fi

# -----------------------------------------------------------------------------------------------
Info  "TB1TFL - B1 fieldmaps"
# -----------------------------------------------------------------------------------------------
tb1tfl_rename() {
    # If there is two files, remove the run-? and and the second file will be the scaled flip angle map (sfam) 
    b1s=($(ls "${BIDS}/fmap/"*acq-anat_*TB1TFL*gz))
    if [[ ${#b1s[@]} -eq 2 ]]; then
      Info "Make run-1 anat and run-2 the sfam"
      replace_suffix "acq-anat_run-1_TB1TFL" "acq-anat_TB1TFL" "$BIDS/fmap"
      replace_suffix "acq-anat_run-2_TB1TFL" "acq-sfam_TB1TFL" "$BIDS/fmap"
    elif [[ ${#b1s[@]} -gt 2 ]]; then
      Info "Process the naming of multiple TB1TFL runs in corresponding pairs"
      for ((i=0; i<${#b1s[@]}; i+=2)); do
          file1="${b1s[$i]}"
          file2="${b1s[$i+1]}"
          run_num=$((i / 2 + 1))
          # Rename both files and their JSON counterparts
          mv "$file1" "${BIDS}/fmap/${id}acq-anat_run-${run_num}_TB1TFL.nii.gz"
          mv "$file2" "${BIDS}/fmap/${id}acq-sfam_run-${run_num}_TB1TFL.nii.gz"
          mv "${file1/nii.gz/json}" "${BIDS}/fmap/${id}acq-anat_run-${run_num}_TB1TFL.json"
          mv "${file2/nii.gz/json}" "${BIDS}/fmap/${id}acq-sfam_run-${run_num}_TB1TFL.json"
      done
    fi
}

# Rename TB1TFL files
if ls "${BIDS}/fmap/"*acq-anat_*TB1TFL*gz 1> /dev/null 2>&1; then tb1tfl_rename; fi

# -----------------------------------------------------------------------------------------------
# Rename T2starmap
if ls "$BIDS"/anat/${id}acq-aspire_T2starw.* 1> /dev/null 2>&1; then 
  for t2 in "$BIDS"/anat/${id}acq-aspire_T2starw.*; do 
    mv $t2 ${t2/T2starw/T2starmap} 
  done
fi

# -----------------------------------------------------------------------------------------------
Info "DWI acquisitions"
# -----------------------------------------------------------------------------------------------
# Loop through the directories of DWI acquisitions
for k in "${!origDWI[@]}"; do
  bids_name=${bidsDWI[k]}
  mri="${bids_name##*_}"                                                                                                                                                      
  acq="${bids_name%_*}"
  # Check if acq_string is not empty
  if [[ ${acq} == ${mri} ]]; then acq=""; else acq="${acq}_"; fi
  # Find the number of dicoms_sorted with the sequence name (quiet)
  N=$(ls -d ${origDWI[k]} 2>/dev/null | wc -l)
  if [ "$N" -gt 1 ]; then
    Names=($(ls -d ${origDWI[k]}))
    for i in "${!Names[@]}"; do
       out_name="${id}${acq}run-$((i+1))_${mri}"
       dcm2niix -z y -b y -o "$BIDS" -f "$out_name" ${Names[i]}
    done
  elif [ "$N" -eq 1 ]; then
     dcm2niix -z y -b y -o "$BIDS" -f ${id}${bids_name} ${origDWI[k]}
  fi
done

# Change directory 
cmd cd "$BIDS"

Info "Moving files to their correct directory location"
if ls "$BIDS"/*b0* 1> /dev/null 2>&1; then mv "$BIDS"/*b0* "$BIDS"/dwi; fi
if ls "$BIDS"/*sbref* 1> /dev/null 2>&1; then mv "$BIDS"/*sbref* "$BIDS"/dwi; fi
if ls "$BIDS"/*dwi.* 1> /dev/null 2>&1; then mv "$BIDS"/*dwi.* "$BIDS"/dwi; fi
if ls "$BIDS"/*epi* 1> /dev/null 2>&1; then mv "$BIDS"/*epi* "$BIDS"/fmap; fi
if ls "$BIDS"/anat/*ROI* 1> /dev/null 2>&1; then rm "$BIDS"/anat/*ROI*; fi

dwi_rename() {
    local dwi_acq=$1
    # If there is two files, remove the run-? and and the second file will be the phase
    dwis=($(ls ${BIDS}/dwi/*${dwi_acq}*_dwi.nii.gz))
    Info "DWIS ${dwi_acq}: ${#dwis[@]}"
    if [[ ${#dwis[@]} -eq 2 ]]; then
      Info "REMOVE run-1 string from new 7T DWI acquisition & Make the run-2 the phase file"
      replace_suffix "${dwi_acq}_run-1_dwi" "${dwi_acq}_dwi" "$BIDS/dwi"
      replace_suffix "${dwi_acq}_run-2_dwi" "${dwi_acq}_part-phase_dwi" "$BIDS/dwi"
    elif [[ ${#dwis[@]} -gt 2 ]]; then
      Info "Process the naming of multiple DWI runs in corresponding pairs"
      for ((i=0; i<${#dwis[@]}; i+=2)); do
          file1="${dwis[$i]}"
          file2="${dwis[$i+1]}"
          run_num=$((i / 2 + 1))
          # Rename both files and their JSON counterparts
          mv "$file1" "${BIDS}/dwi/${id}${dwi_acq}_run-${run_num}_dwi.nii.gz"
          mv "$file2" "${BIDS}/dwi/${id}${dwi_acq}_run-${run_num}_part-phase_dwi.nii.gz"
          mv "${file1/nii.gz/json}" "${BIDS}/dwi/${id}${dwi_acq}_run-${run_num}_dwi.json"
          mv "${file2/nii.gz/json}" "${BIDS}/dwi/${id}${dwi_acq}_run-${run_num}_part-phase_dwi.json"
      done
    fi
}

# Rename the phase files (run-2 or mulples of 2)
dwi_rename acq-multib38_dir-AP
dwi_rename acq-multib70_dir-AP
dwi_rename acq-b0_dir-PA

# Replace file names with the correct suffix
replace_suffix "sbref_ph" "part-phase_sbref" "$BIDS/dwi"
replace_suffix "dwi_ph" "part-phase_dwi" "$BIDS/dwi"

# -----------------------------------------------------------------------------------------------
Info "Add Units to the phase files"
for file in "$BIDS"/*/*phase*json; do
  # Add the key "Units": "arbitrary" to the JSON file
  jq '. + {"Units": "rad"}' "$file" > tmp.$$.json && mv tmp.$$.json "$file"
done

# -----------------------------------------------------------------------------------------------
Info "Add MTState to the mt scans"
# Add MTState to the mt-off scans
for file in "$BIDS"/*/*mt-off*json; do
  # Add the key "MTState": "False" to the JSON file
  jq '. + {"MTState": false}' "$file" > tmp.$$.json && mv tmp.$$.json "$file"
done
for file in "$BIDS"/*/*mt-on*json; do
  # Add the key "MTState": "False" to the JSON file
  jq '. + {"MTState": true}' "$file" > tmp.$$.json && mv tmp.$$.json "$file"
done

# -----------------------------------------------------------------------------------------------
# QC, count the number of Niftis (json) per subject
dat=$(stat ${BIDS} | awk 'NR==6 {print $2}')
anat=$(ls -R ${BIDS}/anat | grep gz | wc -l)
dwi=$(ls -R ${BIDS}/dwi | grep gz | wc -l)
func=$(ls -R ${BIDS}/func | grep gz | wc -l)
fmap=$(ls -R ${BIDS}/fmap | grep gz | wc -l)

# check mandatory inputs: -in Is $SUBJ_DIR found?
tsv_file="$BIDS_DIR"/participants_7t2bids.tsv
# Check if file exist
if [ ! -f "$tsv_file" ]; then echo -e "sub\tses\tdate\tN.anat\tN.dwi\tN.func\tN.fmap\tdicoms\tuser" > "$tsv_file"; fi
# Add information about subject
echo -e "${Subj}\t${SES/ses-/}\t${dat}\t${anat}\t${dwi}\t${func}\t${fmap}\t${SUBJ_DIR}\t${USER}" >> "$tsv_file"

# -----------------------------------------------------------------------------------------------
# Gitignore file
bidsignore="$BIDS_DIR"/.bidsignore
# Check if file exist
if [ ! -f "$bidsignore" ]; then echo -e "participants_7t2bids.tsv\nbids_validator_output.txt\nsub*/ses*/anat/*desc-*\nsub*/ses*/anat/*GRE*" > "$bidsignore"; fi

# -----------------------------------------------------------------------------------------------
# Add the new subject to the participants.tsv file
participants_tsv="$BIDS_DIR"/participants.tsv
# Check if file exist
if [ ! -f "$participants_tsv" ]; then echo -e "participant_id\tsite\tgroup" > "$participants_tsv"; fi
# Remove existing entry if it exists
grep -v -P "^sub-${Subj}" "$participants_tsv" > "${participants_tsv}.tmp" && mv "${participants_tsv}.tmp" "$participants_tsv"
# Add information about subject
echo -e "sub-${Subj}\tMontreal_SiemmensTerra7T\tHealthy" >> "$participants_tsv"

# create a sessions tsv
sessions_tsv="${BIDS_DIR}/sub-${Subj}/sub-${Subj}_sessions.tsv"
if [ ! -f "$sessions_tsv" ]; then echo -e "session_id" > "$sessions_tsv"; fi
# Remove existing entry if it exists
grep -v -P "^${SES}" "$sessions_tsv" > "${sessions_tsv}.tmp" && mv "${sessions_tsv}.tmp" "$sessions_tsv"
# Add information about subject
echo -e "${SES}" >> "$sessions_tsv"

# -----------------------------------------------------------------------------------------------
# Get the repository path
gitrepo=$(dirname $(dirname $(realpath "$0")))

# Copy json files to the BIDS directory
if [ ! -f "$BIDS_DIR"/participants.json ]; then cp -v "$gitrepo"/participants.json "$BIDS_DIR"/participants.json; fi

# Add the task jsons
tasks=($(ls ${BIDS}/func | grep -oP '(?<=task-)[^_]*' | sort -u))
for i in ${!tasks[@]}; do
    if [ ! -f "$BIDS_DIR"/task-${tasks[$i]}.json ]; then 
    # Create task json files
    cp "$gitrepo"/task-template_bold.json "$BIDS_DIR"/task-${tasks[$i]}_bold.json
    # Replace strings
    sed -i "s/TASK_NAME/${tasks[$i]}/g" "$BIDS_DIR"/task-${tasks[$i]}_bold.json
    fi
done

# Copy the data_set_description.json file to the BIDS directory
if [ ! -f "$BIDS_DIR"/dataset_description.json ]; then cp -v "$gitrepo"/dataset_description.json "$BIDS_DIR"/dataset_description.json; fi

# Copy the data_set_description.json file to the BIDS directory
if [ ! -f "$BIDS_DIR"/CITATION.cff ]; then cp -v "$gitrepo"/CITATION.cff "$BIDS_DIR"/CITATION.cff; fi

# Create README
echo -e "This dataset was provided by the Montreal-Paris Neurobanque initiative, Montreal Neurological Institute and Hospital, The Neuro.\n\nIf you reference this dataset in your publications, please acknowledge its authors." > "$BIDS_DIR"/README

# -----------------------------------------------------------------------------------------------
# Go back to initial directory
cd "$here"

# Remove any tmp files if any
if ls "${BIDS}"/tmp* 1> /dev/null 2>&1; then cmd rm "$BIDS"/tmp*; fi

Info "Remember to validate your BIDS directory:
      http://bids-standard.github.io/bids-validator/"
