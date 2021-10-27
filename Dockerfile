FROM mcr.microsoft.com/azure-cli
RUN df -h | grep overlay
RUN apk add python3 python3-dev py3-pip build-base libressl-dev musl-dev libffi-dev jq ;\
    pip3 install pip --upgrade ;\
    pip3 install certbot ;\
    apk del python3-dev py3-pip build-base libressl-dev musl-dev libffi-dev
    

#RUN apk add --no-cache certbot
RUN df -h | grep overlay

# FROM ubuntu:focal
#
# RUN df -h | grep overlay
# RUN apt update && apt install -y certbot azure-cli && apt-get -y clean && rm -rf /var/lib/apt/lists/*
# # #     az aks install-cli --install-location=$KUBEDIR/kubectl --kubelogin-install-location=$KUBEDIR/kubelogin
# RUN df -h | grep overlay

#ENV PATH=/home/aks-bin:$PATH

RUN mkdir -p /etc/letsencrypt
COPY ./* /home/
RUN chmod -R a+x /home/*.sh
# The following expects the env variables DOMAIN, EMAIL and AKV
CMD ["bash", "-c", "/home/certbot_generate.sh"]
