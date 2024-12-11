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
    --sub (str): Subject ID, NO sub- string.
    --ses (str): Session ID, NO ses- string.
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
dicoms_dir = os.path.abspath(args.dicoms_dir)
bids_dir = os.path.abspath(args.bids_dir)
sub = args.sub
ses = args.ses

# Remove strings if they exist in sub and ses
sub = sub.replace('sub-', '')
ses = ses.replace('ses-', '')

# Set workflow
def run_command(command):
    try:
        subprocess.run(command.split(), check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error occurred while running command: {command}. Exception: {e}")
        print(e)
        raise

# Workflow steps
def sorted2bids(tmpdirname):
    print("/n[step 2] ... Running Sorted dicoms to BIDS .../n")
    run_command(f"mpn_sorted2bids.sh -in {tmpdirname} -id {sub} -ses {ses} -o {bids_dir}")

def validate_bids():
    print("/n[step 3] ... Running BIDS validator .../n")
    command = f'deno run --allow-write -ERN jsr:@bids/validator {bids_dir} --ignoreWarnings --outfile {bids_dir}/bids_validator_output.txt'
    print(f"Running command: {command}")
    run_command(command)

def main():
    # Set a timer
    start_time = time.time()

    # Create a temporary directory
    with tempfile.TemporaryDirectory() as tmpdirname:
        print(f"Created temporary directory at {tmpdirname}")

        # Change to the temporary directory
        os.chdir(tmpdirname)

        # Run sort_dicoms
        print("/n[step 1] ... Running Sorting dicoms .../n")
        run_command(f'dcmSort.sh {dicoms_dir} {tmpdirname}')

        # Run sorted2bids
        sorted2bids(tmpdirname)

        # Run validate_bids
        validate_bids()

        # Print validate_bids output
        with open(os.path.join(bids_dir, 'bids_validator_output.txt'), 'r') as file:
            print(file.read())
        
        elapsed_time = time.time() - start_time
        minutes, seconds = divmod(elapsed_time, 60)
        print(f"Workflow completed successfully in {minutes:.0f} minutes and {seconds:.0f} seconds.")

if __name__ == "__main__":
    main()