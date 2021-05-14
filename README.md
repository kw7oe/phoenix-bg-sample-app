# Sample

This is the follow along repository for my ["Blue Green Deployment"](https://kaiwern.com/posts/2021/03/29/blue-green-deployment/) article.

The Vagrant virtual machine is setup with the following:

- Nginx _(default config is removed)_
- PostgreSQL

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

3. If you are following along the article, you could also add the following
   line to your `/etc/hosts` file _(you'll need sudo access to change
   /etc/hosts`)_:

```
192.168.33.40 domain.app
```

4. Now you can follow along on the blog post by:

- Setting up the nginx configuration for blue version.
- Setting up the nginx configuration for green version.

5. You can destory the Vagrant VM by running `vagrant destroy` in the `vagrant`
   directory.
