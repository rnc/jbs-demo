

# JBS And Jenkins

In order to setup Jenkins and JBS there are a number of prerequisite steps. Note that this demo assumes using Jib to 
push to Quay, not any form of docker or podman within OpenShift.

## Sample Repositories

The two sample repositories that we used for this demo are:

* https://github.com/rnc/Nasa-Picture.git and quay.io/ncross/nasapicture:latest
* https://github.com/rnc/hacbs-test-simple-jdk8.git and quay.io/ncross/hacbs-test-simple-jdk8:latest

## Install/Configure Jenkins

Assuming as per other demo installations this will be installed upon OpenShift, it is possible to switch to the 
'Developer' mode, click Add, browse and locate Jenkins with persistent storage. It is recommended change the PVC to have 2.5GB and the Jenkins memory limit to 2GB.

### Jenkins Tools/Plugins

Under Dashboard/Manage Jenkins/Plugins, add the following plugins to Jenkins:

* https://plugins.jenkins.io/gradle
* https://plugins.jenkins.io/http_request
* https://plugins.jenkins.io/persistent-parameter
* https://plugins.jenkins.io/ws-cleanup

Under Dashboard/Manage Jenkins/Tools, add a JDK configuration:

* Configure to install automatically
* Use URL of e.g. https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.22%2B7/OpenJDK11U-jdk_x64_linux_hotspot_11.0.22_7.tar.gz
* Add subdir of jdk-11.0.22+7

Under Dashboard/Manage Jenkins/Tools, add a Maven configuration:

* Configure to install automatically.
* The associated Jenkins file assumes a name of `Maven396`


## Jenkins Credentials

Create the following credentials within Dashboard/Manage Jenkins/Credentials/System/Global credentials (unrestricted):

| ID              | Kind         | Username              | Value                                    |
|-----------------|--------------|-----------------------|------------------------------------------|
| quay-jbs        | Username/Pwd | Quay.io Robot Account | Quay.io Robot Account                    |
| console-jbs     | Username/Pwd | admin                 | Console password                         |
| console-jbs-url | SecretTxt    | N/A                   | Url of console e.g. `http://<ip>:<port>` |

# Configure Quay.io

Currently the Quay.io repositories **and** hooks have to be created prior to running the pipeline. It is potentially
possible to use an OAuth token from a Quay.io application to create via the API
* https://access.redhat.com/documentation/en-us/red_hat_quay/3.10/html/red_hat_quay_api_guide/using_the_red_hat_quay_api#accessing_the_red_hat_quay_api_from_the_command_line
* https://docs.quay.io/api/swagger/#

Configure a Robot account for the above Jenkins credentials and give each repository access to it.

Configure a webhook for each repository that, on Push, will notify the mangement console e.g. 
`http://<ip>:8080/api/quay`

# Setup JBS Console

The JVM console needs to be running and listening to potential requests. Note that if its running in dev mode it must be explicitly configured to listen on all interfaces e.g.

```
mvn quarkus:dev -DskipTests -Dquarkus.http.host=0.0.0.0
```

The firewall/router must be configured to allow port 8080 through.

# Setup Jenkins Pipeline

Configure the Jenkins pipeline to use the associated Jenkinsfile.