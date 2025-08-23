# Use a Node.js Long Term Support (LTS) Alpine image for stability and smaller size.
FROM node:lts-alpine

# Set the working directory inside the container.
WORKDIR /app

# Copy package.json and package-lock.json first to leverage Docker layer caching.
COPY package*.json ./

# Install Node.js dependencies. Use 'npm ci' for clean, reproducible installs.
RUN npm ci

# Copy the rest of the application code.
COPY . .

# Expose the port where the Express.js app will run (defaulting to 3000).
EXPOSE 8686

# Command to run the application when the container starts.
# This assumes a "start" script is defined in package.json (e.g., "node server.js").
CMD ["node", "app.js"]
