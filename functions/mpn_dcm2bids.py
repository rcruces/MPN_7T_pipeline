import os
import subprocess
import tempfile
import shutil

def run_command(command):
    try:
        subprocess.run(command, check=True, shell=True)
    except subprocess.CalledProcessError as e:
        print(f"Error occurred while running command: {command}")
        print(e)
        raise

def main():
    # Create a temporary directory
    with tempfile.TemporaryDirectory() as tmpdirname:
        print(f"Created temporary directory at {tmpdirname}")

        # Change to the temporary directory
        os.chdir(tmpdirname)

        # Run dcmsort.sh
        print("Running dcmsort.sh...")
        run_command('./dcmsort.sh')

        # Run mpN_sorted2bids
        print("Running mpN_sorted2bids...")
        run_command('mpN_sorted2bids')

        # Run bids_validator
        print("Running bids_validator...")
        run_command('bids_validator')
        
        # Check if a file is BIDS compatible
        validator = BIDSValidator()
        if validator.is_bids('path/to/a/bids/file'):
            print("The file is BIDS compatible.")
        else:
            print("The file is not BIDS compatible.")

        print("Workflow completed successfully.")

if __name__ == "__main__":
    main()