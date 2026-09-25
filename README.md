# MIUI Camera for Xiaomi Pad 6 (pipa)

Device-side integration and compatibility layer for Xiaomi Camera on the
**Xiaomi Pad 6 (pipa)**.

Lives at:
```text
device/xiaomi/camera
```

Proprietary APK and libraries are provided by the companion
[GitLab repo](https://gitlab.com/CuriousNom/xiaomi-camera.git) (branch `aosp-17`).

## What this provides

- Xiaomi Camera permissions, default permissions, sysconfig entries
- CamX override settings
- pipa device-feature configuration
- Camera SELinux policy
- Camera compatibility shims and vendor-library symlinks
- `MiuiCameraOverlay`
- Camera-related system/vendor properties

## Integration

```bash
git clone https://github.com/CuriousNom/device_xiaomi_camera.git -b aosp-17 device/xiaomi/camera
git clone https://gitlab.com/CuriousNom/xiaomi-camera.git -b aosp-17 vendor/xiaomi/camera
git -C vendor/xiaomi/camera lfs pull
```

Add to `device.mk`:

```makefile
# Miui Camera
include device/xiaomi/camera/miuicamera.mk
```

## Compatibility notes

Watermarks are stored in app-private storage; MiSys is not required.

DisplayConfig compatibility is owned by the sm8250 display HAL — this tree
does not carry a DisplayConfig VINTF matrix.

## Layout

```text
configs/      Camera configs, permissions, device features, VINTF fragments
rro_overlays/ Xiaomi Camera resource overlays
sepolicy/     Camera SELinux policy
shims/        Compatibility shims
miuicamera.mk Main product integration entry point
```
