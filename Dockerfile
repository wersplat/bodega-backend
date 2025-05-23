# --- Build Stage ---
FROM python:3.12-slim AS builder
WORKDIR /app

# Install system dependencies for building Python packages
RUN apt-get update && apt-get install -y \
    curl wget gcc libpq-dev build-essential apt-transport-https ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Doppler CLI (Debian 11+/Ubuntu 22.04+)
RUN curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | gpg --dearmor -o /usr/share/keyrings/doppler-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/doppler-archive-keyring.gpg] https://packages.doppler.com/public/cli/deb/debian any-version main" > /etc/apt/sources.list.d/doppler-cli.list \
    && apt-get update \
    && apt-get install -y doppler

# Install Sentry CLI
RUN pip install --upgrade pip && \
    pip install sentry-cli

# --- Runner Stage ---
FROM python:3.12-slim AS runner
WORKDIR /app

# Install Doppler CLI (Debian 11+/Ubuntu 22.04+)
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg \
    && curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | gpg --dearmor -o /usr/share/keyrings/doppler-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/doppler-archive-keyring.gpg] https://packages.doppler.com/public/cli/deb/debian any-version main" > /etc/apt/sources.list.d/doppler-cli.list \
    && apt-get update \
    && apt-get install -y doppler

# Copy built code and installed packages from build stage
COPY --from=builder /app /app

# Expose FastAPI port
EXPOSE 8000

# Healthcheck (calls FastAPI's /health endpoint)
HEALTHCHECK CMD wget --no-verbose --tries=1 --spider http://localhost:8000/health || exit 1

# Run the FastAPI app with Doppler
CMD ["doppler", "run", "--", "uvicorn", "app.main:app_instance", "--host", "0.0.0.0", "--port", "8000"]