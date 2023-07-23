FROM golang:1.20-bookworm

ENV GOPATH /
RUN go install golang.org/x/tools/cmd/godoc
COPY ./main.bash /bin/main.bash

CMD ["/bin/main.bash"]
