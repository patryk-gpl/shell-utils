# Resources

- [Open WebUI is an extensible, feature-rich, and user-friendly self-hosted WebUI designed to operate entirely offline](https://docs.openwebui.com/)
- [Ollama main](https://ollama.com/)
- [Open WebUI login page](https://openwebui.com/auth?type=login))

# Ollama service


## Start
To run Ollama on local port 8081 and persist the host folder into the running container, use the following command:

```bash
docker run -d -p 8081:11434 -v $HOME/.ollama:/root/.ollama --name ollama ollama/ollama
```

This command will start the Ollama container in detached mode, map port 8081 on the host to port 11434 in the container, and mount the host folder `$HOME/.ollama` to the container's `/root/.ollama` directory for persistent storage.

## SSH Port Forwarding (Optional)
To access a remote Ollama instance, add this to your SSH config:

```bash
Host remote_ollama
    HostName 10.1.1.1
    User remote-username
    IdentityFile ~/.ssh/id_rsa
    LocalForward 0.0.0.0:8081 10.1.1.1:8081
```

This allows the Web UI to connect to the remote host as if it were local.

## Restart

To restart the Ollama container and apply any changes, you can use the following command:

```bash
docker restart ollama
```

This command will restart the Ollama container, allowing it to pick up any modifications or updates that have been made.

# Open WebUI

Run Open WebUI in a Docker container.

```bash
docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:latest
```

After starting, access the Web UI at http://localhost:3000 and configure your Ollama instance (local or remote) running on selected port (local default 11434 or remote 8081).

This command runs a Docker container with the following options:

- `-d`: Run the container in detached mode (in the background).

- `-p 3000:8080`: Map port 3000 on the host to port 8080 in the container. Port 8080 is used by Web UI.

## --add-host=host.docker.internal:host-gateway
- `--add-host=host.docker.internal:host-gateway`: Add a host entry for `host.docker.internal` pointing to the host's gateway. This allows the container to communicate with the host machine. The `--add-host=host.docker.internal:host-gateway` option has a special meaning and purpose in Docker. Let's break it down:

1. `--add-host`: This flag allows you to add a custom host-to-IP mapping in the container's `/etc/hosts` file.

2. `host.docker.internal`: This is a special DNS name used in Docker to refer to the host machine from within a container.

3. `host-gateway`: This is a special keyword in Docker that resolves to the IP address of the host machine as seen from the container's network.

The special significance of this option is:

1. **Cross-platform compatibility**: On macOS and Windows, Docker Desktop automatically creates a DNS entry for `host.docker.internal` that resolves to the host machine. However, this doesn't happen by default on Linux.

2. **Linux support**: By using `--add-host=host.docker.internal:host-gateway`, you're explicitly adding this DNS entry on Linux systems, making your Docker commands more portable across different operating systems.

3. **Host-container communication**: This option allows containers to communicate with services running on the host machine using a consistent hostname (`host.docker.internal`) regardless of the host's actual IP address or the operating system.

4. **Network isolation**: It provides a way for containers to access the host while maintaining network isolation, which is especially useful in development environments.

In summary, `--add-host=host.docker.internal:host-gateway` ensures that the container can reliably communicate with the host machine using the `host.docker.internal` DNS name, regardless of the host operating system or network configuration. This is particularly useful for development scenarios or when the container needs to access services running on the host.

- `-v open-webui:/app/backend/data`: Mount a volume named `open-webui` to the `/app/backend/data` directory in the container. This persists data across container restarts.

- `--name open-webui`: Assign the name "open-webui" to the container.

- `--restart always`: Configure the container to always restart if it stops or if the Docker daemon restarts.

- `ghcr.io/open-webui/open-webui:main`: Specify the image to use for creating the container. This image is pulled from the GitHub Container Registry (ghcr.io) and uses the "main" tag.

This command sets up a container for the Open WebUI application, ensuring it runs in the background, is accessible on port 3000, can communicate with the host, persists data, and automatically restarts if needed.
