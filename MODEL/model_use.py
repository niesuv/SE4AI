import onnxruntime as ort

from utils import resize_img, handle_output

# onnx_model = onnx.load("cnn_model.onnx")
# onnx.checker.check_model(onnx_model)
# print("ONNX model is valid ✅")

# Load the ONNX model
session = ort.InferenceSession("cnn_model.onnx")

# Check input and output names
input_name = session.get_inputs()[0].name  # usually 'input'
output_name = session.get_outputs()[0].name  # usually 'output'

# Example input: shape should match what your model expects (e.g. 1x3x256x256)
img_path = "img_1.png"
fruit = None
input_img = resize_img(img_path)
outputs = session.run([output_name], {input_name: input_img})
prediction = outputs[0]

diease = handle_output(prediction, fruit)
print(diease)

