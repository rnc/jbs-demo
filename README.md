
Java Build Service Demonstration Script
=======================================


This is a script to assist in setting up a JBS demo.

It expects the JBS Installer to be cloned next to it. It will setup:

* A nexus instance utilising `https://github.com/m88i/nexus-operator` to set it up.
* It then install JBS setting the appropriate Maven variables so it can deploy to the Nexus instance.

It can setup a GitLab instance though this requires some extra manual work to create a token through the UI and export `GIT_DEPLOY_TOKEN`

This has been tested with kubectl v1.28.4 and kustomize v5.2.1.
