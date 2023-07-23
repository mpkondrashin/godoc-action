FROM golang:1.20-bookworm

ENV GOPATH /
RUN go get golang.org/x/tools/cmd/godoc
COPY ./main.bash /bin/main.bash

CMD ["/bin/main.bash"]
