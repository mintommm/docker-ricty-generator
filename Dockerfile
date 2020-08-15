FROM ubuntu:latest

ENV RICTY_URL https://rictyfonts.github.io/files
ENV RICTY_VERSION 4.1.1
ENV MIGU_VERSION 20200307
ENV MIGU_RELEASE_ID 72511

RUN apt-get update \
	&& apt-get install -y curl zip unzip fontforge-nox fonttools \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /Ricty

RUN mkdir -p LICENSE LICENSE/Migu LICENSE/Inconsolata \
	&& curl -o ricty_generator.sh -SL ${RICTY_URL}/ricty_generator-${RICTY_VERSION}.sh \
	&& chmod +x *.sh \
	&& curl -o migu.zip -SL https://osdn.net/projects/mix-mplus-ipa/downloads/${MIGU_RELEASE_ID}/migu-1m-${MIGU_VERSION}.zip \
	&& unzip migu.zip && rm migu.zip \
	&& mv migu-1m-${MIGU_VERSION}/* . \
	&& mv ipag* mplus* migu-README.txt LICENSE/Migu \
	&& rm -r migu-1m-${MIGU_VERSION} \
	&& curl -o Inconsolata-Regular.ttf -SL https://github.com/googlefonts/Inconsolata/raw/master/fonts/ttf/Inconsolata-Regular.ttf \
	&& curl -o Inconsolata-Bold.ttf -SL https://github.com/googlefonts/Inconsolata/raw/master/fonts/ttf/Inconsolata-Bold.ttf \
	&& curl -o LICENSE/Inconsolata/OFL.txt -SL https://github.com/googlefonts/Inconsolata/raw/master/OFL.txt

COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
