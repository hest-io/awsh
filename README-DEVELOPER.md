# AWSH: Cloud Shell

AWS Shell: Load and use your AWS identities with all your favorite AWS tools

## Using/Developing AWSH with VS Code Remote

- Clone the repo and open it in VS Code. VS Code will detect the Container configuration and offer to re-open your workspace in a Container

    ![Source](.devcontainer/docs/images/Selection_611.png)

- Add your own source code/tools as normal

- You also have AWSH embedded into your default Terminal

    ![Source](.devcontainer/docs/images/Selection_615.png)

### Customization

- Modify the contents of `docker-compose.yml` to suit your own preferences and environment (add your own extensions)

    ![Source](.devcontainer/docs/images/Selection_614.png)

- If you made changes, when prompted by VS Code select to "Rebuild" the Container

### Manually starting Remote

- You can also start/build the Container by using the "Remote" option (bottom-left) or via the Command Palette

    ![Source](.devcontainer/docs/images/Selection_612.png)

    ![Source](.devcontainer/docs/images/Selection_613.png)

