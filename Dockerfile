# Simple Nginx container that serves static content from /usr/share/nginx/html
FROM nginx:alpine
COPY app /usr/share/nginx/html