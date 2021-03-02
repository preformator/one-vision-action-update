# Server Setup v.1.0.2

# Install docker
echo "Installing docker..."

if ! command -v docker &> /dev/null
then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    docker swarm init
    echo "Done."
else
    echo "Docker already installed, skipping..."
fi

# Setup registry
echo "Creating docker registry.."
docker service create --with-registry-auth --name registry -d -p 5000:5000 registry:2
echo "Done."

# Setup GitHub
echo "Install GitLab actions, follow readMe: Initial server setup 4.)"
read -r -p "Are GitLab actions installed? [Y/n] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo "***** Run builds on the GitHub in order to load docker registry on the serve *****"
    echo "Order:"
    echo "one-vision-static-builder"
    echo "one-vision-builder"

    # Setup max number of file watcher as we are getting following error:
    # "Error: ENOSPC: System limit for number of file watchers reached, watch '/public/tmp/448.json'"
    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
    
    echo "one-vision-scraper"

    echo "Setting up postgres service, creating working directory..."
    mkdir $HOME/postgres-data

    echo "Backup directory with following command: tar -zcvf postgres-data.tar.gz $HOME/postgres-data"
    echo "Restore backup with following command: tar -zxvf postgres-data.tar.gz"

    read -r -p "Did you restored postgres data into $HOME/postgres-data ? [Y/n] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        echo "Proceeding..."

        echo "Setting up portiner"
        mkdir $HOME/portainer_data
        docker service create --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock --mount type=bind,source=$HOME/portainer_data,destination=/data --name portainer --publish published=9000,target=9000 portainer/portainer

        echo "Done, access HOST:9000 to check services"
    else
        echo "Restore postgres data before continuing."
        exit 1
    fi
        
    #docker run -d --name dev-postgres -e POSTGRES_PASSWORD=Pass2020! -v ${HOME}/postgres-data/:/var/lib/postgresql/data -p 5432:5432 postgres
    docker service create --name dev-postgres -e POSTGRES_PASSWORD=Pass2020! -p 5432:5432 --mount type=bind,source=$HOME/postgres-data,destination=/var/lib/postgresql/data postgres

    echo "Run one-vision-keycloak build."
    echo "Run one-vision-frontend build."
else
    echo "Setup GitHub actions in order to proceed further."
fi
