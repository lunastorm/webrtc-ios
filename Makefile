.SECONDARY:
.SECONDEXPANSION:
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

LIBVPX_TARGET_NAME_x86_64 = x86_64-iphonesimulator-gcc
LIBVPX_TARGET_NAME_i386   = x86-iphonesimulator-gcc
LIBVPX_TARGET_NAME_armv7  = armv7-darwin-gcc
LIBVPX_TARGET_NAME_arm64  = arm64-darwin-gcc

SUBARCH_x86 = i386 x86_64
SUBARCH_arm = armv7 arm64
ARCHS = x86 arm

build/libvpx.%.a: $$(addsuffix .a,$$(addprefix build/libvpxsub-,$$(SUBARCH_%)))
	libtool -static -o $@ $^

build/libvpx: |build
	cd build; git clone https://chromium.googlesource.com/webm/libvpx

build:
	mkdir -p $@

build/libvpx-%: |build/libvpx
	cp -r $| $@

build/libvpxsub-%.a: /usr/local/bin/yasm |build/libvpx-%
	$(eval LIBVPX_TARGET_NAME = $(LIBVPX_TARGET_NAME_$*))
	cd $| ; make clean ; ./configure --as=yasm --target=$(LIBVPX_TARGET_NAME) && env PATH=/usr/local/bin:$$PATH make -j$(shell sysctl -n hw.ncpu)
	mv $|/libvpx.a $@

build/libwebrtc.a: $$(patsubst %,build/libwebrtc-%-min.a,$$(ARCHS))
	lipo -create $^ -output $@

build/libwebrtc-%-min.a: build/libwebrtc-%-g.a
	strip -S -x -o $@ -r $^

RELEASE_DIR_x86 = build/webrtc-x86/Release-iphonesimulator
RELEASE_DIR_arm = build/webrtc-arm/Release-iphoneos

build/libwebrtc-%-g.a: $$(RELEASE_DIR_%) build/libvpx.%.a
	ninja -C $< AppRTCDemo || true
	cp -f $(word 2,$^) $</libvpx.a
	ninja -C $< AppRTCDemo
	libtool -static -o $@ $</lib*.a

GYP_DEFINES_x86 = target_arch=ia32 build_neon=0
GYP_DEFINES_arm = target_arch=arm64 build_neon=1

build/webrtc-%: |build/webrtc
	$(eval ARCH = $(subst /,,$(dir $*)))
	cd $| && lockfile -1 gclient.lock && trap "rm -f gclient.lock" EXIT && env GYP_GENERATORS="ninja" GYP_DEFINES="build_with_libjingle=1 build_with_chromium=0 libjingle_objc=1 OS=ios target_subarch=both $(GYP_DEFINES_$(ARCH))" GYP_GENERATOR_FLAGS="output_dir=../../webrtc-$(ARCH)" GYP_CROSSCOMPILE=1 gclient runhooks

build/webrtc: |build/depot_tools
	mkdir -p $@
	cd $@; gclient config --name src http://webrtc.googlecode.com/svn/trunk
	echo "target_os = ['ios', 'mac']" >> $@/.gclient
	cd $@; gclient sync --force
	# disable gen_asm_offset target in libvpx to prevent build error
	# libvpx is then replaced with our own built ones
	# remove this and libvpx when libvpx in chromium is updated to remove asm offset
	patch -N -p1 -d $@/src/chromium/src/third_party/libvpx < libvpx.diff || true

build/depot_tools: |build
	cd build; git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

/usr/local/bin/yasm:
	brew install yasm

.PHONY:
clean:
	rm -rf WebRTC.framework
	rm -rf build
