FROM debian:stable
COPY src /home/src
WORKDIR /home/src
RUN apt-get update
RUN apt-get install -y apt-utils apt-transport-https
RUN apt-get install -y make perl curl gnupg2
RUN apt-get install -y libdancer2-perl \ 
	liblwp-useragent-chicaching-perl \
	liblwp-protocol-socks-perl \
	libplack-perl
RUN apt-get install -y tor
RUN echo "deb https://deb.i2p2.de/ stretch main" >> /etc/apt/sources.list
RUN curl https://geti2p.net/_static/i2p-debian-repo.key.asc -o i2p.key
RUN apt-key add i2p.key
RUN apt-get update
RUN apt-get install -y i2p i2p-keyring
RUN sed -i 's/RUN_DAEMON="false"/RUN_DAEMON="true"/g' /etc/default/i2p
EXPOSE 5000/tcp
ENTRYPOINT service tor restart && service i2p restart && plackup bin/app.psgi
