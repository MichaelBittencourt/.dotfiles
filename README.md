# Michael Bittencourt Dotfiles

This project was created to make easy install dotfiles in an other environment

## Install

### With curl

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/MichaelBittencourt/.dotfiles/main/download.sh)"
```

### With wget
```bash
bash -c "$(wget https://raw.githubusercontent.com/MichaelBittencourt/.dotfiles/main/download.sh -O -)"
```

## To development

You can made changes to this script without affect your current environment. To do this you can use the container in dev mode.
To this mode you need have docker and docker-compose installed and working on your machine.

### To build the Docker container to test changes

```bash
docker-compose build
```

### To test changes you can start the container

```bash
docker-compose run test
```

When you run the test service you will see the behaviour similar to copy the install command and run on your local machine.
This command will run inside docker container. After install the fish shell will open with Tide theme.
Check the content of /dev folder that has a script to run this command and another to mock the sudo in the container.
