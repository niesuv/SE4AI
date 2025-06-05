import os
import onnxruntime as ort
from fastapi import FastAPI, File, UploadFile, HTTPException, Form, Request
from fastapi.responses import JSONResponse
import uvicorn
from typing import Dict, Any
import google.generativeai as genai

# Import utility functions for inference
from utils.inference_utils import preprocess_image_from_bytes, handle_model_output

# --- Application Setup ---
app = FastAPI(
    title="Plant Disease Diagnosis API",
    description="API to predict plant diseases from images using an ONNX model.",
    version="1.0.0"
)

# --- Global Variables ---
ONNX_MODEL_PATH = os.environ.get("MODEL_PATH", "cnn_model.onnx")
genai.configure(api_key=os.environ["GOOGLE_API_KEY"])
session = None
input_name = None
output_name = None


# --- Event Handlers ---
@app.on_event("startup")
async def load_model():
    """Load the ONNX model when the application starts."""
    global session, input_name, output_name
    try:
        # Check if model file exists
        if not os.path.exists(ONNX_MODEL_PATH):
            raise FileNotFoundError(f"ONNX model file not found at: {ONNX_MODEL_PATH}")

        # Load the ONNX inference session
        # Consider adding more providers if targeting specific hardware (e.g., 'CUDAExecutionProvider')
        session = ort.InferenceSession(ONNX_MODEL_PATH, providers=['CPUExecutionProvider'])
        input_name = session.get_inputs()[0].name
        output_name = session.get_outputs()[0].name
        print(f"ONNX model loaded successfully from: {ONNX_MODEL_PATH}")
        print(f"Input Name: {input_name}, Output Name: {output_name}")
    except FileNotFoundError as e:
        print(f"Error: {e}")
        # Decide how to handle this - exit, or let requests fail?
        # For Cloud Run, letting requests fail might be okay as it shows an unhealthy state.
        session = None  # Ensure session is None if loading fails
    except Exception as e:
        print(f"Critical Error loading ONNX model: {e}")
        session = None  # Ensure session is None if loading fails
        # Optionally raise an exception here to prevent the app from starting fully
        # raise RuntimeError(f"Failed to load ONNX model: {e}") from e


@app.on_event("shutdown")
async def cleanup():
    """Perform cleanup tasks on shutdown (if any)."""
    global session
    if session:
        del session
        print("ONNX session closed.")


# --- API Endpoints ---
@app.get("/")
async def read_root():
    """Root endpoint providing basic API information."""
    return {"message": "Welcome to the Plant Disease Diagnosis API. Use the /predict/ endpoint for inference."}


@app.post("/predict/", response_model=Dict[str, Any])  # Added response_model for documentation
async def predict_disease(
        request: Request,  # Inject request for logging client info
        fruit: str = Form(...),
        file: UploadFile = File(...)
):
    """
    Receives a plant image and fruit type, returns disease prediction.

    - **fruit**: The type of plant/fruit (e.g., "Apple", "Tomato"). Must match keys in mapping files.
    - **file**: The image file to be diagnosed.
    """
    client_host = request.client.host if request.client else "unknown"
    print(f"Received prediction request from {client_host} for fruit: {fruit}")

    if not session:
        print("Error: Model not loaded.")
        raise HTTPException(status_code=503,
                            detail="Model is not available. Service might be starting or encountered an error.")

    # Validate file type
    if not file.content_type or not file.content_type.startswith("image/"):
        print(f"Invalid file type received: {file.content_type}")
        raise HTTPException(status_code=400,
                            detail=f"Invalid file type. Please upload an image (received: {file.content_type}).")

    try:
        # 1. Read image bytes
        image_bytes = await file.read()
        if not image_bytes:
            raise ValueError("Received empty image file.")
        print(f"Read {len(image_bytes)} bytes from uploaded file: {file.filename}")

        gemini_model = genai.GenerativeModel(model_name="gemini-2.5-pro-preview-05-06")  # hoặc gemini-2.0-pro
        gemini_response = gemini_model.generate_content([
            {"mime_type": file.content_type, "data": image_bytes},
            "Is there any leaf or fruit in this image? If so, is it the main factor? Just answer \"yes\" or \"no\"."
        ])
        result = {"predicted_disease": ["no"],
                  "probabilities": {}
                  }

        check_fruit = gemini_response.text.strip()
        print(f"Gemini caption: {check_fruit}")
        if not check_fruit.__contains__('no'):
            # 2. Preprocess the image
            input_tensor = preprocess_image_from_bytes(image_bytes)
            print(f"Image preprocessed into tensor shape: {input_tensor.shape}, dtype: {input_tensor.dtype}")

            # 3. Run inference
            print("Running ONNX model inference...")
            outputs = session.run([output_name], {input_name: input_tensor})
            prediction_tensor = outputs[0]  # Get the raw model output
            print(f"Inference complete. Output tensor shape: {prediction_tensor.shape}")

            # 4. Postprocess the output
            result = handle_model_output(prediction_tensor, fruit_key=fruit)
            print(f"Prediction result for {fruit}: {result['predicted_disease']}")

        # 5. Return the result as JSON
        return JSONResponse(content=result)

    except FileNotFoundError as e:  # Should be caught during startup, but as a safeguard
        print(f"Error during prediction - Model file missing: {e}")
        raise HTTPException(status_code=500, detail="Internal server error: Model file not found.")
    except KeyError as e:  # Raised by handle_model_output if fruit key is invalid
        print(f"Invalid fruit key provided: {e}")
        raise HTTPException(status_code=400, detail=str(e))  # Return the KeyError message
    except ValueError as e:  # Raised by preprocessing or output handling on bad data/mismatch
        print(f"Data processing error: {e}")
        raise HTTPException(status_code=400, detail=f"Error processing data: {e}")
    except ort.ONNXRuntimeException as e:
        print(f"ONNX Runtime error during inference: {e}")
        raise HTTPException(status_code=500, detail=f"Model inference failed: {e}")
    except Exception as e:
        # Catch-all for other unexpected errors
        print(f"Unexpected error during prediction: {e}")
        # Log the full traceback here in a real application for debugging
        # import traceback
        # traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {e}")


# --- Run Locally (for testing) ---
if __name__ == "__main__":
    # Run on port 8080, standard for Cloud Run and other PaaS
    print("Starting Uvicorn server for local testing...")
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)  # Added reload=True for easier local dev
