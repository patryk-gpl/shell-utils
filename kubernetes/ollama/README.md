# Resources

- [Open WebUI is an extensible, feature-rich, and user-friendly self-hosted WebUI designed to operate entirely offline](https://docs.openwebui.com/)
- [Ollama main](https://ollama.com/)
- [Open WebUI login page](https://openwebui.com/auth?type=login))

# Open WebUI

Run Open WebUI in a Docker container.

```bash
docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main
```
