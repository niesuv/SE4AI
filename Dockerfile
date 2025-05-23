# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory in the container
WORKDIR /app

# Install system dependencies (if any, e.g., for certain Python libraries)
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     # list-dependencies-here \
#     && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY ./app /app/app
COPY .env.example /app/.env.example # Optional: for reference inside container if needed, but .env should be managed by Cloud Run secrets
# If you have other top-level files like main.py outside 'app' folder:
# COPY main.py .
# COPY agent.py .
# COPY config.py .
# COPY models.py .
# COPY utils.py .
# For now, assuming main.py and others are inside 'app/' or will be created there.
# If your main.py (entrypoint) is directly under SE4AI/, adjust the COPY and CMD.
# Let's assume main.py will be in app/ for now.

# Expose the port the app runs on
# Cloud Run expects the application to listen on the port defined by the PORT environment variable.
# Uvicorn by default listens on 8000. We can make it dynamic.
EXPOSE 8080
ENV PORT 8080

# Command to run the application
# The CMD should start your FastAPI application using Uvicorn.
# Assuming your FastAPI app instance is named 'app' in 'app.main:app'
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "$PORT"]