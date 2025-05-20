# --- Build Stage ---
    FROM python:3.12-slim AS builder
    WORKDIR /app
    
    # Install system dependencies for building Python packages
    RUN apt-get update && apt-get install -y \
        curl gcc libpq-dev build-essential \
        && rm -rf /var/lib/apt/lists/*
        curl wget libpq-dev gcc \
        && rm -rf /var/lib/apt/lists/*
    
    # Install Doppler and Sentry CLI
    RUN curl -Ls https://cli.doppler.com/install.sh | sh && \
        pip install --upgrade pip && \
        pip install sentry-cli
    
    # Copy built code and installed packages from build stage
    COPY --from=builder /app /app
    
    # Expose FastAPI port
    EXPOSE 8000
    
    # Healthcheck (calls FastAPI's /health endpoint)
    HEALTHCHECK CMD wget --no-verbose --tries=1 --spider http://localhost:8000/health || exit 1
    
    # Run the FastAPI app with Doppler
    CMD ["doppler", "run", "--", "uvicorn", "app.main:app_instance", "--host", "0.0.0.0", "--port", "8000"]
    