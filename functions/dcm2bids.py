"""
This script converts DICOM files to BIDS format using the MPN 7T workflow.

Modules:
    os: Provides a way of using operating system dependent functionality.
    subprocess: Allows you to spawn new processes, connect to their input/output/error pipes, and obtain their return codes.
    tempfile: Generates temporary files and directories.
    bids_validator: Validates BIDS datasets.
    argparse: Parses command-line arguments.

Functions:
    run_command(command):
        Executes a shell command and raises an error if the command fails.
        Args:
            command (str): The command to be executed.
        Raises:
            subprocess.CalledProcessError: If the command execution fails.

    main():
        Main function that sets up the workflow for converting DICOMs to BIDS format.
        It creates a temporary directory, runs the necessary scripts, and validates the BIDS output.

Arguments:
    --dicoms_dir (str): Directory containing DICOM files.
    --bids_dir (str): Output BIDS directory.
    --sub (str): Subject ID.
    --ses (str): Session ID.
"""
import os
import subprocess
import tempfile
import argparse
import time

# Arguments
parser = argparse.ArgumentParser(description='Convert DICOMs to BIDS format.')
parser.add_argument('--dicoms_dir', required=True, help='Directory containing DICOM files')
parser.add_argument('--bids_dir', required=True, help='Output BIDS directory')
parser.add_argument('--sub', required=True, help='Subject ID')
parser.add_argument('--ses', required=True, help='Session ID')

args = parser.parse_args()
dicoms_dir = args.dicoms_dir
bids_dir = args.bids_dir
sub = args.sub
ses = args.ses

# Set workflow
def run_command(command):
    try:
        subprocess.run(command, check=True, shell=True)
    except subprocess.CalledProcessError as e:
        print(f"Error occurred while running command: {command}")
        print(e)
        raise

# Workflow steps
def sort_dicoms():
    print("Sorting DICOMs with dcm2Sort...")
    run_command(f'dcm2Sort.sh {dicoms_dir} {os.path.join(bids_dir, "sorted_dicoms")}')

def sorted2bids():
    print("Converting sorted DICOMs to BIDS format with dcm2niix sorted2bids...")
    run_command(f'mpn_sorted2bids.sh -b y -z y -o {bids_dir} -f "%p_%s" {os.path.join(bids_dir, "sorted_dicoms")}')

def validate_bids():
    print("Validating BIDS output with bids-validator...")
    run_command(f'deno run --allow-write -ERN jsr:@bids/validator {bids_dir} --ignoreWarnings --outfile {bids_dir}/bids_validator_output.txt')

def main():
    # Set a timer
    start_time = time.time()

    # Create a temporary directory
    with tempfile.TemporaryDirectory() as tmpdirname:
        print(f"Created temporary directory at {tmpdirname}")

        # Change to the temporary directory
        os.chdir(tmpdirname)

        # Run sort_dicoms
        print("Running Sorting dicoms ...")
        sort_dicoms()

        # Run sorted2bids
        print("Running Sorted dicoms to BIDS ...")
        sorted2bids()

        # Run validate_bids
        print("Running BIDS validator ...")
        validate_bids()

        # Print validate_bids output
        with open(os.path.join(bids_dir, 'bids_validator_output.txt'), 'r') as file:
            print(file.read())
        
        # Print success message with time
        elapsed_time = time.time() - start_time
        print(f"Workflow completed successfully in {elapsed_time // 60:.0f} minutes and {elapsed_time % 60:.0f} seconds.")

if __name__ == "__main__":
    main()