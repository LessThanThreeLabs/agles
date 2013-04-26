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
A koality.yml file consists of four sections: languages_, setup_, compile_, and test_. Each of these sections is used as a simple way of specifying the steps required to configure a machine to verify each change.

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

Creating a Personal SSH Key
===========================
Github has written wonderful documentation on this. You can find it at: https://help.github.com/articles/generating-ssh-keys

Admin API
=========

Your Admin REST Api is located at ``https://<domain-name>:1337``.

All api calls must include your Admin Api Key, which can be found in the admin panel under "api": ``https://<domain name>/admin?view=api``. This key can be included in the query string of a GET request or in the body of a POST request.

Calls to the admin api are versioned. Currently the verison is 0, which can be seen in the admin api url (ex: https://domain-name:1337/v/0/...).

Data can be displayed in either json (default) or xml format.
  Show data in json by adding .json to the end of the url (ex: https://koality.company.com:1337/v/0/users.json)
  Show data in xml by adding .xml to the end of the url (ex: https://koality.company.com:1337/v/0/users.xml)

Users
-----

All Users
~~~~~~~~~

  :Url: ``https://<domain name>:1337/v/0/users``
  :Request type: GET
  :Query params: 
    :key: the admin api key (string)
  :Returns:
    :id: the user id (number)
    :email: the user email (string)
    :firstName: the user's first name (string)
    :lastName: the user's last name (string)
    :isAdmin: whether this user is an admin (boolean)
    :created: timestamp when the user was created, in milliseconds (number)
  :Example: https://domain-name:1337/v/0/users?key=whatislove


Single User
~~~~~~~~~~~

  :Url: ``https://<domain name>:1337/v/0/users/<user id>``
  :Request type: GET
  :Query params: 
    :key: the admin api key (string)
  :Returns:
    :id: the user id (number)
    :email: the user email (string)
    :firstName: the user's first name (string)
    :lastName: the user's last name (string)
    :isAdmin: whether this user is an admin (boolean)
    :created: timestamp when the user was created, in milliseconds (number)
  :Example: https://domain-name:1337/v/0/users/17?key=whatislove


Repositories
------------

All Repositories
~~~~~~~~~~~~~~~~

  :Url: ``https://<domain name>:1337/v/0/repositories``
  :Request type: GET
  :Query params:
    :key: the admin api key (string)
  :Returns:
    :id: the repository id (number)
    :name: the name of the repository (string)
    :uri: the Koality uri for the repository (string)
    :publicKey: the repository's public key, to be included in the destination repository (string)
    :created: timestamp when the repository was created, in milliseconds (number)
  :Example: https://domain-name:1337/v/0/repositories?key=whatislove

Single Repository
~~~~~~~~~~~~~~~~~

  :Url: ``https://<domain name>:1337/v/0/repositories/<repository id>``
  :Request type: GET
  :Query params:
    :key: the admin api key (string)
  :Returns:
    :id: the repository id (number)
    :name: the name of the repository (string)
    :uri: the Koality uri for the repository (string)
    :publicKey: the repository's public key, to be included in the destination repository (string)
    :created: timestamp when the repository was created, in milliseconds (number)
  :Example: https://domain-name:1337/v/0/repositories/7?key=whatislove


Changes
-------

All Changes
~~~~~~~~~~~

  :Url: ``https://<domain name>:1337/v/0/repositories/<repository id>/changes``
  :Request type: GET
  :Query params:
    :key: the admin api key (string)
    :search: names to search for, defaults to '' (string)
    :start: where to start search, where 0 represents the most recent (number)
    :results: number of results to return (number)
  :Returns:
    :id: the change id (number)
    :number: the change number for the repository (number)
    :status: the change's current status (string)
    :mergeStatus: whether the change successfully merged (boolean)
    :createTime: timestamp when the change was created, in milliseconds (number)
    :startTime: timestamp when the change was started, in milliseconds (number)
    :endTime: timestamp when the change ended, in milliseconds (number)
  :Example: https://domain-name:1337/v/0/repositories/7/changes?key=whatislove&search=koala&start=0&results=100

Single Change
~~~~~~~~~~~~~

  :Url: ``https://<domain name>:1337/v/0/repositories/<repository id>/changes/<change id>``
  :Request type: GET
  :Query params:
    :key: the admin api key (string)
  :Returns:
    :id: the change id (number)
    :number: the change number for the repository (number)
    :status: the change's current status (string)
    :user:
      :id: the id for the user that created the change (number)
      :email: the email for the user that created the change (string)
      :firstName: the first name of the user that created the change (string)
      :lastName: the last name of the user that created the change (string)
    :headCommit:
      :message: the message for the head commit (string)
      :sha: the sha for the head commit (string)
    :target: the branch for that change (string)
    :mergeStatus: whether the change successfully merged (boolean)
    :createTime: timestamp when the change was created, in milliseconds (number)
    :startTime: timestamp when the change was started, in milliseconds (number)
    :endTime: timestamp when the change ended, in milliseconds (number)
  :Example: https://domain-name:1337/v/0/repositories/7/changes/9001?key=whatislove

Create Change
~~~~~~~~~~~~~

  :Url: ``https://<domain name>:1337/v/0/repositories/<repository id>/changes``
  :Request type: POST
  :Body:
    :key: the admin api key (string)
    :sha: the sha to verify (string)
  :Returns:
    :changeId: the newly created change id (number)


Stages
------

All Stages
~~~~~~~~~~

  :Url: ``https://<domain name>:1337/v/0/repositories/<repository id>/changes/<change id>/stages``
  :Request type: GET
  :Query params:
    :key: the admin api key (string)
  :Returns:
    :id: the stage id (number)
    :type: the type of stage (string)
    :name: the name of the stage (string)
    :status: whether the stage is running, passed, or failed (string)
  :Example: https://domain-name:1337/v/0/repositories/7/changes/9001/stages?key=whatislove

Single Stage
~~~~~~~~~~~~

  :Url: ``https://<domain name>:1337/v/0/repositories/<repository id>/changes/<change id>/stages/<stage id>``
  :Request type: GET
  :Query params:
    :key: the admin api key (string)
  :Returns:
    :id: the stage id (number)
    :type: the type of stage (string)
    :name: the name of the stage (string)
    :status: whether the stage is running, passed, or failed (string)
    :lines: an array of lines [string]
  :Example: https://domain-name:1337/v/0/repositories/7/changes/9001/stages/1234?key=whatislove


Aws
---

Getting Information
~~~~~~~~~~~~~~~~~~~

  :Url: ``https://<domain name>:1337/v/0/aws``
  :Request type: GET
  :Query params:
    :key: the admin api key (string)
  :Returns:
    :awsKeys:
      :accessKey: aws access key (string)
      :secretKey: aws secret key (string)
    :allowedInstances: array of allowed instance types [string]
    :instanceSettings:
      :instanceSize: currently selected instance size (string)
      :numWaiting: number of instances to have waiting (number)
      :maxRunning: maximum number of running instances (number)
  :Example: https://domain-name:1337/v/0/aws?key=whatislove

Setting Information
~~~~~~~~~~~~~~~~~~~

  :Url: ``https://<domain name>:1337/v/0/aws``
  :Request type: POST
  :Body:
    :key: the admin api key (string)
    :awsKeys:
      :accessKey: aws access key (string)
      :secretKey: aws secret key (string)
    :instanceSettings:
      :instanceSize: currently selected instance size (string)
      :numWaiting: number of instances to have waiting (number)
      :maxRunning: maximum number of running instances (number)
  :Returns: ``ok`` on success


Domain
------

Getting Information
~~~~~~~~~~~~~~~~~~~

  :Url: ``https://<domain name>:1337/v/0/domain``
  :Request type: GET
  :Query params:
    :key: the admin api key (string)
  :Returns:
    :name: the domain name (string)
  :Example: https://domain-name:1337/v/0/domain?key=whatislove

Setting Information
~~~~~~~~~~~~~~~~~~~

  :Url: ``https://<domain name>:1337/v/0/domain``
  :Request type: POST
  :Body:
    :key: the admin api key (string)
    :name: the domain name (string)
  :Returns: ``ok`` on success


Optimizing Koality for Speed
============================
1. I make large changes and git push takes a long time

      AWS is notorious for having bad IO. The larger the instance you choose for the Koality master, the faster the IO and the faster your git push will work.

Troubleshooting
===============

1. My SSH key doesn't appear to be working.

     Have you uploaded your SSH key to Koality? Make sure you have before you continue. You can do this from the Account->SSH Keys (click on your name to get there).

     Additionally, if you have more than one key, SSH may be handing Koality the wrong key. The SSH protocol only sends 1 key over the wire. If you have multiple keys, it sometimes selects the incorrect one. Temporarily remove all of you keys (other than the one you uploaded to Koality) from your ~/.ssh directory and try again to verify.

     If all else fails, you'll need to do some manual debugging. You can see what SSH is doing by passing the -v option to a git pull or git push (you can also do ssh -v git@your.internal.koality.com).

2. I can't push or pull from Koality

     First, check to make sure you have your SSH keys set correctly. Make sure you've uploaded your (personal) SSH key to your user account. If this is correct, make sure you've uploaded the repository SSH key to the repository server.

     You should double check the security group you placed Koality master in. Make sure tcp port 22 (ssh) is open to the ips you are pushing from.(Hint: AWS is sometimes finicky. Trying 0.0.0.0 and 127.0.0.1 rather than localhost may fix issues)

3. Pushing doesn't send anything to Koality, but goes directly into my git repository

     Check to see that you've updated your .gitconfig to point to the Koality master. Koality acts as a proxy, so if you don't point to the proxy, we can't verify your changes!

4. Koality accepts my change, but doesn't show the correct stages and immediately rejects the change

     Check your koality.yml file to make sure it is valid. The easiest first step for this is to verify that you are using valid YAML with a tool such as http://yamllint.com. Oftentimes this is caused by indenting your YAML file with tabs, which violates the YAML spec.
