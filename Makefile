ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES = YourAppBinaryName   # example: rtedsr

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = IDChanger
IDChanger_FILES = Tweak.xm
IDChanger_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
