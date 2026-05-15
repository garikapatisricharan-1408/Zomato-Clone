# Use a newer Node LTS version (and remove legacy workarounds)
FROM node:20-alpine AS builder
WORKDIR /app

# Separate dependency layer for better caching
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Copy source and build
COPY . .
RUN npm run build

# Nginx stage
FROM nginx:alpine

# Copy built artifacts
COPY --from=builder /app/build /usr/share/nginx/html

# Add nginx config for SPA routing + security
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

EXPOSE 80
USER nginx
CMD ["nginx", "-g", "daemon off;"]
