# Agriculture AI Agent API

Một API thông minh hỗ trợ trả lời các câu hỏi liên quan đến nông nghiệp và thời tiết sử dụng AI và tìm kiếm web.

## Tính năng chính

- **Routing thông minh**: Tự động phân loại câu hỏi và chọn chế độ xử lý phù hợp
- **Chế độ cơ bản**: Trả lời nhanh các câu hỏi đơn giản
- **Chế độ nâng cao**: Tìm kiếm thông tin từ web, đánh giá và tổng hợp để đưa ra câu trả lời chi tiết
- **Hỗ trợ tiếng Việt**: Được tối ưu cho các câu hỏi nông nghiệp tại Việt Nam

## API Endpoints

### POST `/query`

Gửi câu hỏi tới Agriculture Agent.

**Request Body:**
```json
{
  "user_query": "Câu hỏi của bạn"
}
```

**Response:**
```json
{
  "agent_response": "Câu trả lời từ AI Agent"
}
```

## Cách sử dụng

### 1. Sử dụng curl

```bash
curl -X POST [YOUR_API_ENDPOINT]/query \
  -H "Content-Type: application/json" \
  -d "{\"user_query\": \"Nhiệt độ trung bình trong vòng 1 tuần tới tại Quảng Ngãi là bao nhiêu?\"}"
```

**Kết quả trả về:**
```json
{
  "agent_response": "Dựa trên dự báo, nhiệt độ trung bình tại Quảng Ngãi trong 7 ngày tới (từ 31/05/2025 đến 06/06/2025) được dự kiến khoảng 32.1°C[1].\n\n## Dự báo chi tiết hàng ngày\nDưới đây là dự báo nhiệt độ cao nhất và thấp nhất hàng ngày tại Quảng Ngãi cho 7 ngày tới[1]:\n- Thứ bảy (31/05/2025): Nhiệt độ cao nhất 36°C, thấp nhất 28°C[1].\n- Chủ nhật (01/06/2025): Nhiệt độ cao nhất 38°C, thấp nhất 27°C[1].\n..."
}
```

### 2. Sử dụng Python

```python
import requests

url = "[YOUR_API_ENDPOINT]/query"
data = {
    "user_query": "Cách trồng lúa trong mùa khô?"
}

response = requests.post(url, json=data)
result = response.json()
print(result["agent_response"])
```

### 3. Sử dụng JavaScript/Node.js

```javascript
const response = await fetch('[YOUR_API_ENDPOINT]/query', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    user_query: 'Thời tiết hôm nay ở Hà Nội như thế nào?'
  })
});

const data = await response.json();
console.log(data.agent_response);
```

## Ví dụ câu hỏi

### Câu hỏi thời tiết
- "Dự báo thời tiết 3 ngày tới tại TP.HCM"
- "Nhiệt độ trung bình tuần này ở Đà Nẵng"
- "Có mưa không ở Cần Thơ ngày mai?"

### Câu hỏi nông nghiệp
- "Cách trồng rau muống trong thùng xốp"
- "Thời điểm tốt nhất để gieo hạt lúa ở miền Bắc"
- "Cách phòng trừ sâu bệnh cho cây cà chua"

### Câu hỏi kỹ thuật nông nghiệp
- "Cách tính lượng phân bón cho 1 hecta lúa"
- "Hệ thống tưới nhỏ giọt cho vườn rau"
- "Công nghệ nhà kính thông minh"

## Chế độ hoạt động

### Chế độ cơ bản
- Trả lời nhanh các câu hỏi đơn giản
- Sử dụng kiến thức có sẵn của AI

### Chế độ nâng cao (tự động kích hoạt)
- Tìm kiếm thông tin cập nhật từ web
- Đánh giá và lọc thông tin
- Tổng hợp câu trả lời chi tiết với nguồn tham khảo

## Lưu ý

- API hỗ trợ tối đa 5000 ký tự cho mỗi câu hỏi
- Thời gian phản hồi: 2-10 giây tùy độ phức tạp
- Kết quả có thể bao gồm các nguồn tham khảo đáng tin cậy
- API được tối ưu cho các câu hỏi bằng tiếng Việt

## Health Check

Kiểm tra trạng thái API:

```bash
curl [YOUR_API_ENDPOINT]/
```

**Response:**
```json
{
  "status": "healthy",
  "message": "Welcome to the Agriculture AI Agent API!"
}
```

## Cài đặt và chạy local

### Yêu cầu
- Python 3.8+
- Gemini API Key
- Google Custom Search API Key (tùy chọn cho chế độ nâng cao)

### Cài đặt
```bash
pip install -r requirements.txt
```

### Chạy ứng dụng
```bash
python -m app.main
```

API sẽ chạy tại: `http://localhost:8000`