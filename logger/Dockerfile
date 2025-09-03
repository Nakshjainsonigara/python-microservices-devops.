FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    LOG_DIR=/logs \
    LOG_FILE=requests.log

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY app.py /app/app.py

VOLUME ["/logs"]

EXPOSE 6000

CMD ["gunicorn", "-w", "1", "-b", "0.0.0.0:6000", "app:app"]

