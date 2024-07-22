#!/bin/bash
while ! minikube status | grep -q 'host: Running'; do sleep 5; done
curl -L -o pipeline_config.xml https://github.com/kodal035/nodejs-app/raw/main/pipeline_config.xml
if ! command -v jenkins-cli > /dev/null; then
  wget http://localhost:8080/jnlpJars/jenkins-cli.jar
fi
java -jar jenkins-cli.jar -s http://localhost:8080 create-job nodejs-app < pipeline_config.xml
