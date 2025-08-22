# ---- Build stage ----
FROM node:20-alpine AS build
WORKDIR /app

# Install pnpm
RUN npm i -g pnpm

# Install deps
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile=false

# Copy source and build
COPY . .
RUN pnpm vite build --sourcemap false

# ---- Runtime stage ----
FROM nginx:1.25-alpine

# Static files
WORKDIR /usr/share/nginx/html
COPY --from=build /app/build/client ./

# Nginx template that reads $PORT and injects COOP/COEP headers
COPY nginx.template /etc/nginx/templates/default.conf.template

# Tell nginx entrypoint where templates live (it will envsubst $PORT on startup)
ENV NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/templates
ENV NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx/conf.d

# Expose a default port (Render will still inject $PORT)
EXPOSE 8080

# Start nginx (entrypoint will render the template and run nginx)
CMD ["/docker-entrypoint.sh", "nginx", "-g", "daemon off;"]
