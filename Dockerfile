# Build Stage
FROM python:3.11-slim AS builder

# Set working directory
WORKDIR /app

# Copy Python dependencies
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

#Production Stage
FROM python:3.11-slim AS production

WORKDIR /app

COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Copy backend code
COPY app.py .
COPY utils/ ./utils/
COPY templates/ ./templates/

# Expose the app port (Flask default 5000)
EXPOSE 5000

# Run the app
CMD ["python", "app.py"]
