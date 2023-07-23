FROM golang:1.20-bookworm

ENV GOPATH /
RUN go install golang.org/x/tools/cmd/godoc@latest
COPY ./main.bash /bin/main.bash

CMD ["/bin/main.bash"]
