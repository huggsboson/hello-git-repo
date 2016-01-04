DOCKER_MACHINE_IP := $(shell docker-machine ip $(shell docker-machine active))

# keys
keys:
	ssh-keygen -t rsa -b 4096 -N '' -C "fake@fake.com" -f ./id_rsa

# build
build-hello-git-repo: Dockerfile.daemon
	docker build -t hello-git-repo:daemon --file=Dockerfile.daemon .

build-hello-git-repo-ssh: build-hello-git-repo Dockerfile.ssh
	docker build -t hello-git-repo:ssh  --file=Dockerfile.ssh .


# run
hello-git-repo: build-hello-git-repo clean-containers
	docker run -p 9418:9418 --detach=true --name hello-git-repo hello-git-repo:daemon 

hello-git-repo-ssh: build-hello-git-repo-ssh clean-containers
	docker run -p 2222:22 -d --name hello-git-repo-ssh hello-git-repo:ssh 

clean-containers:
	docker kill hello-git-repo > /dev/null 2>&1; docker rm hello-git-repo > /dev/null 2>&1; true
	docker kill hello-git-repo-ssh > /dev/null 2>&1; docker rm hello-git-repo-ssh > /dev/null 2>&1; true


# clone 
clone-hello: clean-clone
	git clone git://$(DOCKER_MACHINE_IP)/hello.git hello

clone-hello-ssh: clean-clone
	ssh-agent /bin/sh -c 'ssh-add ./id_rsa; git clone ssh://git@$(DOCKER_MACHINE_IP):2222/~/hello.git hello-ssh'

clean-clone:
	rm -Rf hello/
	rm -Rf hello-ssh/

clean: clean-containers clean-clone

