FROM signalk/signalk-server:latest

# Switch to root to modify system files
USER root

# Install git for GitHub updates and copy our custom startup script
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
COPY startup.sh /usr/lib/node_modules/signalk-server/startup.sh
RUN chmod +x /usr/lib/node_modules/signalk-server/startup.sh

# Final container settings
WORKDIR /home/node/.signalk
ENV IS_IN_DOCKER=true
USER node
EXPOSE 3000

