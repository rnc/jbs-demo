
Java Build Service Demonstration Script
=======================================


This is a script to assist in setting up a JBS demo.

It expects the JBS Installer to be cloned next to it. It will setup:

* A nexus instance utilising `https://github.com/m88i/nexus-operator` to set it up.
* It then install JBS setting the appropriate Maven variables so it can deploy to the Nexus instance.
