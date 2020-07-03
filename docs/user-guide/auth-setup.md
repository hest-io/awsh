{!includes/hestio-header.md!}

# Setup AWS Access

There are many different ways to authenticate with AWS for API access. What **AWSH** aims to do is to **help manage your identities without interfering with your access**

Each of the supported methods for authentication to AWS are activated by simply extending the existing credential setup you are already familiar with in `aws.conf`. The only difference is that your identities are managed under `$HOME/.awsh/identities` instead of `.aws`


## Simple Credential Access



