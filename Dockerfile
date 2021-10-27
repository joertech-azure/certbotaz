# FROM mcr.microsoft.com/azure-cli
# # RUN apk add python3 python3-dev py3-pip build-base libressl-dev musl-dev libffi-dev jq
# # RUN pip3 install pip --upgrade
# # RUN pip3 install certbot
# RUN apk add --no-cache certbot

FROM certbot/certbot

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
RUN export KUBEDIR=$HOME/aks-bin
RUN mkdir $KUBEDIR
RUN export PATH=$PATH:$KUBEDIR
RUN az aks install-cli --install-location=$KUBEDIR/kubectl --kubelogin-install-location=$KUBEDIR/kubelogin


RUN mkdir /etc/letsencrypt
COPY ./* /home/
RUN chmod -R a+x /home/*.sh
# The following expects the env variables DOMAIN, EMAIL and AKV
CMD ["bash", "-c", "/home/certbot_generate.sh"]
