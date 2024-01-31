# grist-buildpack

Scalingo Grist buildpack

> This buildpack aims at installing a [Grist](https://getgrist.com) instance on [Scalingo](https://www.scalingo.com) and let you configure it at your convenance.

## Usage

[Add this buildpack environment variable][1] to your Scalingo application to install the `Grist` server:

```shell
BUILDPACK_URL=https://github.com/MTES-MCT/grist-buildpack
```

Default version Grist is `latest` found in github releases, but you can choose another one:

```shell
scalingo env-set GRIST_VERSION=1.1.10
```

Warning: container image could be big and build time long.

## Configuration

- Stateless: By default /persist docs are in /tmp folder which is lost at restart.

- Statefull: You should have an add-on database `postgresql`, an external S3 storage object (outside) and an OIDC server (e.g. [Keycloak-buildpack](https://github.com/MTES-MCT/keycloak-buildpack))

Environment variables are listed in [Grist repo](https://github.com/gristlabs/grist-core?tab=readme-ov-file#environment-variables)

## Hacking

Environment variables are set in a `.env` file. You copy the sample one:

```shell
cp docker/stateless/.env.sample .env
# or
cp docker/statefull/.env.sample .env
```

Run an interactive docker scalingo stack:

```shell
# stateless
docker run --name grist -it -p 8484:8484 -v "$(pwd)"/docker/stateless/.env:/env/.env -v "$(pwd)":/buildpack scalingo/scalingo-22:latest bash
# or statefull
docker run --name grist -it -p 8484:8484 -v "$(pwd)"/docker/statefull/.env:/env/.env -v "$(pwd)":/buildpack scalingo/scalingo-22:latest bash
```

And test in it:

```shell
bash buildpack/bin/detect
bash buildpack/lib/env.sh /env/.env /env
bash buildpack/bin/compile /build /cache /env
bash buildpack/bin/release
```

Run Grist server:

```shell
sh /build/grist/boot.sh # http://localhost:8484
```

You can also use docker-compose stack:

```shell
# stateless
docker-compose --env-file docker/stateless/.env -f docker/stateless/docker-compose.yml up --build -d
docker-compose --env-file docker/stateless/.env -f docker/stateless/docker-compose.yml down
# or statefull
docker-compose --env-file docker/statefull/.env -f docker/statefull/docker-compose.yml up --build -d
# You must create bucket in minio server, a user grist and its access key, set in .env then restart grist server
docker-compose --env-file docker/statefull/.env -f docker/statefull/docker-compose.yml down
```

[1]: https://doc.scalingo.com/platform/deployment/buildpacks/custom
