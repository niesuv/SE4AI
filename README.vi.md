# API Chẩn đoán Bệnh cây trồng

[English](README.md)

## Tổng quan

Dự án này cung cấp một dịch vụ API RESTful để chẩn đoán bệnh cây trồng từ hình ảnh. API sử dụng một mô hình ONNX đã được huấn luyện trước và được xây dựng bằng Python với framework FastAPI. Dịch vụ được thiết kế để đóng gói bằng Docker và triển khai trên các nền tảng đám mây như Google Cloud Run.

Một ứng dụng di động có thể gửi dữ liệu hình ảnh (dưới dạng multipart/form-data) cùng với loại cây/trái cây đến điểm cuối `/predict/`, và API sẽ trả về bệnh được dự đoán cùng với các xác suất liên quan dưới định dạng JSON.

## Công nghệ sử dụng

*   **Python 3.9+**
*   **FastAPI:** Web framework hiệu năng cao để xây dựng API.
*   **Uvicorn:** Máy chủ ASGI để chạy FastAPI.
*   **ONNX Runtime:** Để tải và chạy suy luận mô hình `.onnx`.
*   **Pillow:** Xử lý hình ảnh.
*   **Torch/Torchvision:** Chủ yếu được sử dụng cho Softmax và biến đổi hình ảnh (như định nghĩa trong `utils.py`).
*   **Docker:** Để đóng gói ứng dụng (containerization).
*   **Google Cloud Run (Nền tảng triển khai được khuyến nghị)**

## Các Điểm cuối API (Endpoints)

*   **`GET /`**
    *   **Mô tả:** Trả về một thông báo chào mừng cho biết API đang hoạt động. Hữu ích cho việc kiểm tra tình trạng (health check).
    *   **Phản hồi:** `{"message": "Welcome to the Plant Disease Diagnosis API..."}`

*   **`POST /predict/`**
    *   **Mô tả:** Nhận một tệp hình ảnh và loại trái cây tương ứng để dự đoán bệnh cây trồng.
    *   **Nội dung Request:** `multipart/form-data` chứa:
        *   `fruit` (chuỗi, bắt buộc): Loại cây/trái cây (ví dụ: "Apple", "Tomato"). Phải khớp với các khóa trong `mapping.json` / `index_mapping.json`.
        *   `file` (tệp, bắt buộc): Tệp hình ảnh cần chẩn đoán.
    *   **Phản hồi Thành công (200 OK):** Đối tượng JSON chứa chi tiết dự đoán.
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
    *   **Phản hồi Lỗi:**
        *   `400 Bad Request`: Đầu vào không hợp lệ (ví dụ: tệp không phải hình ảnh, thiếu trường, khóa `fruit` không hợp lệ).
        *   `500 Internal Server Error`: Sự cố trong quá trình suy luận mô hình hoặc lỗi máy chủ không mong muốn.
        *   `503 Service Unavailable`: Không thể tải mô hình khi khởi động.

## Yêu cầu Tiên quyết để Triển khai

*   **Docker:** Đã được cài đặt và đang chạy.
*   **Google Cloud SDK (`gcloud`):** Đã được cài đặt và cấu hình (đã đăng nhập, đã chọn dự án).
*   **Dự án Google Cloud:** Đã bật các API Cloud Build, Artifact Registry (hoặc Container Registry), và Cloud Run.
    ```bash
    gcloud services enable cloudbuild.googleapis.com artifactregistry.googleapis.com run.googleapis.com
    ```
*   **Tệp Model ONNX:** Tệp `cnn_model.onnx` đã huấn luyện của bạn (hoặc tên được chỉ định bởi `MODEL_PATH`) được đặt trong thư mục gốc của dự án.
*   **Tệp Mapping:** `mapping.json` và `index_mapping.json` được đặt trong thư mục gốc của dự án.

## Triển khai lên Google Cloud Run

1.  **Sao chép Repository (hoặc đảm bảo code của bạn đã sẵn sàng):**
    Đảm bảo bạn có các tệp `main.py`, `utils.py`, `Dockerfile`, `requirements.txt`, mô hình `.onnx` và các tệp mapping `.json` trong thư mục dự án của bạn.

2.  **Build và Đẩy Docker Image:**
    Sử dụng Google Cloud Build để build Docker image và đẩy nó lên Google Artifact Registry. Chạy lệnh này từ thư mục gốc của dự án:
    ```bash
    # Thay thế YOUR_REGION, YOUR_PROJECT_ID, và tùy chọn tên repo/image
    gcloud builds submit --tag YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/plant-api-repo/plant-disease-api:latest
    ```
    *(Bạn có thể cần tạo một Artifact Registry repository tên là `plant-api-repo` trước nếu nó chưa tồn tại).*

3.  **Triển khai lên Cloud Run:**
    Triển khai container image dưới dạng một dịch vụ Cloud Run:
    ```bash
    # Thay thế YOUR_REGION, YOUR_PROJECT_ID, và đường dẫn image nếu khác
    gcloud run deploy plant-disease-api-service \
        --image YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/plant-api-repo/plant-disease-api:latest \
        --platform managed \
        --region YOUR_REGION \
        --port 8080 \
        --memory 1Gi \
        --cpu 1 \
        --allow-unauthenticated \
        # Thêm --update-env-vars MODEL_PATH=your_custom_model_name.onnx nếu không dùng tên mặc định
        # Cân nhắc bỏ --allow-unauthenticated và thiết lập IAM hoặc API Gateway cho môi trường production
    ```
    *   Ghi lại **URL Dịch vụ (Service URL)** được cung cấp sau khi triển khai thành công. Đây là URL cơ sở API của bạn.
    *   Điều chỉnh `--memory` và `--cpu` dựa trên yêu cầu của mô hình của bạn.

## Ví dụ Sử dụng (Dùng cURL)

Thay thế `YOUR_CLOUD_RUN_URL` bằng URL thực tế từ bước triển khai, `/path/to/your/test_image.jpg` bằng đường dẫn hình ảnh hợp lệ, và `"Apple"` bằng loại trái cây chính xác.

```bash
curl -X POST YOUR_CLOUD_RUN_URL/predict/ \
     -F "fruit=Apple" \
     -F "file=@/path/to/your/test_image.jpg"
```

## Cấu hình

*   **Đường dẫn Model:** Đường dẫn đến tệp mô hình ONNX được xác định bởi biến môi trường `MODEL_PATH`. Nó mặc định là `cnn_model.onnx` nếu biến môi trường không được đặt. Bạn có thể ghi đè giá trị này trong quá trình triển khai Cloud Run bằng cờ `--update-env-vars`.
*   **Cổng (Port):** Ứng dụng chạy trên cổng `8080` bên trong container, như được định nghĩa trong `Dockerfile` và `CMD`. Cloud Run tự động ánh xạ các yêu cầu bên ngoài đến cổng này.