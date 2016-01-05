DOCKER_MACHINE_IP := $(shell docker-machine ip $(shell docker-machine active))
REPO = "huggsboson/hello-git-repo"

# keys
keys:
	ssh-keygen -t rsa -b 4096 -N '' -C "fake@fake.com" -f ./id_rsa


# build
build-hello-git-repo-base: Dockerfile.base
	docker build -t $(REPO):base --file=Dockerfile.base .

build-hello-git-repo-daemon: build-hello-git-repo-base Dockerfile.daemon
	docker build -t $(REPO):daemon --file=Dockerfile.daemon .

build-hello-git-repo-ssh: build-hello-git-repo-base Dockerfile.ssh
	docker build -t $(REPO):ssh --file=Dockerfile.ssh .


# run
hello-git-repo-daemon: build-hello-git-repo-daemon clean-containers
	docker run -p 9418:9418 --detach=true --name hello-git-repo-daemon $(REPO):daemon 
	# git address on kube-master git://10.245.1.2/hello.git

hello-git-repo-ssh: build-hello-git-repo-ssh clean-containers
	docker run -p 2244:22 --detach=true --name hello-git-repo-ssh $(REPO):ssh 

clean-containers:
	docker kill hello-git-repo > /dev/null 2>&1; docker rm hello-git-repo-daemon > /dev/null 2>&1; true
	docker kill hello-git-repo-ssh > /dev/null 2>&1; docker rm hello-git-repo-ssh > /dev/null 2>&1; true


# clone 
clone-hello: clean-clone
	git clone git://$(DOCKER_MACHINE_IP)/hello.git hello

clone-hello-ssh: clean-clone
	chmod 600 ./id_rsa
	ssh-agent /bin/sh -c 'ssh-add ./id_rsa; git clone ssh://git@$(DOCKER_MACHINE_IP):2222/~/hello.git hello-ssh'

clean-clone:
	rm -Rf hello/
	rm -Rf hello-ssh/


# release
release: build-hello-git-repo-daemon build-hello-git-repo-ssh
	docker push $(REPO):base
	docker push $(REPO):daemon
	docker push $(REPO):ssh

clean: clean-containers clean-clone

