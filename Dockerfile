FROM python:3.11-slim

WORKDIR /app

# Install system deps needed by scipy/numpy
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc g++ && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Train all models at build time so they're baked into the image
RUN python eeg_ml.py all

# Railway injects PORT env var; Flask must bind to 0.0.0.0
ENV PORT=5004
EXPOSE ${PORT}

CMD python ui_app.py
