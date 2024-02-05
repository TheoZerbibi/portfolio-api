FROM alpine:3.19 as builder

RUN apk update && \
	apk add \
		curl \
		xz

ARG ZIGVER
RUN mkdir -p /deps
WORKDIR /deps
RUN curl https://ziglang.org/download/$ZIGVER/zig-linux-$(uname -m)-$ZIGVER.tar.xz -O && \
	tar xf zig-linux-$(uname -m)-$ZIGVER.tar.xz && \
	mv zig-linux-$(uname -m)-$ZIGVER/ local/

FROM alpine:3.19
RUN mkdir -p /home/app
WORKDIR /home/app
RUN apk --no-cache add \
		libc-dev \
		xz \
		samurai \
		git \
		cmake \
		perl-utils \
		jq \
		curl
# Install python framework along with its dependency packages 
RUN apk --no-cache add g++ make python3 py3-pip

# Create a virtual environment and install required packages
RUN python3 -m venv ~/pyvenv --system-site-packages && \
	~/pyvenv/bin/pip3 install s3cmd

COPY --from=builder /deps/local/ /deps/local/
