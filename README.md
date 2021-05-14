# Sample

This is the follow along repository for my ["Blue Green Deployment"](https://kaiwern.com/posts/2021/03/29/blue-green-deployment/) article.

The Vagrant virtual machine is setup with the following:

- Nginx
  - Remove default configuration.
- PostgreSQL
  - Create `sample_prod` database.
  - Create `sample_app` user.

## Instructions

1. Setup your virtual machine (VM) locally with Vagrant by running the following:

```bash
cd vagrant
vagrant up
```

By the end of the command, you should be able to ssh into the vagrant VM by
`vagrant ssh`.

2. To enable yourself to be able to ssh to the Vagrant VM through `ssh vagrant@192.168.33.40`, you'll need to manually copy your public key to the
   Vagrant VM.

```bash
# Or any equivalent public key file path
# pbcopy only works in MacOS, for Ubuntu or Windows
# user, just copy the public key manually after cat.
cat ~/.ssh/id_rsa.pub | pbcopy

# Don't copy the code below if you just run pbcopy above.
vagrant ssh
cat >> ~/.ssh/authorized_keys << EOF
# Paste your public key here
EOF
```

3. If you are following along the post, you could also add the following
   line to your `/etc/hosts` file _(you'll need sudo access to change
   /etc/hosts`)_:

```
192.168.33.40 domain.app
```

4. If you are following along the post, it assume that you have deployed
   your application to the remote server. You can do that first by:

```bash
./deploy.sh

# After deployed
ssh vagrant@192.168.33.40
curl localhost:4000/health
#=> {"healthy":true,"version":"0.1.0"}
```

5. Now you can follow along on the blog post by:

- Setting up the nginx configuration for blue version.
- Setting up the nginx configuration for green version.

6. Deploying green version of our application:

```bash
git apply change_01.diff
./deploy.sh
```

7. Promoting our green version to live:

```bash
./deploy.sh promote green
# ---> Attempting to promote to green...
# ---> Promoted live to blue

# Wait 1-2 seconds
curl domain.app/health
#=> {"healthy":true,"version":"0.1.1"}
```

6. After finishing, You can destory the Vagrant VM by running `vagrant destroy` in the `vagrant`
   directory.
