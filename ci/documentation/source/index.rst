.. Koality documentation master file, created by
   sphinx-quickstart on Fri Apr 12 14:34:26 2013.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Getting Started
===============
Before you begin (checklist)
----------------------------
To set up Koality, you\'ll need know some details about your system. Here's a general checklist of things we recommend you know/do before beginning:

#. The languages and versions your system needs installed
#. System dependencies (downloaded through apt) your testing/production environment needs
#. Libraries your code relies on, or an automated way to install them (bundler, mvn, script)
#. How to compile your code from the command line (if you compile)
#. How to run your tests from the command line
#. DNS credentials

   * This is used to point your chosen internal domain name to your Koality master

#. AWS credentials that will allow you to run and deploy our system

   * All of the information required here can be found at https://portal.aws.amazon.com/gp/aws/securityCredentials
   * The main Koality instance needs the ability to launch other instances to verify your change, this requires:
   
     - Access Key ID (An alphanumeric string)
     - Secret Access Key (A base64 string)

#. Security groups for Koality to use

   * The master instance must have the following ports opened

     - TCP Port 443: https
     - TCP Port 80: http
     - TCP Port 22: ssh with security restrictions for git only
     - TCP Port 2222: alternate ssh for administrative purposes
   
   * The verification instances will be launched on an automatically-generated security group named \"koality_verification\"

Change Verification and Testing Environment Configuration (koality.yml)
=======================================================================
To use Koality, you'll need to create a koality.yml (or .koality.yml) in the root of your repository. The koality.yml file is syntactic sugar around shell script that allows you to easily configure your verification machines in the cloud and recreate your production/testing environment. The syntax of the koality.yml file is simple enough to be easily understood, but if necessary, is powerful enough to run arbitrary scripts for configuration.

Writing a koality.yml
---------------------
languages
~~~~~~~~~

setup
~~~~~

compile
~~~~~~~

test
~~~~

Installation and Server Setup
=============================

SERVER SETUP STUFF GOES HERE

Installation of Koality is quite simple. Launch an instance of the koality service AMI. Then, using your DNS credentials point your internal domain name to the ip address of that instance. The instance will take a few minutes to start.

Open up the domain name you chose in your browser (or the ip of the koality service instance works too) and follow the wizard for first time setup.

Once you've completed all these steps, you're all set! Koality is up and running. Time to make your first push!

Admin Panel and Options
=======================
Optimizing Koality for Speed
============================
1. I make large changes and git push takes a long time
      
      AWS is notorious for having bad IO. The larger the instance you choose for the Koality master, the faster the IO and the faster your git push will work.

Troubleshooting
===============
1. I can't push or pull from Koality 

     You should double check the security group you placed Koality master in. Make sure tcp port 22 (ssh) is open to the ips you are pushing from.(Hint: AWS is sometimes finicky. Trying 0.0.0.0 and 127.0.0.1 rather than localhost may fix issues)

2. Pulling works, but pushing to Koality master times out

     Are you using an elastic IP? Koality master needs to know its own ip, and elastic IPs erase the previous IP address from an AWS instance. Wait a few minutes and try again, since the Koality master will update itself.

3. Pushing doesn't send anything to Koality, but goes directly into my git repository

     Check to see that you've updated your .gitconfig to point to the Koality master. Koality acts as a proxy, so if you don't point to the proxy, we can't verify your changes!

4. Koality accepts my change, but doesn't show the correct stages and immediately rejects the change

     Check your koality.yml file to make sure it is valid.
