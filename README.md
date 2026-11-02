# docker-cardano-cli

Builds [Cardano CLI](https://github.com/IntersectMBO/cardano-cli) from source
on Debian and publishes it as a container image.

Cardano CLI used to be built inside the
[docker-cardano-node](https://github.com/blinklabs-io/docker-cardano-node)
image. This repository builds it on its own, so the command-line tool can be
run without a node's other binaries, and so the node image can copy the binary
from here.

## Images

| Registry | Image |
|----------|-------|
| GitHub Container Registry | `ghcr.io/blinklabs-io/cardano-cli` |
| Docker Hub | `blinklabs/cardano-cli` |

Images are published for `linux/amd64` and `linux/arm64`. Tags include
`latest`, the Cardano CLI version (for example `11.4.0.0`), and the version
with a build suffix (for example `11.4.0.0-1`). Pin a version tag rather than
`latest` for anything you need to reproduce.

The image is based on `debian:bookworm-slim`. Besides `cardano-cli` it
includes `bc`, `curl`, `jq`, `socat`, `sqlite3`, `wget` and the runtime
libraries Cardano CLI needs.

## Running Cardano CLI

Arguments to `docker run` after the image name are passed to `cardano-cli`.

```bash
docker run --rm ghcr.io/blinklabs-io/cardano-cli version
```

An optional leading `cli` argument is accepted and dropped, so the same
command lines work against the `docker-cardano-node` image, where `cli` is
required.

Commands that do not talk to a node, such as key and address generation, only
need a directory for their input and output files:

```bash
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/work" -w /work \
  ghcr.io/blinklabs-io/cardano-cli \
  conway address key-gen \
  --verification-key-file payment.vkey \
  --signing-key-file payment.skey
```

### Talking to a node

Commands that query or submit to a node need the node's UNIX socket. The
socket is found through the `CARDANO_NODE_SOCKET_PATH` environment variable.
The entrypoint sets it when it is not already set:

| Condition | `CARDANO_NODE_SOCKET_PATH` |
|-----------|----------------------------|
| `NETWORK` is set, or a socket exists at `/ipc/node.socket` | `/ipc/node.socket` |
| otherwise | `/opt/cardano/ipc/socket` |

These match the defaults of the `docker-cardano-node` image, so a volume shared
with a node container is found without extra configuration. A value you set
yourself is never changed.

The `NETWORK` environment variable also selects the network, so commands do not
need `--mainnet` or `--testnet-magic`:

| `NETWORK` | Network ID used |
|-----------|-----------------|
| `mainnet` | mainnet |
| `preprod` | 1 |
| `preview` | 2 |
| `sanchonet` | 4 |
| `dijkstra` | 6 |

Any other value is ignored. If `CARDANO_NODE_NETWORK_ID` is set, it is used
instead, and a network option given on the command line overrides both.

With a node container started from `docker-cardano-node` that stores its socket
in the `node-ipc` volume:

```bash
docker run --rm \
  -e NETWORK=preprod \
  -v node-ipc:/ipc \
  ghcr.io/blinklabs-io/cardano-cli query tip
```

To use a node socket on the host, mount it at `/ipc/node.socket`:

```bash
docker run --rm \
  -e NETWORK=mainnet \
  -v /path/to/node.socket:/ipc/node.socket \
  ghcr.io/blinklabs-io/cardano-cli query tip
```

The same thing can be done with a shell alias:

```bash
alias cardano-cli="docker run --rm -ti \
  -e NETWORK=preprod \
  -v node-ipc:/ipc \
  ghcr.io/blinklabs-io/cardano-cli"
```

### Environment variables

| Variable | Description |
|----------|-------------|
| `NETWORK` | Named network (see above). Also makes `/ipc/node.socket` the default socket |
| `CARDANO_NODE_SOCKET_PATH` | Node socket path inside the container |
| `CARDANO_NODE_NETWORK_ID` | Network ID, `mainnet` or a network magic number. Overrides `NETWORK` |
| `DEBUG` | When set, the entrypoint scripts print each command as they run |

### Using it from cardano-up

[cardano-up](https://github.com/blinklabs-io/cardano-up) installs a
`cardano-cli` command that runs this image, with the host filesystem and the
context's node socket mounted.

## Building

```bash
docker build -t cardano-cli .
```

The first stage clones and compiles Cardano CLI, which takes a long time. The
version is the `CLI_VERSION` build argument:

```bash
docker build --build-arg CLI_VERSION=11.4.0.0 -t cardano-cli .
```

The final image keeps only the compiled binaries, their libraries and the
scripts in `bin/`: `entrypoint`, which is the image entrypoint, and `run-cli`,
which sets up the environment described above and runs `cardano-cli`.

## License

MIT. See [LICENSE](LICENSE).
