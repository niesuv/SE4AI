import io
import json
import numpy as np
import torch
import torch.nn as nn
import torchvision.transforms as transforms
from PIL import Image
from numpy import ndarray

# --- Load Mappings ---
try:
    with open("mapping/mapping.json", "r") as f:
        disease_mapping = json.load(f)
    with open("mapping/index_mapping.json", "r") as f:
        disease_index_mapping = json.load(f)
    all_labels = [label for sublist in disease_mapping.values() for label in sublist]
    print("Successfully loaded mapping files.")
except FileNotFoundError as e:
    print(f"Error loading mapping file: {e}. Ensure mapping.json and index_mapping.json are present.")
    # Depending on resilience needs, you might raise an exception or exit
    disease_mapping = {}
    disease_index_mapping = {}
    all_labels = []
except json.JSONDecodeError as e:
    print(f"Error decoding JSON from mapping file: {e}")
    disease_mapping = {}
    disease_index_mapping = {}
    all_labels = []


# --- Image Preprocessing ---
def preprocess_image_from_bytes(image_bytes: bytes, target_size: tuple = (256, 256)) -> np.ndarray:
    """
    Loads an image from bytes, preprocesses it for the ONNX model.

    Args:
        image_bytes: Raw bytes of the image file.
        target_size: The target size (height, width) for resizing.

    Returns:
        A numpy array representing the preprocessed image tensor
        with shape (1, 3, H, W) and dtype float32.
    """
    try:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

        # Define the same transformations used during training
        transform = transforms.Compose([
            transforms.Resize(target_size),
            transforms.ToTensor(),  # Converts to [0, 1] range and CxHxW format
            # Add normalization if your model requires it, e.g.:
            # transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])

        # Apply transform, add batch dimension, convert to numpy float32
        # Model expects input shape like (batch_size, channels, height, width)
        tensor = transform(image).unsqueeze(0).numpy().astype(np.float32)
        return tensor
    except Exception as e:
        print(f"Error preprocessing image: {e}")
        raise ValueError(f"Could not preprocess image: {e}") from e


# --- Output Handling ---
def handle_model_output(prediction_tensor: ndarray, fruit_key: str) -> dict:
    """
    Processes the raw output tensor from the ONNX model to get disease names and probabilities.

    Args:
        prediction_tensor: The raw output numpy array from the model.
        fruit_key: The key identifying the fruit type (e.g., "Apple", "Tomato")
                   used to select relevant output indices and labels.

    Returns:
        A dictionary containing the predicted disease and probabilities for the specific fruit.
        Example:
        {
            'predicted_disease': ('Apple___Black_rot', 98.5),
            'probabilities': {'Apple___Cedar_apple_rust': 0.5, ...}
        }
    Raises:
        KeyError: If the fruit_key is not found in the mapping files.
        ValueError: If prediction tensor is invalid.
    """
    if prediction_tensor is None or prediction_tensor.size == 0:
        raise ValueError("Invalid prediction tensor received.")
    if not fruit_key or fruit_key not in disease_index_mapping or fruit_key not in disease_mapping:
        raise KeyError(f"Fruit key '{fruit_key}' not found in mappings. Available keys: {list(disease_index_mapping.keys())}")

    try:
        # Select the relevant output indices for the given fruit
        relevant_indices = disease_index_mapping[fruit_key]
        fruit_specific_predictions = prediction_tensor[:, relevant_indices]

        # Get the corresponding disease names for this fruit
        fruit_specific_labels = disease_mapping[fruit_key]

        # Apply Softmax to get probabilities
        # Convert numpy array to torch tensor for Softmax calculation
        softmax_probs = nn.Softmax(dim=-1)(torch.tensor(fruit_specific_predictions))

        # Find the disease with the highest probability
        max_prob, predicted_index = torch.max(softmax_probs, dim=-1)
        predicted_disease_name = fruit_specific_labels[predicted_index.item()]
        predicted_probability_percent = (max_prob.item() * 100)

        # Create a dictionary of all probabilities for this fruit type
        probabilities_percent = {
            label: prob.item() * 100
            for label, prob in zip(fruit_specific_labels, softmax_probs[0]) # Use softmax_probs[0] as batch size is 1
        }

        # Format the final output dictionary
        result = {
            'predicted_disease': (predicted_disease_name, round(predicted_probability_percent, 2)),
            'probabilities': {k: round(v, 2) for k, v in probabilities_percent.items()}
        }
        return result

    except IndexError as e:
         print(f"Index error during output handling for fruit '{fruit_key}'. Check mapping files against model output shape. Indices: {relevant_indices}, Pred shape: {prediction_tensor.shape}. Error: {e}")
         raise ValueError(f"Mapping/Index mismatch for fruit '{fruit_key}'.") from e
    except Exception as e:
        print(f"Error handling model output: {e}")
        raise ValueError(f"Could not handle model output: {e}") from e