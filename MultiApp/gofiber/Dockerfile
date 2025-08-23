FROM alpine:latest

# Create required directories
RUN mkdir /source /app

# Set working directory for the project
WORKDIR /source

# Copy project files into the container
COPY . .

# Move the built binary to the final directory
RUN mv /source/bin /app
RUN rm -rf /source

# Set working directory to /app and run the application
WORKDIR /app
RUN chmod +x /app/bin/api
CMD ["./bin/api"]
