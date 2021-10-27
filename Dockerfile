# FROM mcr.microsoft.com/azure-cli
# # RUN apk add python3 python3-dev py3-pip build-base libressl-dev musl-dev libffi-dev jq
# # RUN pip3 install pip --upgrade
# # RUN pip3 install certbot
# RUN apk add --no-cache certbot

#FROM certbot/certbot
FROM ubuntu:focal

RUN df -h
RUN apt update && apt install -y certbot azure-cli && apt-get -y clean && rm -rf /var/lib/apt/lists/*
# RUN apt update && apt install -y certbot curl
#
# RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
# # RUN export KUBEDIR=/home/aks-bin ;\
# #     mkdir -p $KUBEDIR ;\
# #     az aks install-cli --install-location=$KUBEDIR/kubectl --kubelogin-install-location=$KUBEDIR/kubelogin
#
# RUN az aks install-cli

# RUN rm -rf /var/lib/apt/lists/*
RUN df -h

#ENV PATH=/home/aks-bin:$PATH

RUN mkdir -p /etc/letsencrypt
COPY ./* /home/
RUN chmod -R a+x /home/*.sh
# The following expects the env variables DOMAIN, EMAIL and AKV
CMD ["bash", "-c", "/home/certbot_generate.sh"]
