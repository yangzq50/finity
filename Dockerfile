FROM ubuntu:23.10

RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.tuna.tsinghua.edu.cn@g' /etc/apt/sources.list
RUN apt update -y

# Clang 17+ is required for C++20 modules. GCC is not supported.
RUN echo "hello"
RUN apt install -y clang-*-17
RUN ln -s /usr/bin/clang-scan-deps-17 /usr/bin/clang-scan-deps && ln -s /usr/bin/clang-format-17 /usr/bin/clang-format && ln -s /usr/bin/clang-tidy-17 /usr/bin/clang-tidy && ln -s /usr/bin/llvm-symbolizer-17 /usr/bin/llvm-symbolizer

ENV CC=/usr/bin/clang-17
ENV CXX=/usr/bin/clang++-17

# tools
RUN apt install -y wget curl emacs-nox vim git build-essential ninja-build bison flex thrift-compiler postgresql-client python3-full tree rpm

# rust, refers to https://rsproxy.cn/
ENV RUSTUP_DIST_SERVER="https://rsproxy.cn"
ENV RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
ENV PATH=/root/.cargo/bin:$PATH
RUN wget -O rustup-init.sh https://rsproxy.cn/rustup-init.sh && sh rustup-init.sh -y
RUN mkdir -vp $HOME/.cargo && echo "[source.crates-io]" >> $HOME/.cargo/config \
    && echo "replace-with = 'rsproxy-sparse'" >> $HOME/.cargo/config \
    && echo "[source.rsproxy]" >> $HOME/.cargo/config \
    && echo "registry = 'https://rsproxy.cn/index/'" >> $HOME/.cargo/config \
    && echo "[source.rsproxy-sparse]" >> $HOME/.cargo/config \
    && echo "registry = 'sparse+https://rsproxy.cn/index/'" >> $HOME/.cargo/config \
    && echo "[registries.rsproxy]" >> $HOME/.cargo/config \
    && echo "index = 'https://rsproxy.cn/crates.io-index'" >> $HOME/.cargo/config \
	&& echo "[net]" >> $HOME/.cargo/config \
	&& echo "git-fetch-with-cli = true" >> $HOME/.cargo/config

# sqllogictest
RUN cargo install sqllogictest-bin

# CMake 3.28+ is requrired for C++20 modules.
# download https://github.com/Kitware/CMake/releases/download/v3.28.1/cmake-3.28.1-linux-x86_64.tar.gz
COPY cmake-3.28.1-linux-x86_64.tar.gz .
RUN tar xzf cmake-3.28.1-linux-x86_64.tar.gz && cp -rf cmake-3.28.1-linux-x86_64/bin/* /usr/local/bin && cp -rf cmake-3.28.1-linux-x86_64/share/* /usr/local/share && rm -fr cmake-3.28.1-linux-x86_64

# build dependencies
RUN apt install -y liblz4-dev libboost1.81-dev liburing-dev libgflags-dev libevent-dev libthrift-dev

# Create a python virtual environment. Set PATH so that the shell activate this virtual environment automatically when entering a container from this image.
RUN python3 -m venv /usr/local/venv
ENV PATH="/usr/local/venv/bin:$PATH"

# infinity python SDK dependencies
COPY python/requirements.txt .
RUN pip3 install --no-input -r requirements.txt --index-url https://pypi.tuna.tsinghua.edu.cn/simple/ --trusted-host pypi.tuna.tsinghua.edu.cn

ENTRYPOINT [ "bash", "-c", "while true; do sleep 60; done"]
