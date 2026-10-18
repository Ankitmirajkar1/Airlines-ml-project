FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    STREAMLIT_SERVER_HEADLESS=true \
    STREAMLIT_BROWSER_GATHER_USAGE_STATS=false \
    AIRLINE_API_URL=http://127.0.0.1:8000

WORKDIR /app

# libgomp is required by scikit-learn's native extensions.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgomp1 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system app \
    && useradd --system --gid app --home-dir /app app

COPY requirements.txt ./
RUN python -m pip install --no-cache-dir -r requirements.txt

COPY --chown=app:app backend ./backend
COPY --chown=app:app frontend ./frontend
COPY --chown=app:app artifacts/arrival_delay_model.joblib ./artifacts/arrival_delay_model.joblib
COPY --chown=app:app artifacts/metrics.json ./artifacts/metrics.json

USER app

EXPOSE 8501 8000

# The frontend calls the colocated API through localhost. Docker publishes the
# Streamlit port by default; publish 8000 too only when direct API access is needed.
CMD ["sh", "-c", "python -m uvicorn backend.main:app --host 127.0.0.1 --port 8000 & exec python -m streamlit run frontend/app.py --server.address 0.0.0.0 --server.port 8501"]

USER app

EXPOSE 8000 8501
