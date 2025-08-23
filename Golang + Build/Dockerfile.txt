FROM alpine:latest

# Install base tools + Go dependencies
RUN apk update && apk upgrade && \
    apk add --no-cache git wget bash make

# Create required directories
RUN mkdir /source /app

# Set temporary working directory to install Go
WORKDIR /usr/local

# Download and install Go
RUN wget https://go.dev/dl/go1.23.8.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.23.8.linux-amd64.tar.gz && \
    rm go1.23.8.linux-amd64.tar.gz

# Add Go to PATH environment variable
ENV PATH="/usr/local/go/bin:${PATH}"

# Set working directory for the project
WORKDIR /source

# Copy project files into the container
COPY . .

# Initialize Go modules and build the project
RUN go mod tidy
RUN GOMEMLIMIT=300000000 make build

# Prepare .env file for running in /app
RUN mv .env.prod .env && \
    mv .env /app

# Move the built binary to the final directory
RUN mv ./bin/api /app/bin

# Clean up source files and Go cache
RUN rm -rf /source && \
    go clean -cache -modcache -i -r && \
    rm -rf /root/go && \
    rm -rf /usr/local/go

# Remove build packages
RUN apk del git wget bash make

# Set working directory to /app and run the application
WORKDIR /app
RUN chmod +x /app/bin/api
CMD ["./bin/api"]
