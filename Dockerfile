FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ser2net && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -r -M -d /usr/share/ser2net -G dialout ser2net

RUN mkdir /ser2netconfig && chown ser2net /ser2netconfig && chmod 755 /ser2netconfig
USER ser2net

EXPOSE 20108

# Hacky way to recover the value of UDEV_DEVNODE_RANDOMSUFFIX env var
# and generate a config file at runtime
CMD export ADAPTER=$(env | awk -F= '/^UDEV_DEVNODE/ {print $2;exit;}') \
 && echo "\
connection: &con01\n\
  accepter: tcp,20108\n\
  connector: serialdev,$ADAPTER,115200n81,nobreak,local\n\
  options:\n\
    kickolduser: true\
" > /ser2netconfig/config.yaml \
 && echo -n "Starting " && ser2net -v && ser2net -d -c /ser2netconfig/config.yaml
