# cosh
Docker actions: cosh

See https://github.com/i11/cosh

## Example

```bash
function cosh {
  docker_host_args='-e DOCKER_HOST'
  if [ -S /var/run/docker.sock ]; then
    docker_host_args="${docker_host_args} -v /var/run/docker.sock:/var/run/docker.sock"
  fi
  
  # TODO: handle $(pwd) == ${TMPDIR} || '/tmp' # for Darwin
  tmp_dir="${TMPDIR:-/tmp}"
  if [ "xDarwin" = "x$(uname)" ]; then
    tmp_dir='/tmp'
  fi
  tmp_args="-e TMPDIR=${tmp_dir} -v ${tmp_dir}:${tmp_dir}"
  mkdir -p $tmp_dir/cosh
  mkdir -p $tmp_dir/cosh/bin
  
  home_args="-e HOME -v ${HOME}:/container_user_home"
  if [ ! "x$(pwd)" = "x${HOME}" ]; then
    home_args="${home_args} -v ${HOME}:${HOME}"
  fi
  
  dev_args=''
  if [ ! "x$(pwd)" = "x/dev" ]; then
    dev_args='-v /dev:/dev'
  fi
  
  ssh_auth_sock_arg="-e SSH_AUTH_SOCK"
  if [ ! "x" = "x${SSH_AUTH_SOCK}" ]; then
    ssh_auth_sock_arg="${ssh_auth_sock_arg} -v ${SSH_AUTH_SOCK}:${SSH_AUTH_SOCK}"
  fi
 
  if [ ! -x "${tmp_dir}/cosh/docker/docker" ]; then
    # TODO: Do sha256sum verification
    docker run --net=host -it --rm  ${home_args} ${tmp_args} ${dev_args} -v $(pwd):$(pwd) -w $(pwd) actions/curl:latest -L -o $tmp_dir/cosh/docker.tgz https://download.docker.com/linux/static/stable/x86_64/docker-18.06.0-ce.tgz > /dev/null
    docker run --net=host -it --rm  ${home_args} ${tmp_args} ${dev_args} -v $(pwd):$(pwd) -w $(pwd) actions/gzip:latest -d $tmp_dir/cosh/docker.tgz
    docker run --net=host -it --rm  ${home_args} ${tmp_args} ${dev_args} -v $(pwd):$(pwd) -w $(pwd) actions/tar:latest fx $tmp_dir/cosh/docker.tar -C $tmp_dir/cosh
    rm -f $tmp_dir/cosh/docker.tgz
    echo -e '#!/bin/bash'"\n/usr/local/bin/cosh --tmpdir ${tmp_dir}/cosh.docker-credential-gcloud docker-credential-gcloud \"\$@\"" > $tmp_dir/cosh/bin/docker-credential-gcloud
    chmod +x $tmp_dir/cosh/bin/docker-credential-gcloud
    echo -e '#!/bin/bash'"\n/usr/local/bin/cosh --tmpdir ${tmp_dir}/cosh.gcloud gcloud \"\$@\"" > $tmp_dir/cosh/bin/gcloud
    chmod +x $tmp_dir/cosh/bin/gcloud
  fi

  test -t 0 && export USE_TTY="-t"
  docker run --net=host -i ${USE_TTY} --rm ${docker_host_args} ${home_args} ${tmp_args} ${dev_args} ${ssh_auth_sock_arg} -v $(pwd):$(pwd) -v ${tmp_dir}/cosh/docker/docker:/sbin/docker -v $tmp_dir/cosh/bin/docker-credential-gcloud:/sbin/docker-credential-gcloud -v $tmp_dir/cosh/bin/gcloud:/sbin/gcloud -w $(pwd) actions/cosh:latest "$@"
}

cosh java -- -version
```
