import os
import shutil
import subprocess
# ROOT =the absolute path to your IbrahimTahir/ folder computed dynamically
ROOT = os.path.dirname(os.path.abspath(__file__)) #__file__ - the path to the currently-running script itself (build.py)
BUILD_DIR = os.path.join(ROOT, "backend", "_build")
ZIP_PATH = os.path.join(ROOT, "backend", "lambda.zip")
REQUIREMENTS = os.path.join(ROOT, "backend", "requirements.txt")
HANDLER = os.path.join(ROOT, "backend", "lambda_function.py")


def main():
    # if a _build/ folder exists from previous run
    if os.path.exists(BUILD_DIR):
        # delete it entirely (recursive del)
        shutil.rmtree(BUILD_DIR)
    os.makedirs(BUILD_DIR)

    # runs pip install -r backend/requirements.txt -t backend/build -q
    subprocess.run(
        ["pip", "install", "-r", REQUIREMENTS, "-t", BUILD_DIR, "-q"],
        # raise an error if command fails
        check=True,
    )

    #copies lambda_function.py itself into _build/
    shutil.copy(HANDLER, BUILD_DIR)

    # delete old lambda.zip first
    if os.path.exists(ZIP_PATH):
        os.remove(ZIP_PATH)
    shutil.make_archive(ZIP_PATH[: -len(".zip")], "zip", BUILD_DIR)

    print(f"Built {ZIP_PATH}")


if __name__ == "__main__":
    main()
