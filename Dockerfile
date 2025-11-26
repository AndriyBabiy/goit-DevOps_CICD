# Use official Python image (3.9 or newer as required)
FROM python:3.11-slim

# Set environment variables
# Prevents Python from writing .pyc files
ENV PYTHONDONTWRITEBYTECODE=1
# Prevents Python from buffering stdout/stderr
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install system dependencies
# Required for psycopg2 and other packages
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Expose port 8000 for Django
EXPOSE 8000

# Run Django development server or gunicorn
# For development:
# CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

# For production (recommended):
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "myproject.wsgi:application"]