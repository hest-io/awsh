# AWSH: Cloud Shell

AWS Shell: Load and use your AWS identities with all your favorite AWS tools


## What is AWSH and how can it help me?

The AWSH tools are a collection of Python and BASH helper scripts that are intended to augment your existing interaction with AWS by;

- Helping with the loading of AWS credentials into the environment that can be re-used by all of your existing AWS toolset; Terraform, AWS CLI, Terraforming, Ansible, etc
- Helping to generate useful information about existing resources you already have on AWS in a format that can be used as part of a pipeline for other tools/apps

---

 - View the [AWSH Documentation]

[AWSH Documentation]: http://awsawsh.readthedocs.io/


## Docker by default

The preferred method of installing and using AWSH is now a Docker container based version that brings you all that you need to run and use AWSH without disrupting your normal OS package setup.

This should make it easier for you to use the latest version and make it easier to rollback an update if a new version breaks something you relied on


## Get and Use AWSH

- From your command line pull the latest AWSH image

    ```console
    $ docker pull kxseven/awsh:latest
    ```

- Run the AWSH container, passing in your AWSH identities

    ```console
    $ docker run \
        -it \
        --network=host \
        -v ${HOME}/.awsh:/home/awsh/.awsh \
        kxseven/awsh:latest
    ```

- Run the AWSH container, passing in your AWSH identities and your Kerberos setup

    ```console
    $ docker run \
        -it \
        --network=host \
        -v ${HOME}/.awsh:/home/awsh/.awsh \
        -v /etc/krb5.conf:/etc/krb5.conf \
        -v /etc/krb5.conf.d/:/etc/krb5.conf.d/ \
        kxseven/awsh:latest
    ```
