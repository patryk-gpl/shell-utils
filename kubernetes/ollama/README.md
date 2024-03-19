- [Resources](#resources)
- [Run Ollama locally with Docker](#run-ollama-locally-with-docker)
  - [Ollama](#ollama)
  - [Quick API test (get list of models)](#quick-api-test-get-list-of-models)
    - [Sync models to remote VM](#sync-models-to-remote-vm)
  - [Open WebUI](#open-webui)

# Resources

- [Open WebUI is an extensible, feature-rich, and user-friendly self-hosted WebUI designed to operate entirely offline](https://docs.openwebui.com/)
- [Ollama main](https://ollama.com/)
- [Open WebUI login page](https://openwebui.com/auth?type=login)
- [Ollama API reference](https://github.com/ollama/ollama/blob/main/docs/api.md)

# Run Ollama locally with Docker

- [Ollama in DockerHub](https://hub.docker.com/r/ollama/ollama)

## Ollama

Run Ollama:

```bash
docker run -d -v $HOME/.ollama:/root/.ollama -p 8081:11434 --name ollama ollama/ollama
docker exec -it ollama ollama ls # no output expected yet, unless models were copied already
```

## Quick API test (get list of models)

```bash
curl -s http://localhost:11434/api/tags | jq -r '.models[].name'
```

### Sync models to remote VM

To sync models from localhost to a remote VM (login to remote VM first):

```bash
rsync -avz -e ssh /usr/share/ollama/.ollama/models <hostname>:.ollama/
```

And then make it available for already deployed `ollama` container:

```shell
docker run -it --rm -v ollama:/vol -v $HOME/models:/models busybox sh
cp -R models/ /vol/
exit
```

Now the test should be successful:

```shell
docker exec -it ollama ollama ls # output expected
```

## Open WebUI

Run Open WebUI in a Docker container.

```bash
docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main
```
