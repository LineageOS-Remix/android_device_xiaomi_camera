#
# Copyright (C) 2024 VoidUI Project
#
# SPDX-License-Identifier: Apache-2.0
#

CAMERA_PATH := device/xiaomi/camera
CAMERA_VENDOR_PATH := vendor/xiaomi/camera

TARGET_USES_MIUI_CAMERA := true
TARGET_INCLUDES_MIUI_CAMERA := true

# Permissions
PRODUCT_COPY_FILES += \
     $(call find-copy-subdir-files,*,$(CAMERA_PATH)/configs/permissions/default-permissions/,$(TARGET_COPY_OUT_SYSTEM)/etc/default-permissions) \
     $(call find-copy-subdir-files,*,$(CAMERA_PATH)/configs/permissions/permissions/,$(TARGET_COPY_OUT_SYSTEM)/etc/permissions) \
     $(call find-copy-subdir-files,*,$(CAMERA_PATH)/configs/permissions/sysconfig/,$(TARGET_COPY_OUT_SYSTEM)/etc/sysconfig)

# ExtraPhoto
PRODUCT_COPY_FILES += \
    $(CAMERA_PATH)/configs/permissions/product/privapp-permissions-extraphoto.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/privapp-permissions-extraphoto.xml \
    $(CAMERA_PATH)/configs/permissions/system_ext/gson.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/gson.xml

# CameraX Config Overwrite
PRODUCT_COPY_FILES += \
     $(CAMERA_PATH)/configs/camera/camxoverridesettings.txt:$(TARGET_COPY_OUT_VENDOR)/etc/camera/camxoverridesettings.txt

# Device-Features
PRODUCT_COPY_FILES += \
     $(CAMERA_PATH)/configs/device_features/alioth.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/device_features/alioth.xml \
     $(CAMERA_PATH)/configs/device_features/aliothin.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/device_features/aliothin.xml

# Shims
PRODUCT_PACKAGES += \
    libgui_camera_shim

# MiuiCamera JNI compatibility
PRODUCT_PACKAGES += \
    libcamera_jpegutil_jni.xiaomi \
    miui_camera_libcamera_algoup_symlink \
    miui_camera_libcamera_jpegutil_symlink \
    miui_camera_libcamera_mianode_symlink

# Properties
PRODUCT_SYSTEM_PROPERTIES += \
    ro.com.google.lens.oem_camera_package=com.android.camera \
    ro.miui.notch=1 \
    persist.sys.cam.skip_detach_image=true

# Logging
PRODUCT_SYSTEM_PROPERTIES += \
   log.tag.CHIUSECASE=ERROR

PRODUCT_VENDOR_PROPERTIES += \
   persist.vendor.camera.logInfoMask=0 \
   persist.vendor.camera.privapp.list=com.android.camera

# Sepolicy Camera
BOARD_VENDOR_SEPOLICY_DIRS += \
    $(CAMERA_PATH)/sepolicy/camera/vendor

# Android 17 splits legacy platform apps into platform_app_36. Older
# policy trees use platform_app. Keep the seapp domain and allow rules aligned.
ifneq ($(wildcard system/sepolicy/private/platform_app_36.te),)
BOARD_SEPOLICY_M4DEFS += miui_camera_platform_domain=platform_app_36
else
BOARD_SEPOLICY_M4DEFS += miui_camera_platform_domain=platform_app
endif

SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += \
    $(CAMERA_PATH)/sepolicy/camera/private

# Qualcomm Gralloc
PRODUCT_PACKAGES += \
     gralloc.qcom

# RRO Overlays
PRODUCT_PACKAGES += \
    MiuiCameraOverlay

# VINTF
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    $(CAMERA_PATH)/configs/vintf/camera_framework_compatibility_matrix.xml \

$(call inherit-product, $(CAMERA_VENDOR_PATH)/camera-vendor.mk)
