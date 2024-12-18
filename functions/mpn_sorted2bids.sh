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
Warn() {
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
# if [ -d ${BIDS} ]; then Error "Output directory already exist, use -force to overwrite it. \n\t    ${BIDS}\t    "; exit 0; fi

# Save actual path
here=$(pwd)

# -----------------------------------------------------------------------------------------------
# New BIDS-naming, follow the BIDS specification:
# https://bids-specification.readthedocs.io/en/stable/04-modality-specific-files/01-magnetic-resonance-imaging-data.html
orig=(
    "*anat-T1w_acq_mprage_0.8mm_CSptx"
    "*fmap-b1_tra_p2"
    "*fmap-b1_acq-sag_p2"
    "*fmap-fmri_acq-mbep2d_SE_19mm_dir-AP"
    "*fmap-fmri_acq-mbep2d_SE_19mm_dir-PA"
    "*func-cloudy_acq-ep2d_MJC_19mm"
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
    "*Romeo_Mask_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*Aspire_M_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*Aspire_P_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*EchoCombined_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*T2star_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*Romeo_P_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*Romeo_B0_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*sensitivity_corrected_mag_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
    "*CLEAR-SWI_anat-T2star_acq-me_gre_0*7iso_ASPIRE"
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
    acq-anatTra_TB1TFL
    acq-anatSag_TB1TFL
    dir-AP_epi
    dir-PA_epi
    task-cloudy_bold
    task-cross_bold
    task-semphon1_bold
    task-semphon2_bold
    task-rest_bold
    task-rest_bold
    inv-1_MP2RAGE
    inv-2_MP2RAGE
    T1map
    UNIT1
    acq-DEN_UNIT1
    FLAIR
    acq-mask_T2starw
    acq-aspire_T2starw
    acq-aspire_T2starw
    acq-EchoCombined_T2starw
    T2starw
    acq-romeo_T2starw
    acq-romeoB0_T2starw
    acq-SensitivityCorrectedMag_T2starw
    acq-clearSWI_T2starmap
    mt-on_MTR
    mt-off_MTR
    acq-MTR_T1w
    acq-neuromelanin_MWFmap
    acq-tof_angio
    acq-tofSag_angio
    acq-tofCor_angio
    acq-tofTra_angio
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
#Create BIDS/subj_dir
cmd mkdir -p "$BIDS"/{anat,func,dwi,fmap}
if [ ! -d "$BIDS" ]; then Error "Could not create subject BIDS directory, check permissions \n\t     ${BIDS}\t    "; exit 0; fi

# dicomx to Nifti with BIDS Naming
cmd cd $SUBJ_DIR
# Warning lenght
n=$((${#orig[@]} - 1))
for ((k=0; k<=n; k++)); do
  N=$(ls -d ${orig[k]} 2>/dev/null | wc -l) # make it quiet
  if [ "$N" -eq 0 ]; then
    Warn "No directories were found with the following name: ${orig[k]}"
  elif [ "$N" -gt 1 ]; then
    Names=($(ls -d ${orig[k]}))
    for ((i = 1; i <= N; i++)); do
       nii=$(echo ${Names[((i-2))]} | awk -F '_' '{print $1 "_" $2}')
       acq=$(echo ${bids[k]} | grep -oP '(?<=acq-)[^_]+')
       # Check if acq_string is not empty
       if [[ -n "$acq" ]]; then acq_string="acq-${acq}_"; else acq_string=""; fi
       nom="${id}${acq_string}run-${i}_${bids[k]/${acq_string}/}"
       cmd dcm2niix -z y -b y -o "$BIDS" -f "$nom" ${nii}${orig[k]}
    done
  elif [ "$N" -eq 1 ]; then
     cmd dcm2niix -z y -b y -o "$BIDS" -f ${id}${bids[k]} ${orig[k]}
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
if ls "$BIDS"/*MWFmap* 1> /dev/null 2>&1; then mv "$BIDS"/*MWFmap* "$BIDS"/anat; fi
if ls "$BIDS"/*angio* 1> /dev/null 2>&1; then mv "$BIDS"/*angio* "$BIDS"/anat; fi
if ls "$BIDS"/*MTR* 1> /dev/null 2>&1; then mv "$BIDS"/*MTR* "$BIDS"/anat; fi

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
        mv $f ${f/${str}/echo-${i}_T2starw}
    done
done
fi

# REPLACE "_ph" with "part-phase"
replace_phase_suffix() {
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
replace_phase_suffix "bold_ph" "part-phase_bold" "$BIDS/func"
replace_phase_suffix "MTR_ph" "part-phase_MTR" "$BIDS/anat"
replace_phase_suffix "T2starw_ph" "part-phase_T2starw" "$BIDS/anat"
replace_phase_suffix "T1w_ph" "part-phase_T1w" "$BIDS/anat"

# remove run-? from echo-?_bold
if ls "$BIDS"/func/*"_run-"* 1> /dev/null 2>&1; then
  Info "REMOVE the run-? from func files (echoes)"
  for func in $(ls "$BIDS"/func/*"_run-"*); do
    mv "$func" "${func/_run-?/}"
  done
fi

if ls "$BIDS"/anat/*MP2RAGE.bv* 1> /dev/null 2>&1; then
  Info "Remove MP2RAGE bval and bvecs"
  rm "$BIDS"/anat/*MP2RAGE.bv*
fi

# Check if there are TB1TFL files
if ls "${BIDS}/fmap/"*TB1TFL*gz 1> /dev/null 2>&1; then
    TB1TFL=($(ls "${BIDS}/fmap/"*TB1TFL*gz))
    Info "Organizing TB1TFL acquisitions"

    # Process files in pairs
    for ((i=0; i<${#TB1TFL[@]}; i+=2)); do
        file1="${TB1TFL[$i]}"
        file2="${TB1TFL[$i+1]}"
        run_num=$((i / 2 + 1))

        # Extract sequence types (anatSag or anatTra) for both files
        seq_type1=$(basename "$file1" | grep -oP "acq-\K\w+(?=_run)")
        seq_type2=$(basename "$file2" | grep -oP "acq-\K\w+(?=_run)")

        # Rename both files and their JSON counterparts
        mv "$file1" "${BIDS}/fmap/${id}acq-${seq_type1/anat/sfam}_run-${run_num}_TB1TFL.nii.gz"
        mv "$file2" "${BIDS}/fmap/${id}acq-${seq_type2}_run-${run_num}_TB1TFL.nii.gz"
        mv "${file1/nii.gz/json}" "${BIDS}/fmap/${id}acq-${seq_type1/anat/sfam}_run-${run_num}_TB1TFL.json"
        mv "${file2/nii.gz/json}" "${BIDS}/fmap/${id}acq-${seq_type2}_run-${run_num}_TB1TFL.json"
    done
fi

# Rename T2starmap
if ls "$BIDS"/anat/${id}T2starw.* 1> /dev/null 2>&1; then 
  for t2 in "$BIDS"/anat/${id}T2starw.*; do 
    mv $t2 ${t2/T2starw/T2starmap} 
  done
fi

# -----------------------------------------------------------------------------------------------
Info "DWI acquisitions"
# -----------------------------------------------------------------------------------------------
# Loop through the directories of DWI acquisitions
n=$((${#origDWI[@]} - 1))
for ((k=0; k<=n; k++)); do
  N=$(ls -d ${origDWI[k]} 2>/dev/null | wc -l) # make it quiet
  if [ "$N" -eq 0 ]; then
    Warn "No directories were found with the following name: ${origDWI[k]}"
  elif [ "$N" -gt 1 ]; then
    Names=($(ls -d ${origDWI[k]} 2>/dev/null))
    for ((i = 0; i < N; i++)); do
      nii=$(echo ${Names[i]} | awk -F '_' '{print $1 "_" $2}')
      nom=${id}${bidsDWI[k]}
      dcm=$(echo ${nom##*_})
      nom=$(echo ${nom/$dcm/}run-$((i+1))_${dcm})
      cmd dcm2niix -z y -b y -o "$BIDS" -f "$nom" "${nii}${origDWI[k]}"
    done
  elif [ "$N" -eq 1 ]; then
     cmd dcm2niix -z y -b y -o "$BIDS" -f "${id}${bidsDWI[k]}" "${origDWI[k]}"
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

if ls "$BIDS"/dwi/*"acq-"*"_dir-"*"_run-1_dwi"* 1> /dev/null 2>&1; then
  Info "REMOVE run-1 string from new 7T DWI acquisition"
  for dwi in $(ls "$BIDS"/dwi/*"acq-"*"_dir-"*"_run-1_dwi"*); do mv "$dwi" "${dwi/run-1_/}"; done
fi

if ls "$BIDS"/dwi/*"acq-"*"_dir-"*"_run-2_dwi"* 1> /dev/null 2>&1; then
  Info "REPLACE run-2 string to part-phase from new 7T DWI acquisition"
  for dwi in $(ls "$BIDS"/dwi/*"acq-"*"_dir-"*"_run-2_dwi"*); do mv "$dwi" "${dwi/run-2_/part-phase_}"; done
fi

if ls "$BIDS"/dwi/*"_sbref_ph"* 1> /dev/null 2>&1; then
  Info "REPLACE \"_sbref_ph\" with \"_part-phase_sbref\""
  for dwi in $(ls "$BIDS"/dwi/*"_sbref_ph"*); do mv "$dwi" "${dwi/_sbref_ph/_part-phase_sbref}"; done
fi

if ls "$BIDS"/dwi/*"_dwi_ph"* 1> /dev/null 2>&1; then
  Info "REPLACE \"_dwi_ph\" with \"_part-phase_dwi\""
  for dwi in $(ls "$BIDS"/dwi/*"_dwi_ph"*); do mv "$dwi" "${dwi/_dwi_ph/_part-phase_dwi}"; done
fi

# -----------------------------------------------------------------------------------------------
# Add Units to the phase files
for file in "$BIDS"/*/*phase*json; do
  # Add the key "Units": "arbitrary" to the JSON file
  jq '. + {"Units": "arbitrary"}' "$file" > tmp.$$.json && mv tmp.$$.json "$file"
done

# -----------------------------------------------------------------------------------------------
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
if [ ! -f "$bidsignore" ]; then echo -e "participants_7t2bids.tsv\nbids_validator_output.txt" > "$bidsignore"; fi

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
tasks_protocols=(func-cloudy_acq-ep2d_MJC_19mm func-cross_acq-ep2d_MJC_19mm func-semphon1_acq-mbep2d_ME_19mm func-semphon2_acq-mbep2d_ME_19mm)
tasks=(cross cloudy semphon1 semphon2 rest)
for i in ${!tasks[@]}; do
    if [ ! -f "$BIDS_DIR"/task-${tasks[$i]}.json ]; then 
    # Create task json files
    cp "$gitrepo"/task-template_bold.json "$BIDS_DIR"/task-${tasks[$i]}_bold.json
    # Replace strings
    sed -i "s/PROTOCOL_NAME/${tasks_protocols[$i]}/g" "$BIDS_DIR"/task-${tasks[$i]}_bold.json
    sed -i "s/TASK_NAME/${tasks[$i]}/g" "$BIDS_DIR"/task-${tasks[$i]}_bold.json
    fi
done

# Copy the data_set_description.json file to the BIDS directory
if [ ! -f "$BIDS_DIR"/dataset_description.json ]; then cp -v "$gitrepo"/dataset_description.json "$BIDS_DIR"/dataset_description.json; fi

# Copy the data_set_description.json file to the BIDS directory
if [ ! -f "$BIDS_DIR"/CITATION.cff ]; then cp -v "$gitrepo"/CITATION.cff "$BIDS_DIR"/CITATION.cff; fi

# Create README
echo -e "This dataset was provided by the Montreal Paris Neurobanque initiative.\n\nIf you reference this dataset in your publications, please acknowledge its authors." > "$BIDS_DIR"/README

# -----------------------------------------------------------------------------------------------
# Go back to initial directory
cd "$here"

# Remove any tmp files if any
if ls "${BIDS}"/tmp* 1> /dev/null 2>&1; then cmd rm "$BIDS"/tmp*; fi

Info "Remember to validate your BIDS directory:
      http://bids-standard.github.io/bids-validator/"
