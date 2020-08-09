FROM centos:7

# Start as root
USER root

RUN yum install -y --nogpgcheck deltarpm epel-release
RUN yum install -y --nogpgcheck git sudo which wget make cmake python3 \ 
    jansson-devel openssl-devel libsrtp-devel sofia-sip-devel \ 
    glib2-devel opus-devel libogg-devel libcurl-devel pkgconfig \ 
    gengetopt libconfig-devel libtool autoconf automake

RUN useradd janus -d /home/janus && \
    usermod -aG wheel janus

# for libnice
RUN pip3 install -U meson ninja && \
    ln -s /usr/local/bin/ninja /usr/bin/ninja

RUN mkdir /home/janus/Downloads && cd "$_"
WORKDIR /home/janus/Downloads

RUN wget https://mirror.koddos.net/gnu/libmicrohttpd/libmicrohttpd-0.9.71.tar.gz && \
    tar xf libmicrohttpd-0.9.71.tar.gz && rm libmicrohttpd-0.9.71.tar.gz && cd libmicrohttpd-0.9.71/ && \
    ./configure --libdir=/lib64 --prefix=/usr && make install && ldconfig && \
    cd .. && rm -rf libmicrohttpd-0.9.71/

RUN git clone https://gitlab.freedesktop.org/libnice/libnice.git && \
    cd libnice/ && \
    meson --prefix=/usr build && ninja -C build && ninja -C build install && ldconfig && \
    cd .. && rm -rf libnice/

RUN git clone https://libwebsockets.org/repo/libwebsockets && \
    cd libwebsockets/ && mkdir build && cd build/ && \
    cmake -DLWS_MAX_SMP=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. && \
    make && make install && ldconfig && \
    cd ../.. && rm -rf libwebsockets/

RUN git clone https://github.com/sctplab/usrsctp && \
    cd usrsctp && \
    ./bootstrap && ./configure --libdir=/lib64 --prefix=/usr && \
    make && make install && ldconfig && \
    cd .. && rm -rf usrsctp/

RUN wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz && \
    tar xf v2.2.0.tar.gz && rm v2.2.0.tar.gz && cd libsrtp-2.2.0/ && \
    ./configure --libdir=/lib64 --prefix=/usr --enable-openssl && \
    make shared_library && make install && ldconfig && \
    cd .. && rm -rf libsrtp-2.2.0/

RUN git clone https://github.com/meetecho/janus-gateway.git && \
    cd janus-gateway/ && sh autogen.sh && \
    ./configure --prefix=/opt/janus && \
    make && make install && \ 
    cd .. 

COPY ./config /opt/janus/etc/janus
RUN chown -R janus:janus /opt/janus/

USER janus
WORKDIR /opt/janus/etc/

CMD ["/opt/janus/bin/janus"]

EXPOSE 7088 7188 7889 7989 8088 8089 8188 8989