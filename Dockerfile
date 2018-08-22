FROM ubuntu:bionic as build

ARG VERSION=0.3.0

ARG PYTHON_MAJOR_VERSION=3
ARG PYTHON_MINOR_VERSION=6
ARG REQUIRED_PACKAGES="python${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_VERSION}-minimal libpython${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_VERSION}-minimal libpython${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_VERSION}-stdlib python${PYTHON_MAJOR_VERSION}-distutils"

ENV BUILD_DEBS /build/debs
ENV ROOTFS /build/rootfs
ENV DEBIAN_FRONTEND noninteractive

# Build pre-requisites
RUN bash -c 'mkdir -p ${BUILD_DEBS} ${ROOTFS}/{sbin,usr/local/bin}'

# Fix permissions
RUN chown -Rv 100:root $BUILD_DEBS

# Unpack required packges to rootfs
RUN apt-get update \
  && cd ${BUILD_DEBS} \
  && for pkg in $REQUIRED_PACKAGES; do \
       apt-get download $pkg \
         && apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances --no-pre-depends -i $pkg | grep '^[a-zA-Z0-9]' | xargs apt-get download ; \
     done
RUN if [ "x$(ls ${BUILD_DEBS}/)" = "x" ]; then \
      echo No required packages specified; \
    else \
      for pkg in ${BUILD_DEBS}/*.deb; do \
        echo Unpacking $pkg; \
        dpkg -x $pkg ${ROOTFS}; \
      done; \
    fi

RUN apt-get update \
      && apt-get install -yq python${PYTHON_MAJOR_VERSION}-pip \
      && pip${PYTHON_MAJOR_VERSION} install --upgrade --force-reinstall --root ${ROOTFS} cosh==${VERSION}

# /usr/bin/python${PYTHON_MAJOR_VERSION} => /usr/bin/python${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_VERSION} symlink
RUN ln -s python${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_VERSION} ${ROOTFS}/usr/bin/python${PYTHON_MAJOR_VERSION}

# Move /sbin out of the way
RUN mv ${ROOTFS}/sbin ${ROOTFS}/sbin.orig \
      && mkdir -p ${ROOTFS}/sbin \
      && for b in ${ROOTFS}/sbin.orig/*; do \
           echo 'cmd=$(basename ${BASH_SOURCE[0]}); exec /sbin.orig/$cmd "$@"' > ${ROOTFS}/sbin/$(basename $b); \
           chmod +x ${ROOTFS}/sbin/$(basename $b); \
         done

COPY entrypoint.sh ${ROOTFS}/usr/local/bin/entrypoint.sh
RUN chmod +x ${ROOTFS}/usr/local/bin/entrypoint.sh

FROM actions/bash:4.4.18-6
LABEL maintainer = "ilja+docker@bobkevic.com"

ARG ROOTFS=/build/rootfs

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

COPY --from=build ${ROOTFS} /

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]