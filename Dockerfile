FROM alpine
WORKDIR /home
ADD ./micro-serv /bin/
ENTRYPOINT ["micro-serv"]
