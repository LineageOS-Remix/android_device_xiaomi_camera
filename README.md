# Xiaomi Camera for POCO F3 (alioth)

![POCO F3 (alioth) — Xiaomi Camera](assets/poco-f3-xiaomi-camera.webp)

Device-side integration and compatibility layer for Xiaomi Camera on the
**POCO F3 / Redmi K40 / Mi 11X (alioth)** family, with the corresponding
`aliothin` device-feature configuration.

This repository is intended to live at:

```text
device/xiaomi/camera
```

The ready-to-use camera APK and required proprietary libraries are provided by
the companion [GitLab repository](https://gitlab.com/johnmart19/vendor_xiaomi_camera).
Clone both repositories to integrate Xiaomi Camera into the ROM.

## What this repository owns

The camera integration is intentionally kept here rather than spread across
the device-common tree. It currently provides:

- Xiaomi Camera permissions, default permissions and sysconfig entries
- CamX override settings
- alioth / aliothin device-feature configuration
- Camera SELinux policy
- Camera compatibility shims and vendor-library symlinks
- `MiuiCameraOverlay`
- Camera-related system and vendor properties

## Integration

### 1. Clone the device-side camera integration

```bash
git clone https://github.com/PocoF3Releases/device_xiaomi_camera.git -b aosp-17 device/xiaomi/camera
```

### 2. Clone the companion proprietary vendor repository

```bash
git clone https://gitlab.com/johnmart19/vendor_xiaomi_camera.git -b aosp-17 vendor/xiaomi/camera
```

The vendor repository uses Git LFS. Ensure its prebuilt files are downloaded:

```bash
git -C vendor/xiaomi/camera lfs pull
```

### 3. Include Xiaomi Camera from the device tree

Add the following to the device `device.mk`:

```makefile
# Miui Camera
include device/xiaomi/camera/miuicamera.mk
```

That include brings in the camera packages, overlays, properties, SELinux
directories maintained by this repository.

## Compatibility ownership

The mod stores watermarks in app-private storage; it does not require MiSys.

Legacy DisplayConfig compatibility is owned by the sm8250 display HAL. The
display composer publishes a real `vendor.display.config@1.9/default`
compatibility endpoint alongside its native 2.0 service for the proprietary
alioth CamX client, so this camera tree does not carry a DisplayConfig VINTF
matrix or pretend that a compatibility matrix provides the runtime service.

## Repository layout

```text
configs/      Camera configs, permissions, device features and VINTF fragments
rro_overlays/ Xiaomi Camera resource overlays
sepolicy/     Camera SELinux policy
shims/        Compatibility shims
miuicamera.mk Main product integration entry point
```

## Companion repository

[Ready-to-use APK and proprietary libraries on GitLab](https://gitlab.com/johnmart19/vendor_xiaomi_camera)
— use the matching `aosp-17` branch.
