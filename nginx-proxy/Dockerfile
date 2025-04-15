FROM nginx:alpine

# Copy custom Nginx config
COPY nginx.conf /etc/nginx/

# Copy custom HTML files
COPY html/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"] 
