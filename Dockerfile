FROM mcr.microsoft.com/azure-cli
#RUN df | grep overlay
RUN apk add python3 python3-dev py3-pip build-base libressl-dev musl-dev libffi-dev jq ;\
    pip3 install pip --upgrade ;\
    pip3 install certbot ;\
    apk del python3-dev py3-pip build-base libressl-dev musl-dev libffi-dev

#RUN df | grep overlay
#
#
#
# FROM ubuntu:focal
#
# # RUN df  | grep overlay
# RUN apt update && apt install -y certbot azure-cli && apt-get -y clean && rm -rf /var/lib/apt/lists/*
# # #     az aks install-cli --install-location=$KUBEDIR/kubectl --kubelogin-install-location=$KUBEDIR/kubelogin
# # RUN df | grep overlay
#
#ENV PATH=/home/aks-bin:$PATH

COPY ./* /home/
RUN chmod -R a+x /home/*.sh ;\
    adduser -D crtbot ;\
    mkdir -p /etc/letsencrypt ; \
    chown -R crtbot:root /home
    chown -R crtbot:root /etc/letsencrypt

USER crtbot

# The following expects the env variables DOMAIN, EMAIL and AKV
CMD ["bash", "-c", "/home/certbot_generate.sh"]
