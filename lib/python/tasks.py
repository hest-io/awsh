import os
import subprocess
from invoke import task
from zipfile import ZipFile
import tempfile
import datetime


@task
def support(c):
    # Create temporary directory
    with tempfile.TemporaryDirectory() as tempdir:
        # Save environment variables to a file
        print("Collecting enviroment variables.")
        with open(os.path.join(tempdir, "env.txt"), "w") as f:
            for key, value in os.environ.items():
                f.write(f"{key}={value}\n")

        # Save versions of important software
        print("Collecting details about utilized software.")
        with open(os.path.join(tempdir, "versions.txt"), "w") as f:
            for software in [
                "python",
                "python3",
                "terraform",
                "aws",
                "ansible",
                "pip",
                "pip3",
            ]:
                try:
                    version = subprocess.check_output([software, "--version"])
                    f.write(f"{software.capitalize()}: {version.decode().strip()}\n")
                except Exception as e:
                    f.write(f"Error getting version for {software}: {str(e)}\n")

        # Generate filename with timestamp
        timestamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        zipfilename = f"/tmp/support_{timestamp}.zip"

        # Create ZipFile object
        with ZipFile(zipfilename, "w") as zip:
            # Add files in the current directory to the zip file
            print("Collecting details about current working directory.")
            for file in os.listdir():
                if os.path.isfile(file) and file != zipfilename:
                    zip.write(file)
            # Add environment variables and software versions files to the zip
            zip.write(os.path.join(tempdir, "env.txt"), "env.txt")
            zip.write(os.path.join(tempdir, "versions.txt"), "versions.txt")

        print(f"Support file created at {zipfilename}")
