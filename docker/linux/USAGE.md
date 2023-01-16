## Basic Usage

Build entire build-chain and generate the artifacts that Javet depends on

```bash
docker build -t javet-local --build-context gradle_javet_buildenv=docker/linux/base.Dockerfile -f docker/linux/base.Dockerfile .
```

Or obtain all v8/Node.js and Java dependencies in an image, ready to build Javet inside.

```bash
docker build -t localhost/javet_buildenv -f docker/linux/base.Dockerfile .
```

*By default will only target x86_64 architectures.*
To build for other architectures, add them to the `platform` flag. e.g. to build all supported by NodeJS:

```bash
docker build -t localhost/javet_buildenv --platform=linux/amd64,linux/arm,linux/arm64 -f docker/linux/base.Dockerfile .
```

##### ARM builds take much longer to build

## Build Image from Specific Stages

Base Image with build tools

```bash
docker build -t localhost/make_javet_buildenv --target make_javet_buildenv -f docker/linux/base.Dockerfile .
```

Base Node.JS build Image

```bash
docker build -t localhost/nodejs_javet_buildenv --target nodejs_javet_buildenv -f docker/linux/base.Dockerfile .
```

Base v8 build Image

```bash
docker build -t localhost/v8_javet_buildenv --target v8_javet_buildenv -f docker/linux/base.Dockerfile .
```

Base combined v8 and Node.js Image

```bash
docker build -t localhost/full_javet_buildenv --target full_javet_buildenv -f docker/linux/base.Dockerfile .
```

Final Image containing v8 and Node.js dependencies as well as Javet codebase and Java dependencies

```bash
docker build -t localhost/gradle_javet_buildenv --target gradle_javet_buildenv -f docker/linux/base.Dockerfile .
```
