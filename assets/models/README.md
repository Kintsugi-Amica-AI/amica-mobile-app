# On-device detector models

The Scan before you ride vehicle check uses these models. All of them run on the phone with `tflite_flutter`, and photos never leave the device.

**All three models are bundled, and both features are on** in `lib/core/constants/feature_flags.dart`. They were trained on Kaggle with `amica-ai-core/notebooks/train_plate_detector.ipynb`. Test-set results:

* `plate_detector`: precision 0.976, recall 0.959, mAP50 0.985 (43 test images).
* `vehicle_detector_lk`: mAP50 0.967 overall, 0.979 for three-wheelers (450 test images).
* `vehicle_detector`: the stock COCO YOLOv8n, not retrained.

| Files | Used by | Feature flag |
|---|---|---|
| `plate_detector.tflite` + `.txt` | AI plate finder | `FeatureFlags.plateFinder` |
| `vehicle_detector.tflite` + `.txt` | Vehicle type check (COCO: car, motorcycle, bus, truck) | `FeatureFlags.vehicleCheck` |
| `vehicle_detector_lk.tflite` + `.txt` (optional) | Sri Lanka types, including `three_wheeler`. Used in place of the COCO model when present | `FeatureFlags.vehicleCheck` |

## Turning the features on

1. Run `amica-ai-core/notebooks/train_plate_detector.ipynb` on Kaggle (GPU T4 x2, Internet on). It trains and exports the models and gives you a zip of them.
2. Copy the `.tflite` and `.txt` files into this folder.
3. Set the flag to `true`:
   * `plateFinder` once `plate_detector` is here.
   * `vehicleCheck` once `vehicle_detector` is here and the backend is deployed (`firebase deploy --only firestore:rules,functions`).
4. Rebuild the app.

If a flag is on but its model is missing, the app still falls back safely: no plate finder means the scan-frame crop is used, and no vehicle model means the result says "not sure".

## Model format

Ultralytics YOLO (v8/v11), exported to ONNX and then converted with `onnx2tf`. The notebook and `amica-ai-core/plate_ocr/training/export_tflite.py` do this for you.

* Input: `[1, S, S, 3]`, float32 RGB in the range 0–1.
* Output: `[1, 4 + classes, anchors]`.
* Labels: a `.txt` file with one class name per line, in class-index order.

## Licence

Ultralytics YOLOv8 is AGPL-3.0. That's fine for a university project. A public release would need an Ultralytics Enterprise licence or a detector under a permissive licence, such as an EfficientDet-Lite model from MediaPipe Model Maker (Apache-2.0).

The Roboflow "Srilankan Number Plates" dataset is CC BY 4.0, so credit it in the app and in the report.
