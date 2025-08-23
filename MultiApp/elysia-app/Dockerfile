# Base image dengan Bun resmi
FROM oven/bun:latest as builder

# Set direktori kerja
WORKDIR /app

# Salin file dependency
COPY bun.lock package.json tsconfig.json ./

# Install dependency production-only
RUN bun install --production

# Salin source code
COPY ./src ./src

# Compile TypeScript ke JavaScript (jika menggunakan TS)
RUN bun build src/index.ts --outdir dist

# Final image untuk menjalankan app
FROM oven/bun:latest as runner

WORKDIR /app

# Salin node_modules dan dist dari builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package.json ./

# Jalankan aplikasi (ganti path sesuai output tsconfig)
CMD ["bun", "run", "dist/index.js"]

