FROM ubuntu

COPY ./dev/test_script.sh /test_script.sh

RUN apt-get update
RUN apt-get install curl -y

ENTRYPOINT ["/test_script.sh"]
