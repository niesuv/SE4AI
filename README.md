# Plant Disease Diagnosis API

[Tiếng Việt](README.vi.md)

## Overview

This project provides a RESTful API service for diagnosing plant diseases from images. It utilizes a pre-trained ONNX model and is built using Python with the FastAPI framework. The service is designed to be containerized using Docker and deployed on cloud platforms like Google Cloud Run.

A mobile application can send image data (as multipart/form-data) along with the fruit/plant type to the `/predict/` endpoint, and the API will return the predicted disease and associated probabilities in JSON format.

## Technology Stack

*   **Python 3.9+**
*   **FastAPI:** High-performance web framework for building APIs.
*   **Uvicorn:** ASGI server to run FastAPI.
*   **ONNX Runtime:** For loading and running the `.onnx` model inference.
*   **Pillow:** Image processing.
*   **Torch/Torchvision:** Primarily used for Softmax and image transforms (as defined in `utils.py`).
*   **Docker:** For containerization.
*   **Google Cloud Run (Recommended Deployment Target)**

## API Endpoints

*   **`GET /`**
    *   **Description:** Returns a welcome message indicating the API is running. Useful for health checks.
    *   **Response:** `{"message": "Welcome to the Plant Disease Diagnosis API..."}`

*   **`POST /predict/`**
    *   **Description:** Accepts an image file and the corresponding fruit type to predict the plant disease.
    *   **Request Body:** `multipart/form-data` containing:
        *   `fruit` (string, required): The type of plant/fruit (e.g., "Apple", "Tomato"). Must match keys in `mapping.json` / `index_mapping.json`.
        *   `file` (file, required): The image file for diagnosis.
    *   **Success Response (200 OK):** JSON object with prediction details.
        ```json
        {
          "predicted_disease": [
            "Apple___Black_rot",
            98.5
          ],
          "probabilities": {
            "Apple___Cedar_apple_rust": 0.5,
            "Apple___Apple_scab": 0.8,
            "Apple___Black_rot": 98.5,
            "Apple___healthy": 0.2
          }
        }
        ```
    *   **Error Responses:**
        *   `400 Bad Request`: Invalid input (e.g., non-image file, missing fields, invalid fruit key).
        *   `500 Internal Server Error`: Issues during model inference or unexpected server errors.
        *   `503 Service Unavailable`: Model failed to load during startup.

## Prerequisites for Deployment

*   **Docker:** Installed and running.
*   **Google Cloud SDK (`gcloud`):** Installed and configured (logged in, project set).
*   **Google Cloud Project:** With Cloud Build, Artifact Registry (or Container Registry), and Cloud Run APIs enabled.
    ```bash
    gcloud services enable cloudbuild.googleapis.com artifactregistry.googleapis.com run.googleapis.com
    ```
*   **ONNX Model File:** Your trained `cnn_model.onnx` (or the name specified by `MODEL_PATH`) placed in the project root.
*   **Mapping Files:** `mapping.json` and `index_mapping.json` placed in the project root.

## Deployment to Google Cloud Run

1.  **Clone the Repository (or ensure your code is ready):**
    Make sure you have `main.py`, `utils.py`, `Dockerfile`, `requirements.txt`, your `.onnx` model, and the `.json` mapping files in your project directory.

2.  **Build and Push Docker Image:**
    Use Google Cloud Build to build the Docker image and push it to Google Artifact Registry. Run this command from your project's root directory:
    ```bash
    # Replace YOUR_REGION, YOUR_PROJECT_ID, and optionally the repo/image names
    gcloud builds submit --tag YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/plant-api-repo/plant-disease-api:latest
    ```
    *(You might need to create an Artifact Registry repository named `plant-api-repo` first if it doesn't exist).*

3.  **Deploy to Cloud Run:**
    Deploy the container image as a Cloud Run service:
    ```bash
    # Replace YOUR_REGION, YOUR_PROJECT_ID, and image path if different
    gcloud run deploy plant-disease-api-service \
        --image YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/plant-api-repo/plant-disease-api:latest \
        --platform managed \
        --region YOUR_REGION \
        --port 8080 \
        --memory 1Gi \
        --cpu 1 \
        --allow-unauthenticated \
        # Add --update-env-vars MODEL_PATH=your_custom_model_name.onnx if not using default
        # Consider removing --allow-unauthenticated and setting up IAM or API Gateway for production
    ```
    *   Note the **Service URL** provided after successful deployment. This is your API base URL.
    *   Adjust `--memory` and `--cpu` based on your model's requirements.

## Usage Example (Using cURL)

Replace `YOUR_CLOUD_RUN_URL` with the actual URL from the deployment step, `/path/to/your/test_image.jpg` with a valid image path, and `"Apple"` with the correct fruit type.

```bash
curl -X POST YOUR_CLOUD_RUN_URL/predict/ \
     -F "fruit=Apple" \
     -F "file=@/path/to/your/test_image.jpg"
```

## Configuration

*   **Model Path:** The path to the ONNX model file is determined by the `MODEL_PATH` environment variable. It defaults to `cnn_model.onnx` if the environment variable is not set. You can override this during Cloud Run deployment using the `--update-env-vars` flag.
*   **Port:** The application runs on port `8080` inside the container, as defined in the `Dockerfile` and `CMD`. Cloud Run automatically maps external requests to this port.
