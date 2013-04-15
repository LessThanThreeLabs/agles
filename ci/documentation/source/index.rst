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
Languages are specified as a simple key-value pair mapping language name to version. You can use unsupported languages by installing them with your own script under the `"scripts"`_ section of setup.

The following languages are supported:

- Java and JVM:
   * Chosen with "java" or "jvm"
   * Supported versions include 1.5 and 1.6
- Node.js:
   * Chosen with "nodejs"
   * Uses nvm for versioning to support most standard versions
- Python:
   * Chosen with "python"
   * Uses a virtualenv for safe versioning
   * Supported versions include 2.5, 2.6, 2.7, 3.2, 3.3
- Ruby
   * Chosen with "ruby"
   * Uses rvm for versioning to support most standard versions

setup
~~~~~
The setup section defines the production or testing environment for your code. Each step in the setup section is explicitly ordered to function like a shell script, and the return code for each step is checked to validate that no steps fail. The three major types of setup steps are "packages_", "databases_", and `"scripts"`_.

packages
````````
The packages section defines package dependencies. Each item in the level directly below packages must be a package type, which includes "system_", "gem_", "npm_", and "pip_". Within each package type, a list of packages should be specified, each as either the package name or a key-value pair specifying the name and version.

system
******
System packages specify packages that are installed by the system package manager. Koality currently uses Ubuntu 12.04 machines for verification, so each package listed under "system" must be installable via the aptitude package manager (apt-get).

gem
***
In addition to the syntax for installing a single package by name or name and version, the additional command "bundle install" is supported for gems. "bundle install" uses bundler to install packages listed in a Gemfile. If you specify "bundle install" as a key-value pair, the value denotes the relative path to your Gemfile from the root of your repository.

npm
***
In addition to the syntax for installing a single package by name or name and version, the additional command "npm install" is supported for npm. "npm install" runs the command "npm install" in either a specified directory or from the root of your repository if not specified.

pip
***
In addition to the syntax for installing a single package by name or name and version, the additional command "install requirements" is supported for pip. "install requirements" runs the command "pip install -r" with the given path to a requirements file, defaulting to "requirements.txt".

databases
`````````
The databases section defines databases that you wish to use for testing. Each database is represented by a dictionary specifying the name of the database and the username with which to access it. Each database must be specified in a list below the database type. Supported database types are "mysql" and "postgres"

.. _`"scripts"`:

scripts
```````
The scripts section is used to run any other scripts or commands that cannot be simplified by the packages and databases sections. Each script must be represented as either a string or a dictionary.

The dictionary form is as follows:

| path: relative path from the repository root at which to run the command
| script: a string or array of commands to run

The string form is just the name of the command to be run, which will run from the repository root.

compile
~~~~~~~
The compile section is used to specify any compilation steps that must be run before running tests.

Each step should be specified as a script, and as such your steps should be represented as a list under a parent key "scripts". Each of these scripts should be represented as either a string or a dictionary.

.. _`script format`:

The dictionary form is as follows:

| script name:
|     path: relative path at which to run the command  # This is optional and defaults to the repository root
|     script: a string or array of commands to run  # This is optional and defaults to the name

The string form is just the name of the command to be run, which uses the default values for the dictionary form above.

test
~~~~
The test section is used to specify any test steps that must be run to verify your change. All test steps can be run in parallel across any virtual machines launched to verify your change, allowing each test step to run only once.

The test section is specified as a single dictionary defining three parts that designate how to best run your tests, which are "machines_", "scripts__", and "factories_".

__ `test scripts`_

machines
````````
The value specified for machines should be a positive integer denoting the number of machines to use to parallelize your tests.

.. _`test scripts`:

scripts
```````
The scripts section should contain a list of scripts that each follow the same format used for compile, which is `specified above`__.

__ `script format`_

factories
`````````
The factories section should contain a list of scripts which construct other test sections to run. This can be used for automatically splitting up a large number of tests using anything ranging from a simple shell script to code introspection.

Each of these factory steps should be specified in the `test script format`__, and their output should be in the same format, which will then be parsed and treated the same as manually-specified test scripts.

__ `script format`_

Installation and Server Setup
=============================
Installation of Koality is quite simple. Launch an instance of the koality service AMI. This will be a private AMI with a name beginning with "koality_service". Then, using your DNS credentials point your internal domain name to the ip address of that instance. The instance will take a few minutes to start.

Open up the domain name you chose in your browser (or the ip of the koality service instance works too) and follow the wizard for first time setup. If no page loads yet, you may need to wait a few minutes for Koality to first initialize.

Wizard Walkthrough
------------------
Upon initial startup, visiting your instance of Koality will redirect you to an installation wizard. This simple wizard makes sure your deployment has everything it needs to run smoothly.

Step 1 - Domain Name:
~~~~~~~~~~~~~~~~~~~~~
Enter the domain name of your Koality instance. This is important so that Koality can send emails and links with the correct domain name.

For example, setting the domain name to “koality.foo.com” will:

* Notify a user that change 137 failed by linking them to koality.foo.com/repository/1?change=137
* Send invites to other users by having them visit koailty.foo.com/create/account
* Allow users to share and discuss specific changes and stages by linking them to koality.foo.com/repository/1?change=385&stage=4238


Step 2 - Initial Admin:
~~~~~~~~~~~~~~~~~~~~~~~
Create the initial admin. Koality admins can manage users, repositories, and even other admins. After completing the wizard, this admin should invite other users to Koality (discussed later).


Step 3 - Verify Admin:
~~~~~~~~~~~~~~~~~~~~~~
Enter the admin token emailed to you. This token is used to verify that you own the email address entered.


Step 4 - AWS Credentials:
~~~~~~~~~~~~~~~~~~~~~~~~~
Enter your AWS credentials so that Koality can use EC2 to verify changesets. Koality needs these credentials so it can spawn EC2 instances as they are needed.

To find your AWS credentials:

#. Visit http://aws.amazon.com
#. Click on My Account/Console in the top-right corner, and select Security Credentials
#. Click the Access Credentials section and select the Access Keys tab


Once you've completed all these steps, you're all set! Koality is up and running. Time to make your first push!

Admin Panel and Options
=======================
At the end of server setup, the created user is designated as an "Admin", which grants him access to system configuration settings. To view these settings, click on the link titled "Admin" in the upper right corner.

Manage Website
--------------
Sets the domain that the Koality server is located at. This is the internal domain you chose earlier (and what you type into your browser as the URL).

Koality uses this domain in order to send emails and send results from the testing machines to the koality service machine.

Manage User Accounts
--------------------
This panel allows you to add and remove users from your Koality instance.

Manage Repositories
-------------------
This page allows your basic repository management functionality including adding and removing repositories.

Repository URL
--------------
Koality acts as a proxy to an actual repository, intercepting commits and forwarding requests. The repository URL allows Koality to know where the actual repository is located in order to forward successful changes (push) or redirect pulls.

To modify this URL, click the "Edit URL" setting.

Repository SSH Keys
-------------------
Koality creates a unique private/public rsa key pair for every repository. Since we act as a proxy, this key allows us to perform actions on the actual repository (such as forwarding pushes or pulls). The view this key, click on "Show SSH".

You should give Koality access to the actual repository through this SSH key. If you are using github, log in to a user account with privileges to this repository (or have an admin log into the admin github account for your company), and add this SSH key to the list of accepted keys.

Manage AWS
----------
Configuration for your AWS Settings.

**Access Key:** Your AWS Access Key

**Secret Key:** Your AWS Secret Key

Together, the AWS Access Key and Secret Key allows us to manage your EC2 Cloud and create/destroy and set up verification VMs.

**Instance Size:** The VM instance size of a verification machine. Larger instances will run your tests faster due to higher hardware specifications

**Num waiting instances:** The size of the standing (always available) VM pool. On EC2, VMs can take up to 2 minutes to spin up. This can be a hefty time cost your organization isn't willing to take. To counterbalance this, we allow you to define a number of "always ready" instances so you don't have to wait in order to use a VM.

**Max running instances:** The max number of EC2 instances that can be running at any given time.

For example, if you have Num waiting instances set to 8 and Max running instances set to 20, 8 VMs will always be provisioned and ready to use. However, if the system comes under heavy load, up to 12 more VMs may be spawned (for a total of 20) to be used at any given time.

Upgrade
-------
As of this writing, automatic upgrades are not yet implemented. When an update is available, a member of the Koality team will contact you.


Optimizing Koality for Speed
============================
1. I make large changes and git push takes a long time

      AWS is notorious for having bad IO. The larger the instance you choose for the Koality master, the faster the IO and the faster your git push will work.

Troubleshooting
===============
1. I can't push or pull from Koality

     First, check to make sure you have your SSH keys set correctly. Make sure you've uploaded your (personal) SSH key to your user account. If this is correct, make sure you've uploaded the repository SSH key to the repository server.

     You should double check the security group you placed Koality master in. Make sure tcp port 22 (ssh) is open to the ips you are pushing from.(Hint: AWS is sometimes finicky. Trying 0.0.0.0 and 127.0.0.1 rather than localhost may fix issues)

2. Pushing doesn't send anything to Koality, but goes directly into my git repository

     Check to see that you've updated your .gitconfig to point to the Koality master. Koality acts as a proxy, so if you don't point to the proxy, we can't verify your changes!

3. Koality accepts my change, but doesn't show the correct stages and immediately rejects the change

     Check your koality.yml file to make sure it is valid. The easiest first step for this is to verify that you are using valid YAML with a tool such as http://yamllint.com. Oftentimes this is caused by indenting your YAML file with tabs, which violates the YAML spec.
