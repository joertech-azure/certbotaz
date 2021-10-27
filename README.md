# certbotaz


based on erjosito/certbot-azcli repository. 


with an addition of possibility for dns-zonefile to be in a different subscription as where certbotaz container will be runnning and keyvault will be stored.

but changed the docker container to use `apk add certbot` install instead of `pyp3 install certbot` and without '-dev' packages. 

Restulting conatainer image got reduced in size from 850 MB to 65MB. 
