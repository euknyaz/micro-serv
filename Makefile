.PHONY: all image clean publish

IMAGE=euknyaz/micro-serv

all: image

micro-serv: main.go
	go get github.com/Sirupsen/logrus
	go get github.com/prometheus/client_golang/prometheus
	env GOOS=linux GOARCH=amd64 go build -o micro-serv -tags netgo

image: Dockerfile micro-serv
	docker build -t $(IMAGE) .

clean:
	rm -f micro-serv
	docker rmi -f $(IMAGE) 2>/dev/null || true

publish:
	docker push $(IMAGE)
