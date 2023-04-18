FROM ubuntu:22.04
 
RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get install build-essential wget socat iproute2 -y

WORKDIR /root
ADD redis-server /root/.colink/redis-server
ENV HOME=/root
ENV COLINK_HOME=/root/.colink

RUN mkdir -p ~/.colink && cd ~/.colink && wget https://github.com/CoLearn-Dev/colink-server-dev/releases/download/v0.3.4/colink-server-linux-x86_64.tar.gz && tar -xf colink-server-linux-x86_64.tar.gz
ENTRYPOINT ip addr add 127.0.0.1/32 dev lo && ip link set dev lo up && socat vsock-listen:5000,reuseaddr,fork tcp-connect:127.0.0.1:8080 & cd root/.colink ; ./colink-server --address "127.0.0.1" --port 8080 & sleep 5 && cat host_token.txt ; echo && sleep infinity