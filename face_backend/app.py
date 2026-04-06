import base64
import os

import cv2
import numpy as np
from flask import Flask, jsonify, request
from waitress import serve


ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(ROOT_DIR, "models")
DETECTOR_MODEL = os.path.join(MODELS_DIR, "face_detection_yunet_2023mar.onnx")
RECOGNIZER_MODEL = os.path.join(MODELS_DIR, "face_recognition_sface_2021dec.onnx")

app = Flask(__name__)


class FaceEngine:
    def __init__(self):
        self.detector = cv2.FaceDetectorYN.create(DETECTOR_MODEL, "", (320, 320), score_threshold=0.6, nms_threshold=0.3, top_k=5000)
        self.recognizer = cv2.FaceRecognizerSF.create(RECOGNIZER_MODEL, "")

    def decode_image(self, image_base64):
        payload = image_base64.split(",", 1)[1] if "," in image_base64 else image_base64
        image_bytes = base64.b64decode(payload)
        image_array = np.frombuffer(image_bytes, dtype=np.uint8)
        image = cv2.imdecode(image_array, cv2.IMREAD_COLOR)
        if image is None:
            raise ValueError("Imagem invalida.")
        return image

    def detect_largest_face(self, image):
        height, width = image.shape[:2]
        attempts = [image]

        # Retry with gentle upscaling for narrow/low-resolution profile photos.
        if min(width, height) < 320:
            attempts.append(cv2.resize(image, None, fx=2.0, fy=2.0, interpolation=cv2.INTER_CUBIC))

        for candidate in attempts:
            candidate_height, candidate_width = candidate.shape[:2]
            self.detector.setInputSize((candidate_width, candidate_height))
            _, faces = self.detector.detect(candidate)
            if faces is None or len(faces) == 0:
                continue

            largest = max(faces, key=lambda face: face[2] * face[3]).copy()
            if candidate is not image:
                scale_x = width / candidate_width
                scale_y = height / candidate_height
                largest[0] *= scale_x
                largest[1] *= scale_y
                largest[2] *= scale_x
                largest[3] *= scale_y
                for i in range(4, 14, 2):
                    largest[i] *= scale_x
                    largest[i + 1] *= scale_y
            return largest

        return None

    def face_box_to_dict(self, face):
        if face is None:
            return None
        return {
            "x": round(float(face[0]), 2),
            "y": round(float(face[1]), 2),
            "width": round(float(face[2]), 2),
            "height": round(float(face[3]), 2),
        }

    def extract_feature(self, image_base64):
        image = self.decode_image(image_base64)
        image_height, image_width = image.shape[:2]
        face = self.detect_largest_face(image)
        if face is None:
            return None, "Nenhum rosto detectado na imagem.", {
                "image": {"width": int(image_width), "height": int(image_height)},
                "face": None,
            }
        aligned_face = self.recognizer.alignCrop(image, face)
        feature = self.recognizer.feature(aligned_face)
        return feature, None, {
            "image": {"width": int(image_width), "height": int(image_height)},
            "face": self.face_box_to_dict(face),
        }

    def compare(self, reference_image_base64, probe_image_base64):
        reference_feature, reference_error, reference_info = self.extract_feature(reference_image_base64)
        if reference_error:
            return {
                "matched": False,
                "message": "Nao foi possivel localizar o rosto da foto cadastrada.",
                "confidence": 0.0,
                "score": 0.0,
                "distance": 0.0,
                "debug": {
                    "reference": reference_info,
                    "probe": None,
                },
            }

        probe_feature, probe_error, probe_info = self.extract_feature(probe_image_base64)
        if probe_error:
            return {
                "matched": False,
                "message": "Nao foi possivel localizar o rosto capturado. Ajuste a camera e tente novamente.",
                "confidence": 0.0,
                "score": 0.0,
                "distance": 0.0,
                "debug": {
                    "reference": reference_info,
                    "probe": probe_info,
                },
            }

        cosine_score = float(self.recognizer.match(reference_feature, probe_feature, cv2.FaceRecognizerSF_FR_COSINE))
        l2_distance = float(self.recognizer.match(reference_feature, probe_feature, cv2.FaceRecognizerSF_FR_NORM_L2))
        matched = cosine_score >= 0.42 and l2_distance <= 1.10

        confidence = max(0.0, min(1.0, (cosine_score - 0.28) / 0.40))
        return {
            "matched": matched,
            "message": "Rosto validado com sucesso." if matched else "Rosto nao validado com seguranca suficiente.",
            "confidence": round(confidence, 4),
            "score": round(cosine_score, 4),
            "distance": round(l2_distance, 4),
            "debug": {
                "reference": reference_info,
                "probe": probe_info,
            },
        }


engine = FaceEngine()


@app.get("/health")
def health():
    return jsonify({"ok": True})


@app.post("/verify")
def verify():
    payload = request.get_json(silent=True) or {}
    reference_image_base64 = payload.get("reference_image_base64", "")
    probe_image_base64 = payload.get("probe_image_base64", "")

    if not reference_image_base64 or not probe_image_base64:
        return jsonify({"message": "As imagens de referencia e captura sao obrigatorias."}), 422

    try:
        result = engine.compare(reference_image_base64, probe_image_base64)
        status = 200 if result["matched"] else 422
        return jsonify(result), status
    except Exception as error:
        return jsonify({"message": f"Falha ao processar reconhecimento facial: {error}"}), 500


if __name__ == "__main__":
    host = os.environ.get("FACE_BACKEND_HOST", "127.0.0.1")
    port = int(os.environ.get("FACE_BACKEND_PORT", "5127"))
    serve(app, host=host, port=port, threads=4)
