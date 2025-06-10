# Use a lightweight NGINX image
FROM nginx:alpine

# Set working directory
WORKDIR /usr/share/nginx/html

# Remove default nginx static assets
RUN rm -rf ./*

# Copy the React build files to NGINX root
COPY build/ .

# Expose port 80 to the outside world
EXPOSE 80

# Start NGINX in foreground mode
CMD ["nginx", "-g", "daemon off;"]

