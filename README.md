# AWSH: Cloud Shell

AWS Shell: Load and use your AWS identities with all your favorite AWS tools

## What is AWSH and how can it help me?

The AWSH tools are a collection of Python and BASH helper scripts that are intended to augment your existing interaction with AWS by;

- Helping with the loading of AWS credentials into the environment that can be re-used by all of your existing AWS toolset; Terraform, AWS CLI, Terraforming, Ansible, etc
- Helping to generate useful information about existing resources you already have on AWS in a format that can be used as part of a pipeline for other tools/apps


## Docker by default

The preferred method of installing and using AWSH is now a Docker container based version that brings you all that you need to run and use AWSH without disrupting your normal OS package setup.

This should make it easier for you to use the latest version and make it easier to rollback an update if a new version breaks something you relied on


## Get and use AWSH

### Basic Usage

- From your command line pull and run the latest AWSH image

    ```console
    $ docker run -it hestio/awsh
    ```

### Use AWSH with persistent identities

- Create a path to store your AWSH identities

    ```console
    $ mkdir -p ${HOME}/.awsh
    ```

- Run the AWSH container, passing in your AWSH identities

    ```console
    $ docker run \
        -it \
        --network=host \
        -v ${HOME}/.awsh:/home/awsh/.awsh \
        -v ${HOME}:/workspace \
        -v /tmp:/tmp \        
        hestio/awsh
    ```

### Use AWSH with persistent identities, workspace, proxy config and AD/Kerberos credentials

- Create a path to store your AWSH identities

    ```console
    $ mkdir -p ${HOME}/.awsh
    ```

- Run the AWSH container, passing in your AWSH identities and your Kerberos setup and your proxy environment

    ```console
    $ docker run \
        -it \
        --network=host \
        -v ${HOME}/.awsh:/home/awsh/.awsh \
        -v /etc/krb5.conf:/etc/krb5.conf \
        -v /etc/krb5.conf.d/:/etc/krb5.conf.d/ \
        -v ${HOME}:/workspace \
        -v /tmp:/tmp \
        -e "http_proxy=${http_proxy}" \
        -e "https_proxy=${https_proxy}" \
        -e "no_proxy=${no_proxy}" \
        hestio/awsh
    ```
