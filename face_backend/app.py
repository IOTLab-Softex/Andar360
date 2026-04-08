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

        # Retry with upscaling when face is small or profile photo is distant.
        if min(width, height) < 900:
            attempts.append(cv2.resize(image, None, fx=1.5, fy=1.5, interpolation=cv2.INTER_CUBIC))
        if min(width, height) < 420:
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
        return self.extract_feature_from_image(image)

    def extract_feature_from_image(self, image):
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

        probe_image = self.decode_image(probe_image_base64)
        probe_feature, probe_error, probe_info = self.extract_feature_from_image(probe_image)
        probe_feature_flipped = None
        probe_error_flipped = None
        probe_info_flipped = None

        try:
            flipped_image = cv2.flip(probe_image, 1)
            probe_feature_flipped, probe_error_flipped, probe_info_flipped = self.extract_feature_from_image(flipped_image)
        except Exception:
            probe_feature_flipped = None

        if probe_error and probe_feature_flipped is None:
            return {
                "matched": False,
                "message": "Nao foi possivel localizar o rosto capturado. Ajuste a camera e tente novamente.",
                "confidence": 0.0,
                "score": 0.0,
                "distance": 0.0,
                "debug": {
                    "reference": reference_info,
                    "probe": probe_info,
                    "probe_flipped": probe_info_flipped,
                },
            }

        candidates = []
        if probe_feature is not None:
            cosine_score = float(self.recognizer.match(reference_feature, probe_feature, cv2.FaceRecognizerSF_FR_COSINE))
            l2_distance = float(self.recognizer.match(reference_feature, probe_feature, cv2.FaceRecognizerSF_FR_NORM_L2))
            candidates.append(("probe", cosine_score, l2_distance, probe_info))
        if probe_feature_flipped is not None:
            cosine_score_flipped = float(self.recognizer.match(reference_feature, probe_feature_flipped, cv2.FaceRecognizerSF_FR_COSINE))
            l2_distance_flipped = float(self.recognizer.match(reference_feature, probe_feature_flipped, cv2.FaceRecognizerSF_FR_NORM_L2))
            candidates.append(("probe_flipped", cosine_score_flipped, l2_distance_flipped, probe_info_flipped))

        best_variant, cosine_score, l2_distance, _best_probe_info = max(candidates, key=lambda item: (item[1], -item[2]))
        matched = cosine_score >= 0.39 and l2_distance <= 1.18

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
                "probe_flipped": probe_info_flipped,
                "best_variant": best_variant,
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
