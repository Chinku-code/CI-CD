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

##################################################################################

dockerbuild:
  stage: dockerbuild
  image: registry.dev.sbiepay.sbi:8443/library/podman:latest
  script:
    - echo "--- Docker Build & Push START ---"
    - echo "Environment: ${ENV}"
    - echo "Image: ${IMAGE_REGISTRY}/${IMAGE_NAME}:${VERSION}"

    # Login to registry
    - podman login ${IMAGE_REGISTRY} \
        -u ${IMAGE_REGISTRY_USERNAME} \
        -p ${IMAGE_REGISTRY_PASS}

    # Build image once
    - podman build -t ${IMAGE_NAME}:${VERSION} .

    # Tag for target registry
    - podman tag ${IMAGE_NAME}:${VERSION} \
        ${IMAGE_REGISTRY}/${IMAGE_NAME}:${VERSION}

    # Push image
    - podman push ${IMAGE_REGISTRY}/${IMAGE_NAME}:${VERSION}

    - echo "--- Docker Build & Push DONE ---"

  rules:
    - if: '$CI_COMMIT_BRANCH == "develop"'
      variables:
        ENV: dev
        IMAGE_REGISTRY: ${DEV_IMAGE_REGISTRY}
        IMAGE_NAME: "${CHART_NAME}"
        IMAGE_REGISTRY_USERNAME: $DEV_REGISTRY_USERNAME
        IMAGE_REGISTRY_PASS: $DEV_REGISTRY_PASSWORD

    - if: '$CI_COMMIT_BRANCH =~ /^release\/.*$/'
      when: always
      variables:
        ENV: nonprod
        IMAGE_REGISTRY: ${PERF_IMAGE_REGISTRY}
        IMAGE_NAME: "${CHART_NAME}"
        IMAGE_REGISTRY_USERNAME: $PERF_REGISTRY_USERNAME
        IMAGE_REGISTRY_PASS: $PERF_REGISTRY_PASSWORD
