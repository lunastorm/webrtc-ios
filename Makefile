PATH := $(PWD)/build/depot_tools:$(PATH)
SHELL := /bin/bash

all: WebRTC.framework

WebRTC.framework: build/libwebrtc.a
	mkdir -p $@/Versions/A/Headers
	cp -rf build/webrtc/src/talk/app/webrtc/objc/public/* $@/Versions/A/Headers
	cp -f $^ $@/Versions/A/WebRTC
	ln -s Versions/A/Headers $@/Headers
	ln -s Versions/A/WebRTC $@/WebRTC
	ln -s Versions/A $@/Versions/Current
	@echo -e "\nWebRTC.framework is built successfully\n"

.INTERMEDIATE: build/libwebrtc-unstrip.a build/libwebrtc.a
build/libwebrtc-unstrip.a: build/webrtc/src/talk/build/build_ios_libs.sh
	$^
	libtool -static -o $@ build/webrtc/src/out_ios_libs/fat/*.a

build/libwebrtc.a: build/libwebrtc-unstrip.a
	strip -S -x -o $@ -r $^

build/webrtc/src/talk/build/build_ios_libs.sh: |build/depot_tools
	mkdir -p build/webrtc
	cd build/webrtc; env GYP_DEFINES="OS=ios" fetch webrtc_ios

build:
	mkdir -p $@

build/depot_tools: |build
	cd build; git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

.PHONY:
clean:
	rm -rf WebRTC.framework
	rm -rf build
