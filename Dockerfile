FROM signalk/signalk-server:latest

# Final container settings
WORKDIR /home/node/.signalk
ENV IS_IN_DOCKER=true
USER node
EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/signalk-server"]
