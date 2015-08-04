# dl-machine

Scripts to setup a GPU / CUDA enable compute server with libraries to study deep learning development

## Setting up an Amazon g2.2xlarge spot instance

- log in to AWS management console and select EC2 instances
- select US-WEST (N. California) region in top left menu
- click on "Spot Request" on the leftmost menu and click "Request Spot Instances"
- select community AMIs and search for `ubuntu-14.04-hvm-deeplearning-paris`
- on the Choose instance Type tab, select GPU instances `g2.2xlarge`
- bid a price larger than current price (e.g. $0.30, if it fails check the spot pricing history for that instance type)
- in configure security group click Add Rule, and add a Custom TCP Rule with port Range `8888-8889` and from `Anywhere` 
- Review and launch, save the `mykey.pem` file
 
Once your machine is up (status : running in the online console), note the address to your instance :
 `INSTANCE_ID.compute.amazonaws.com`

Note: other regions with access to the deeplearning-paris image: Singapore, Ireland, North Virginia

## Start using your instance

#### Using the notebooks
By default an IPython notebook server and an iTorch notebook server should be running on port 8888 and 8889 respectively. You need to open those ports in the `Security Group` of your instance if you have not done so yet.

To start using your instance, simply open the following URLs in your favorite browser:

- http://INSTANCE_ID.compute.amazonaws.com:8888
- http://INSTANCE_ID.compute.amazonaws.com:8889


#### SSH Connection to your instance
Once the instance is up, you might need to access directly your instance via SSH:
- change the file `mykey.pem` accessibility:
```
chmod 400 mykey.pem
```
- ssh to your instance 
```
ssh -i mykey.pem ubuntu@INSTANCE_ID.compute.amazonaws.com
```

## Other instructions

#### Setting up ssh connection keys

This optional part helps you setting ssh connection keys for better and easier access to your instance. If you already have a public key, skip the keygen part.

- On your own generate a ssh key pair:
```
ssh-keygen
```
- Then go through the steps, you'll have two files, id_rsa and id_rsa.pub (the first is your private key, the second is your public key - the one you copy to remote machines)
```
cat ~/.ssh/id_rsa.pub
```
- On the remote instance, open authorized_keys file the and append your key id_rsa.pub 
```
vi ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```
- On your local machine, you can then use a ssh-agent to store the decrypted key in memory so that you don't have to type the password each time. You can also add an alias in your `~/.ssh/config` file:
```
Host dlmachine
     HostName INSTANCE_ID.compute.amazonaws.com
     User ubuntu
     ServerAliveInterval 300
     ServerAliveCountMax 2
```
- You can now SSH to your machine with the following command:
```
ssh dlmachine
```

#### Running ipython / iTorch server

If the notebooks do not work you can login to your instance via as ssh:

```
ssh -A ubuntu@INSTANCE_ID.compute.amazonaws.com
```

(optional) Start a screen or tmux terminal:

```
screen
```
Use the `top` or `ps aux` command to check whether the ipython process is running. If this is not the case, launch the ipython and itorch notebook server:
```
ipython notebook --ip='*' --port=8888 --browser=none
itorch notebook --ip='*' --port=8889 --browser=none
```

