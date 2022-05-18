FROM mcr.microsoft.com/azure-cli:2.36.0

RUN apk --no-cache add python3 python3-dev py3-pip build-base libressl-dev musl-dev libffi-dev jq ;\
    pip3 install --no-cache-dir pip --upgrade ;\
    pip3 install --no-cache-dir certbot certbot-dns-azure;\
    apk --no-cache del python3-dev py3-pip build-base libressl-dev musl-dev libffi-dev

COPY ./*.sh ./*.md /home/
RUN adduser -D crtbot ;\
    mkdir -p /home/crtbot ;\
    mv /home/*.sh /home/*.md /home/crtbot/ ;\
    chmod -R a+x /home/crtbot/*.sh ;\
    chown -R crtbot /home/crtbot/*.sh ;\
    mkdir -p /home/crtbot/logs ;\
    mkdir -p /home/crtbot/letsencrypt ;\
    mkdir -p /home/crtbot/work ;\
    chown -R crtbot:crtbot /home/crtbot/logs ;\
    chown -R crtbot:crtbot /home/crtbot/letsencrypt ;\
    chown -R crtbot:crtbot /home/crtbot/work ;

USER crtbot

# The following expects the env variables DOMAIN, EMAIL and AKV
CMD ["bash", "-c", "/home/crtbot/certbot_generate.sh"]
