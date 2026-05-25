# Sen FSL — TFLite Conversion Package

**Filipino Sign Language Recognition • TensorFlow Lite • Production-Ready**

---

## 📁 Folder Structure

```
senyas_tflite_output/
├── model.tflite                  ← PRIMARY MODEL (use this)
├── model_float32.tflite          ← Float32 baseline (highest accuracy)
├── model_float16.tflite          ← Float16 quantized (½ size)
├── model_dynamic_range.tflite    ← Dynamic range (⅓ size, for storage-limited devices)
├── labels.txt                    ← 15 FSL sign labels
└── scripts/
    ├── convert_to_tflite.py      ← Full conversion pipeline
    ├── inference_example.py      ← How to run predictions
    ├── webcam_test.py            ← Real-time webcam demo
    └── validate_model.py         ← Model validation suite
```

---

## 🧠 Model Architecture

| Layer    | Type     | Output Shape  | Parameters |
|----------|----------|---------------|------------|
| Input    | —        | (1, 30, 258)  | —          |
| Conv1D   | 64 filters, kernel=3, ReLU | (1, 28, 64) | 49,600 |
| LSTM     | 64 units, return_seq=True  | (1, 28, 64) | 33,024 |
| LSTM     | 128 units, return_seq=True | (1, 28, 128)| 98,816 |
| LSTM     | 64 units, return_seq=False | (1, 64)     | 49,408 |
| Dense    | 64 units, ReLU             | (1, 64)     | 4,160  |
| Dense    | 32 units, ReLU             | (1, 32)     | 2,080  |
| Dense    | 15 units, Softmax          | (1, 15)     | 495    |

**Total parameters:** 237,583 (~928 KB weights)

**Input:** 30 consecutive frames × 258-dimensional MediaPipe landmark vector  
- Pose: 33 landmarks × 4 values (x, y, z, visibility) = 132  
- Left hand: 21 landmarks × 3 values (x, y, z) = 63  
- Right hand: 21 landmarks × 3 values (x, y, z) = 63  
- **Total: 258 per frame**

---

## 🏷️ Supported Signs (15 Classes)

| Index | Sign             | Meaning (Filipino) |
|-------|------------------|--------------------|
| 0     | ako              | I / me             |
| 1     | bakit            | Why                |
| 2     | F                | Letter F           |
| 3     | hi               | Hello              |
| 4     | hindi            | No                 |
| 5     | ikaw             | You                |
| 6     | kamusta          | How are you        |
| 7     | L                | Letter L           |
| 8     | maganda          | Beautiful          |
| 9     | magandang umaga  | Good morning       |
| 10    | N                | Letter N           |
| 11    | O                | Letter O           |
| 12    | oo               | Yes                |
| 13    | P                | Letter P           |
| 14    | salamat          | Thank you          |

---

## 📊 Model Comparison

| Model                      | Size    | Accuracy | Recommended For              |
|----------------------------|---------|----------|------------------------------|
| `model.tflite` (Float32)   | 975 KB  | Baseline | **All platforms** ← USE THIS |
| `model_float16.tflite`     | 503 KB  | ~same*   | Storage-constrained Android  |
| `model_dynamic_range.tflite`| 310 KB | slightly lower | Extreme storage limits |
| Original NF1.h5 (Keras)    | 2.8 MB  | Baseline | Training only                |

> **Note on Float16:** TFLite's CPU delegate dequantizes float16 weights back to float32
> at inference time, so there is **no speed advantage** on CPU-only devices. The float32 
> model is recommended because LSTM networks are sensitive to numeric precision, and the
> 975 KB size is already 65% smaller than the original H5.
> Float16 is beneficial on GPU delegates (Android NNAPI, iOS Core ML) where native f16 math applies.

---

## ⚡ Inference Speed

Measured on CPU (no GPU), 100 runs:

| Metric       | Float32 | Float16 | Dynamic Range |
|--------------|---------|---------|---------------|
| Avg latency  | ~1.1 ms | ~1.1 ms | ~0.9 ms       |
| P95 latency  | ~1.2 ms | ~1.2 ms | ~1.0 ms       |

> Real-time threshold = 33ms (30 FPS). All variants are **30× faster** than needed.

---

## 🚀 Quick Start

### 1. Install dependencies

```bash
pip install tensorflow mediapipe opencv-python numpy
```

### 2. Run inference from your own code

```python
import numpy as np
import tensorflow as tf

# Load model
interpreter = tf.lite.Interpreter(model_path="model.tflite")
interpreter.allocate_tensors()
in_d  = interpreter.get_input_details()
out_d = interpreter.get_output_details()

# Labels
actions = open("labels.txt").read().strip().split('\n')

# Your 30-frame sequence of MediaPipe landmarks → shape (30, 258)
sequence = np.zeros((30, 258), dtype=np.float32)  # replace with real data

# Predict
interpreter.set_tensor(in_d[0]['index'], sequence[np.newaxis])
interpreter.invoke()
probs  = interpreter.get_tensor(out_d[0]['index'])[0]
label  = actions[np.argmax(probs)]
conf   = probs.max()
print(f"Sign: {label} ({conf:.1%})")
```

### 3. Live webcam demo

```bash
python scripts/webcam_test.py
```

### 4. Run validation

```bash
cd scripts
python validate_model.py
```

---

## 🤖 Android Integration

### Step 1 — Add to your Android project

```
app/src/main/assets/
├── model.tflite
└── labels.txt
```

### Step 2 — Gradle dependency

```groovy
dependencies {
    implementation 'org.tensorflow:tensorflow-lite:2.14.0'
    implementation 'org.tensorflow:tensorflow-lite-support:0.4.4'
}
```

### Step 3 — Java/Kotlin inference

```kotlin
// Load model
val model = Interpreter(loadModelFile(assets, "model.tflite"))

// Input: FloatArray of shape [1][30][258]
val input = Array(1) { Array(30) { FloatArray(258) } }
// ... fill input with MediaPipe landmarks ...

// Output: FloatArray of shape [1][15]
val output = Array(1) { FloatArray(15) }
model.run(input, output)

val labelIdx = output[0].indices.maxByOrNull { output[0][it] }!!
val label    = labels[labelIdx]
```

---

## 🔁 Re-running the Conversion

If you retrain the model and get a new `.h5` file:

```bash
cd scripts

# Edit convert_to_tflite.py: update H5_WEIGHTS_PATH
python convert_to_tflite.py
```

The script will produce all 3 TFLite variants and `labels.txt` automatically.

---

## 🔬 Conversion Method

This project uses the **concrete function** approach instead of SavedModel export due
to a known Keras 3.x + TF 2.19 incompatibility with LSTM layers and `_DictWrapper`:

```python
@tf.function(input_signature=[
    tf.TensorSpec(shape=[1, 30, 258], dtype=tf.float32)
])
def run_model(x):
    return model(x, training=False)

concrete_func = run_model.get_concrete_function()
converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_func], model)
```

This bypasses the SavedModel checkpoint traversal bug while preserving full accuracy.

---

## 📋 TF Version Compatibility

| Component          | Version Used |
|--------------------|--------------|
| TensorFlow         | 2.19.0       |
| Keras              | 3.x          |
| Python             | 3.12         |
| TFLite format      | Schema v3    |
| Minimum Android TF | 2.8.0+       |

---

## ⚠️ Known Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| `_DictWrapper` TypeError on export | Keras 3 + TF 2.19 LSTM bug | Use `from_concrete_functions()` ✅ |
| `tensorflowjs` import error | protobuf version conflict | Load H5 directly in Keras ✅ |
| Low float16 match rate on random noise | LSTM state accumulation sensitivity | Use float32 model (recommended) ✅ |
| CUDA warnings at startup | No GPU, CPU-only mode | Safe to ignore ✅ |

---

*Generated for Senyas: Filipino Sign Language Translator (CC-BY-NC 4.0)*
