# Build stage for Python backend
FROM python:3.10-slim AS python-builder

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir wheel setuptools && \
    pip wheel --no-cache-dir --wheel-dir=/app/wheels -r requirements.txt

# Build stage for Frontend
FROM node:18-alpine AS frontend-builder

WORKDIR /app/project_base

# Copy package.json and install dependencies
COPY project_base/package.json ./ || true
COPY project_base/package-lock.json ./ || true
RUN npm install

# Copy frontend source code and build
COPY project_base/ ./
RUN npm run build

# Final stage for the combined application
FROM python:3.10-slim

WORKDIR /app

# Copy wheels from python-builder stage
COPY --from=python-builder /app/wheels /app/wheels
RUN pip install --no-cache-dir --no-index --find-links=/app/wheels/ /app/wheels/* && \
    rm -rf /app/wheels

# Copy Python application code
COPY app /app/app
COPY main.py requirements.txt fly.toml /app/

# Copy built frontend assets from frontend-builder stage
COPY --from=frontend-builder /app/project_base/dist /app/static/frontend

EXPOSE 8000

CMD ["python", "main.py"]