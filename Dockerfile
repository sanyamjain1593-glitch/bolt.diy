# ---- Build stage (Debian, glibc) ----
FROM node:20-bullseye-slim AS build
WORKDIR /app

# Tools needed for native modules (e.g., sharp) & node-gyp
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 make g++ git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN npm i -g pnpm

# Install deps
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile=false

# Copy source and build
COPY . .
# Build to the folder Bolt.DIY uses in production
RUN pnpm vite build --sourcemap false

# ---- Runtime stage (Nginx) ----
FROM nginx:1.25-alpine

# Static files
WORKDIR /usr/share/nginx/html
COPY --from=build /app/build/client ./

# Nginx template that injects COOP/COEP headers and serves SPA
COPY nginx.template /etc/nginx/templates/default.conf.template

# Let nginx entrypoint render the template with $PORT
ENV NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/templates
ENV NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx/conf.d

EXPOSE 8080
CMD ["/docker-entrypoint.sh", "nginx", "-g", "daemon off;"]
