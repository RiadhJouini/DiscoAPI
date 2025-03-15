FROM python:3.9-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY agent.py .
COPY requirements.txt .
COPY entrypoint.sh /entrypoint.sh

RUN pip install --no-cache-dir -r requirements.txt

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
