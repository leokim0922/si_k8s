# Use an official Airflow image as the base
FROM apache/airflow:2.8.1

# Copy the requirements.txt file into the Docker image
COPY requirements.txt /requirements.txt

# Install the Python dependencies
RUN pip install --no-cache-dir -r /requirements.txt