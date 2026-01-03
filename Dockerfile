FROM registry.dev.sbiepay.sbi:8443/ubi9/nginx-126:9.6-1754404361

USER 0

# Create app directory
RUN mkdir -p /usr/share/nginx/html/merchantsimulator

# Copy frontend build
COPY ./dist/ /usr/share/nginx/html/merchantsimulator

# Copy runtime config template (IMPORTANT)
COPY ./dist/runtime-config.template.js /usr/share/nginx/html/merchantsimulator/runtime-config.template.js

# Permissions
RUN chmod 755 -R /usr/share/nginx/html/merchantsimulator \
    && chown -R nginx:nginx /usr/share/nginx/html/merchantsimulator

# Copy nginx configuration (NO CHANGE)
COPY ./nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080/tcp

# Generate runtime-config.js from env vars and start nginx
CMD ["/bin/sh", "-c", \
  "envsubst < /usr/share/nginx/html/merchantsimulator/runtime-config.template.js \
  > /usr/share/nginx/html/merchantsimulator/runtime-config.js && \
  /usr/sbin/nginx -g 'daemon off;'"]
