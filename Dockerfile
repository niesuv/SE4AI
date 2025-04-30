# Dockerfile

# Stage 1: Base Image & Dependencies
# ------------------------------------
# Use a specific minor version of Python on a slim Debian base for reproducibility and smaller size.
# Example: python:3.9.18-slim-bullseye (Check for latest patch versions)
# Using python:3.9-slim is also acceptable but less deterministic over time.
FROM python:3.9-slim AS base

# Set environment variables for best practices:
# 1. PYTHONUNBUFFERED: Prevents Python output from being buffered, ensuring logs appear in real-time.
# 2. PYTHONDONTWRITEBYTECODE: Prevents Python from writing .pyc files, useful in containerized environments.
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Set the working directory inside the container.
WORKDIR /app

# Install OS-level dependencies if needed.
# Example: curl is needed for the HEALTHCHECK instruction later.
# Run apt-get update before install and clean up apt cache afterwards to keep the layer small.
# Do this *before* creating the non-root user if installs require root.
RUN apt-get update && \
    apt-get install --no-install-recommends -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user and group for security.
# Running containers as a non-root user is a critical security best practice.
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Copy only the requirements file first to leverage Docker's layer caching.
# If requirements.txt doesn't change, this layer and the subsequent pip install layer won't be rebuilt.
COPY requirements.txt .

# Install Python dependencies:
# - Upgrade pip first.
# - Install torch/torchvision CPU version specifically (saves space if GPU isn't needed).
# - Install all other dependencies from requirements.txt.
# - Use --no-cache-dir to reduce image size by not storing the pip download cache.
# - Use --require-hashes if you generate a lock file with pinned, hashed dependencies for enhanced security (advanced).
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt

# Switch to the non-root user *before* copying application code.
USER appuser

# Copy the rest of the application code into the working directory.
# Ensure the non-root user owns these files.
COPY --chown=appuser:appgroup . .

# Expose the port the application will listen on.
# This is documentation for the user and informs tools like Cloud Run which port to target.
# It does not publish the port on the host.
EXPOSE 8080

# Add a health check instruction.
# Docker (and Cloud Run, Kubernetes, etc.) can use this to verify the application is healthy.
# It tries to fetch the root path ('/') every 30 seconds. Fails after 3 retries of 5 seconds each.
# Adjust the endpoint and timings as needed. Assumes the '/' endpoint in main.py returns a 2xx status on success.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl --fail http://localhost:8080/ || exit 1

# Define the command to run the application when the container starts.
# Use the JSON array format for CMD (exec form).
# Runs the Uvicorn ASGI server, binding to all interfaces (0.0.0.0) on the exposed port.
# 'main:app' tells Uvicorn to find the FastAPI application instance named 'app' inside the 'main.py' file.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]