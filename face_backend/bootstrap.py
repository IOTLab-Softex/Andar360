import os
import pathlib
import shutil
import subprocess
import urllib.request
import venv


ROOT = pathlib.Path(__file__).resolve().parents[1]
VENV_DIR = ROOT / ".face_backend_venv"
if os.name == "nt":
    PYTHON_EXE = VENV_DIR / "Scripts" / "python.exe"
else:
    PYTHON_EXE = VENV_DIR / "bin" / "python"
MODELS_DIR = ROOT / "face_backend" / "models"
REQUIREMENTS = ROOT / "face_backend" / "requirements.txt"

MODEL_URLS = {
    "face_detection_yunet_2023mar.onnx": "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx",
    "face_recognition_sface_2021dec.onnx": "https://github.com/opencv/opencv_zoo/raw/main/models/face_recognition_sface/face_recognition_sface_2021dec.onnx",
}


def packages_ok():
    if not PYTHON_EXE.exists():
        return False
    try:
        subprocess.run(
            [str(PYTHON_EXE), "-c", "import numpy, cv2, flask, requests, waitress"],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        return True
    except subprocess.CalledProcessError:
        return False


def ensure_venv():
    if VENV_DIR.exists() and not packages_ok():
        print("[bootstrap] Venv inválido ou incompleto — recriando...")
        shutil.rmtree(VENV_DIR)

    if not PYTHON_EXE.exists():
        builder = venv.EnvBuilder(with_pip=True)
        builder.create(VENV_DIR)


def run(*command):
    subprocess.run(command, check=True)


def ensure_packages():
    run(str(PYTHON_EXE), "-m", "pip", "install", "--upgrade", "pip")
    run(str(PYTHON_EXE), "-m", "pip", "install", "--prefer-binary", "-r", str(REQUIREMENTS))


def ensure_models():
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    for filename, url in MODEL_URLS.items():
        target = MODELS_DIR / filename
        if target.exists():
            continue
        urllib.request.urlretrieve(url, target)


if __name__ == "__main__":
    ensure_venv()
    ensure_packages()
    ensure_models()
