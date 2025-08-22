# Simple Nginx container that serves static content from /usr/share/nginx/html
FROM nginx:alpine

# Copy your static site (HTML/CSS/JS) into Nginx's web root
COPY app/ /usr/share/nginx/html/
