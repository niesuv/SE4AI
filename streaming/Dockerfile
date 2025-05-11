FROM tiangolo/nginx-rtmp
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 1935
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]