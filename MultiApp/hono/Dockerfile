# Stage 1: Build Hono application
FROM denoland/deno:latest AS builder

WORKDIR /app

# Copy project files, ensure main.ts (or your entry file) is included.
COPY . .

# Compile Hono app into a single executable named 'hono'.
RUN deno compile --allow-net --allow-read --output hono main.ts

# Stage 2: Run the Hono application
FROM denoland/deno:latest

WORKDIR /app

# Copy the compiled 'hono' executable from the builder stage for a smaller final image.
COPY --from=builder /app/hono .

# Expose the port Hono listens on (default: 3000).
EXPOSE 3000

# Directly run the compiled Hono binary. Permissions are baked in.
ENTRYPOINT ["./hono"]
