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
  tmp_dir="${TMPDIR}"
  if [ "xDarwin" = "x$(uname)" ]; then
    tmp_dir='/tmp'
  fi
  tmp_args="-e TMPDIR=${tmp_dir} -v ${tmp_dir}:${tmp_dir}"
  
  home_args="-e HOME -v ${HOME}:/home"
  if [ ! "x$(pwd)" = "x${HOME}" ]; then
    home_args="${home_args} -v ${HOME}:${HOME}"
  fi
  
  dev_args=''
  if [ ! "x$(pwd)" = "x/dev" ]; then
    dev_args='-v /dev:/dev'
  fi
 
  if [ ! -x "${tmp_dir}/docker/docker" ]; then
    # TODO: Do sha256sum verification
    docker run --net=host -it --rm  ${home_args} ${tmp_args} ${dev_args} -v $(pwd):$(pwd) -w $(pwd) actions/curl:latest -L -o $tmp_dir/docker.tgz https://download.docker.com/linux/static/stable/x86_64/docker-18.06.0-ce.tgz > /dev/null
    docker run --net=host -it --rm  ${home_args} ${tmp_args} ${dev_args} -v $(pwd):$(pwd) -w $(pwd) actions/gzip:latest -d $tmp_dir/docker.tgz
    docker run --net=host -it --rm  ${home_args} ${tmp_args} ${dev_args} -v $(pwd):$(pwd) -w $(pwd) actions/tar:latest fx $tmp_dir/docker.tar -C $tmp_dir
  fi

  docker run --net=host -it --rm ${docker_host_args} ${home_args} ${tmp_args} ${dev_args} -v $(pwd):$(pwd) -v ${tmp_dir}/docker/docker:/sbin/docker -w $(pwd) actions/cosh:latest "$@"
}

cosh java -- -version
```
