FROM nginx:1.10
RUN echo "deb http://deb.debian.org/debian jessie-backports main" >> /etc/apt/sources.list

RUN apt-get update && apt-get -y install certbot -t jessie-backports
RUN mkdir /www

ADD dhparam.pem /dhparam.pem
ADD run.sh /run.sh
ADD config.template.conf /config.template.conf
EXPOSE 443 80
VOLUME ["/www"]
CMD [ "/run.sh" ]
