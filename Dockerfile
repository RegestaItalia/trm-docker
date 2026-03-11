# syntax=docker/dockerfile:1
FROM --platform=linux/amd64 node:22-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      libc-bin \
      util-linux \
      bash \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/trm /usr/local/sap /r3trans

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY first-run-init.sh /usr/local/bin/first-run-init.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/first-run-init.sh

ENV TRM_STATE_DIR=/var/lib/trm
ENV SAPNWRFC_HOME=/var/lib/trm/nwrfcsdk
ENV R3TRANS_HOME=/var/lib/trm/r3trans

ENV TRM_DOCKERIZED=true

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]