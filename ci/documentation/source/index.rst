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
To use Koality, you'll need to create a koality.yml (or .koality.yml) in the root of your repository. The koality.yml file is responsible for the configuration and the execution of scripts that run on your verification machines in the cloud and we look for this file in order to provision your cloud testing machines. We allow you to run arbitrary shell scripts within the koality.yml file, which means that this file can be as simple or as powerful as you need.

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
Admin Panel and Options
=======================
Optimizing Koality for Speed
============================
Troubleshooting
===============
