GITBOX
======
Gitbox is a docker image that combines a preconfigured [git] (https://git-scm.com) server utilizing the git [smart-http] (https://git-scm.com/book/en/v2/Git-on-the-Server-Smart-HTTP) service for repository access. This is complemented by an installation of [gitlist] (https://github.com/klaussilveira/gitlist). Git smart-http and gitlist are served via [nginx] (http://nginx.org).

Installation:
-------------

Gitbox requires docker to be installed and operational. You can then either download this image from [hub.docker.com] (https://hub.docker.com/r/nmarus/docker-gitbox/), or clone this repository from [github.com] (https://github.com) and build the image locally.

The [master branch] (https://github.com/nmarus/docker-gitbox) is where all development is done. The [stable branch] (https://github.com/nmarus/docker-gitbox/tree/stable) is where all feature testing has been completed. The [hub.docker.com] (https://hub.docker.com/r/nmarus/docker-gitbox/) repository is built from the stable branch. Review the [README.md] (https://github.com/nmarus/docker-gitbox/blob/stable/README.md) for the stable branch as it is often quite different than that of the master branch. The master branch is in flux and features are constantly being tweaked and added.

**To install and run from the hub.docker.com image repository:**

From your docker host (or remote docker client):

    docker run -d -it --name gitbox \
        -h <container_fqdn> \
        -e FQDN=<container_fqdn> \
        -p 80:80 \
        -v /srv/gitbox/repos:/repos \
        -v /srv/gitbox/ng-auth:/ng-auth \
        nmarus/docker-gitbox

**To install and run from this from the github source repository:**

From your docker host:

    git clone stable https://github.com/nmarus/docker-gitbox.git
    cd docker-gitbox
    docker build --rm=true -t nmarus/docker-gitbox .
    docker run -d -it --name gitbox \
        -h <container_fqdn> \
        -p 80:80 \
        -v /srv/gitbox/repos:/repos \
        -v /srv/gitbox/ng-auth:/ng-auth \
        nmarus/docker-gitbox

Container to Volume Mapping:
----------------------------
The following volumes are published from this container:

* /repos - This is the location where your repositories live
* /ng-auth - This is the location of the htpasswd file that nginx uses for gitlist and git smart-http authentication

Container to Network Mapping:
-----------------------------
The following ports are published from this container:

* 80 - http access for git smart-http and gitlist access

Server Repository Setup and Admin:
----------------------------------
After installing gitbox, the first thing you will want to do is add some repositories. This can either be an empty repository, or an existing repository from another git server such as [github.com.] (https://github.com)

To make this setup easier, gitbox allows an administrator to define the repositories directly from the docker host without needing to access the shell of the container or worry about setting proper permissions for security.

**To setup an empty repository:**

From your docker host (or remote docker client):

    docker exec gitbox repo-admin -n <repo> -d <description>

*example:*

    docker exec gitbox repo-admin -n myrepo.git -d "This is my first git repo."

**To clone an existing repository from another location:**

From your docker host (or remote docker client):

    docker exec gitbox repo-admin -c <url>

*example:*

    docker exec gitbox repo-admin -c https://github.com/nmarus/docker-gitbox.git

**To remove a gitbox repository:**

From your docker host (or remote docker client):

    docker exec gitbox repo-admin -r <repo>

*example:*

    docker exec gitbox repo-admin -r docker-gitbox.git

**To list all gitbox repositories:**

From your docker host (or remote docker client):

    docker exec gitbox repo-admin -l


Client / Server Connection:
---------------------------
**Setup client to use empty repository via https**

*Note: This example assumes you have created a empty repository (as show above) named "myrepo.git". This is intended to be executed from your git client's command line inside a directory you wish to store the repository locally. See [Getting Started - Git Basics.] (https://git-scm.com/book/en/v2/Getting-Started-Git-Basics)*

From your git client cli:

    mkdir myrepo
    cd myrepo
    git init
    git remote add origin http://<docker host ip or hostname>/git/myrepo.git
    touch README.md
    echo "##This is a README.md file.##" > README.md
    git add -A
    git commit -m "This is my initial commit."
    git push --set-upstream origin master

*Note 1: This process will require authentication to the nginx web server on clone, pull, or push. See Authentication.*

*Note 2: This reuires you at least add one file, commit that file and push it using the last 3 commands. Not doing do will cause git push and git pull to fail.*

**Gitlist Browser Access:**

You can access git box using an internet browser at the url:

    http://<docker host ip or hostname>

*Note: This example assumes you are running gitbox using the default docker mappings defined above. If not, adjust accordingly. If your repository's directory is empty, this url presents a blank page...*

**Git HTTP Access:**

From your git client cli:

    git clone http://<docker host ip or hostname>/git/myrepo.git

*Note 1: There is a slightly different url used in retrieving the git repository in this method. This process will require authentication to the http server on clone, pull, or push. See Authentication.*

Authentication:
---------------
The authentication method and interaction with git and gitlist is still a work in progress. That being said, some authentication is in place through modifications of the nginx htpasswd file. This authentication applies to read and write access via the git smart-http protocol and view access to the gitlist web interface. The htpasswd file is stored in the "/ng-auth" volume and the start.sh script looks for the htpasswd file in this directory on startup. It will only regenerate the htpasswd file when it is not found.

**To grab the initial gitadmin password:**

When the container is built, a random password is generated for the admin account. This account is specified in the Dockerfile. To obtain the initial password run the following command from your docker host (or remote docker client):

    docker exec gitbox cat /ng-auth/gitadmin.password

*Note: This file will delete itself as soon as you add your first user (or reset the admin password) using the steps below.*

**To reset the gitadmin account password:**

From your docker host (or remote docker client):

    docker exec gitbox ng-auth -u gitadmin -p <password>

**To add an additional user (or ro change the password of a user)**

From your docker host (or remote docker client):

    docker exec gitbox ng-auth -u <user-name> -p <password>

**To remove a user**

From your docker host (or remote docker client):

    docker exec gitbox ng-auth -r <user-name>

**To remove all users and reinitialize the user database:**

From your docker host (or remote docker client):

    docker exec gitbox ng-auth -x

SSL:
----
Native SSL is not provided, but can be added through manipulating the /etc/nginx/nginx.conf file and uploading the appropriate certificates. This container also supports being placed behind a reverse SSL proxy (such as nginx). 
