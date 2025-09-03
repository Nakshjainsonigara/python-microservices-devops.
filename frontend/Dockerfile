FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY app.py /app/app.py
COPY templates /app/templates

ENV BACKEND_URL="http://backend:5000/api/data"

EXPOSE 80

CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:80", "app:app"]

