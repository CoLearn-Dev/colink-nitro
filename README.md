# Colink Nitro

A proof of concept for running a Colink server in an [AWS Nitro Enclave](https://aws.amazon.com/ec2/nitro/), a cloud product offering remote attestation of code.

# Getting Started

### Create a nitro-enabled instance on AWS

* A list of supported instance types can be found on https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#Instances%20built%20on%20the%20Nitro%20System
* Currently the enclave image requires ~1.8gb of memory to run. These steps were performed on a c5.xlarge instance type with the latest Amazon Linux 2 machine image. Remember to enable nitro before launching the instance.

### Prepare the host instance

* The required prerequisites to run the enclave container can be installed and configured using

  ```
  sudo amazon-linux-extras install aws-nitro-enclaves-cli -y
  sudo usermod -aG ne ec2-user
  sudo usermod -aG docker ec2-user
  ```

* Log out and log back in for the changes to take effect
  ````
  sudo systemctl start nitro-enclaves-allocator.service && sudo systemctl enable nitro-enclaves-allocator.service
  sudo systemctl start docker && sudo systemctl enable docker
  ````
* The demo currently uses a version of socat newer than the ones provided by Amazon Linux. As such, the following lines install the prerequisites for building socat from source

  ```
  sudo yum install gcc -y
  wget http://www.dest-unreach.org/socat/download/socat-1.7.4.4.tar.gz
  tar -xf socat-1.7.4.4.tar.gz
  cd socat
  ./configure
  sudo make install
  socat -V
  ```

### Run the enclave

* Download the colink.eif file from the releases tab, or build it yourself using the instructions below (TODO)

  ```
  wget https://github.com/Robit/colink-docker/releases/download/v0.0.1-beta/colink.eif
  ```
* Run the enclave file using the following command

  ```
  nitro-cli run-enclave --cpu-count 2 --memory 1800 --enclave-cid 16 --eif-path colink.eif --debug-mode
  ```
* Verify the enclave comes up

  ```
  nitro-cli describe-enclaves
  ```

### Connect to the enclave locally
* The enclave's http traffic is forwarded to vsock 5000 by default using socat. To convert it back into http, we must create a socat listener on the host that forwards connections through the vsock

  ```
  socat tcp-listen:8080,reuseaddr,fork vsock-connect:16:5000 & 
  #Run in the background for the purposes of the demo. A possible enhancement would be to wrap both the enclave start/stop commands and the socat command in a script
  ```
* Get the host_token for the server using the nitro-cli debug console. It should be a string starting with eY near the tail of the console output

  ```
  nitro-cli console --enclave-name colink
  ```
* Follow the SDK examples [here](https://co-learn.notion.site/CoLink-SDK-Examples-in-Rust-a9b583ac5d764390aeba7293aa63f39d#c6c514acfc234e8cb7dce4e7af3b3a3f), substituting the host_token with the one found in the previous step and the server address with http://localhost:8080
* To connect to the enclave from outside the host machine, forward port 8080 out of the server by configuring the security group for the ec2 instance. Follow the same example as above but replace the server address with the address of the ec2 instance.

# TODO

Add a better way to set/get host_token from server (without using debug mode output)

Create an endpoint for [cryptographic attestation](https://docs.aws.amazon.com/enclaves/latest/user/kms.html)

Add support for TLS certificates through [ACM](https://aws.amazon.com/certificate-manager/)

Lower enclave memory requirment
