FROM debian:bookworm-slim 
COPY ./bridge_client_linux_arm64 .
COPY ./entrypoint.sh .
ENV TOKEN=''
ENV ORGANIZATION_ID=''
ENTRYPOINT ["/bin/bash","./entrypoint.sh"]