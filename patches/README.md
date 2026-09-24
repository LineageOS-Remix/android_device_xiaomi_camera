# MiuiCamera patch maintenance

These patches preserve the compatibility edits used to produce the ready-to-use
APK in [vendor_xiaomi_camera](https://gitlab.com/johnmart19/vendor_xiaomi_camera).
ROM integrators consume that prebuilt; they do not need to apply these patches
or rebuild the APK. This document is for maintainers updating the camera.

## Origin and evidence

The adaptations were developed by inspecting the decoded MiuiCamera mod,
comparing relevant Alioth stock-camera/vendor behavior, and tracing failures
through application logs, Camera2 sessions and saved media. Fixes were expressed
as small smali diffs so the extraction tooling can carry them forward.

The mod APK is the app-side implementation baseline. Stock Alioth code and
Qualcomm reference code explain compatibility requirements; neither is an
interchangeable replacement for the mod. Obfuscated names and resource IDs are
specific to the decoded APK and must be resolved again when changing versions.

The current history groups the existing implementation into component commits;
those commits are not necessarily the original experiment dates. This inventory
explains what the actual patch files do. Historical rationale is identified below
where a fresh reproduction was not performed for this documentation update.

## Capability initialization and optional vendor features

### [camera-capabilities-cache.patch](camera-capabilities-cache.patch)

Removes repeated allocation of the capability `SparseArray` in the role-aware
and base camera adapters. Initialization already owns that allocation; replacing
it while populating/reading cameras discards previously collected entries.
The fix preserves the initialized cache rather than inventing missing camera
capabilities. It came from tracing capability-cache initialization and lifetime.

### [config-cache-thread-safety.patch](config-cache-thread-safety.patch)

Serializes ConfigManager load, save, read and write operations using its class
monitor, with exception-safe monitor release. The HEIF/gallery investigation
recorded concurrent configuration access and `ConcurrentModificationException`;
protecting the shared cache addresses the race instead of swallowing failures.
The renamed implementation methods are reached through locking wrappers.

### [optional-device-posture.patch](optional-device-posture.patch)

Uses the Settings.Global getter with a default of zero for `device_posture`.
A non-foldable AOSP device need not publish this setting. Missing optional state
should use the existing neutral value without printing a stack trace each time.

### [optional-dxo-metadata.patch](optional-dxo-metadata.patch)

Returns no parsed DXO result for null or empty input. Optional vendor metadata
is not guaranteed on every result; an absent payload must not be parsed as a
populated structure. This is input handling, not added DXO processing support.

### [optional-result-metadata.patch](optional-result-metadata.patch)

Handles null/empty scene metadata and rejects malformed record lengths through
the existing invalid-input branch. It also wraps face-result access: when face
detect mode exists but both score and rectangle arrays are absent, it returns
an empty face array. When either underlying array exists, normal framework
validation remains in place. The change avoids treating absent vendor results
as complete structures without globally suppressing metadata errors.

### [optional-role65.patch](optional-role65.patch)

Removes the misleading initialization warning for absent optional role `0x41`
(decimal 65), preserving the original missing-ID result. It neither creates a
camera nor redirects this role to another physical sensor.

### [optional-telephoto-roles.patch](optional-telephoto-roles.patch)

Likewise removes initialization-failure warnings for absent optional telephoto
and ultra-telephoto roles. Alioth does not need to expose every role queried by
the generic mod. Actual return values and exception handling are retained.

### [universal-settings-default.patch](universal-settings-default.patch)

Makes the `pref_universal_settings` checkbox use `bool/use_universal_settings`
instead of `bool/pref_false`. In the inspected APK these are resource IDs
`0x7f05006c` and `0x7f050067`, respectively. Both base values are currently false;
the important difference is honoring the dedicated configurable resource rather
than a generic constant. This is not a forced enable of Universal settings.

## Capture and camera selection

### [alioth-photo-size.patch](alioth-photo-size.patch)

Adds an Alioth `Q2()` feature override returning true. It is carried as the
photo-size adaptation. The retained patch and current feature accessor expose
only the obfuscated name `Q2`; do not infer a specific resolution or claim a new
sensor mode from this flag alone. Re-trace its consumers when rebasing to a new
APK. The exact original failure is not recoverable from this small diff alone.

### [alioth-native-pixel-mode.patch](alioth-native-pixel-mode.patch)

Selects session mode `0x80f5` instead of the legacy `0x80f3` branch for device
names starting with `alioth`. Historical stock/mod comparison identifies this
as adaptation of the mod's newer `supportAlgoUp`/native-pixel selection path.
It changes the chosen vendor mode; it does not manufacture a higher-resolution
sensor. Validate full-resolution capture again after a vendor or APK update.

### [alioth-logical-sat.patch](alioth-logical-sat.patch)

Enables the Alioth optical-zoom feature and bypasses its stale ConfigManager
cache value. This lets photo selection use the existing logical SAT path
instead of relying on the generic mod's incompatible default. The override is
based on the Alioth profile, which Aliothin inherits. It does not add a physical
telephoto camera; the logical camera combines existing physical sensors.

### [alioth-front-video-face-detection.patch](alioth-front-video-face-detection.patch)

Skips FaceDetectManager startup only for Alioth-family front normal-Video mode
(`0xa2`). The retained engineering rationale is vendor face-tracker memory
corruption during front-video setup. Rear capture and other modes keep their
original path. That crash was not independently reproduced during the September
23 rear-video tests; retain this distinction when describing validation.

### [alioth-front-video-stabilization.patch](alioth-front-video-stabilization.patch)

Disables the Vidhance/EIS eligibility path for the same Alioth front-video scope
and routes stabilization setup through the existing disabled branch, including
EIS/OIS off and no preview crop. It avoids requesting the incompatible front
stabilization pipeline. This is a compatibility restriction, not stabilization
support, and front video needs separate regression testing after updates.

## HEIF encoding, lifetime and thumbnails

These four patches were developed together during the Alioth HEIF investigation.
Historical device results established saved/openable HEIF files, correct colors
and working Google Photos thumbnails. They were not individually retested during
the latest rear-video session.

### [alioth-direct-heif-encoder.patch](alioth-direct-heif-encoder.patch)

Routes Alioth processed `YUV_420_888` images into the existing HeifSaveRequest
encoder path. The virtual-camera/composite HEIC reprocessing route rejected the
image type (`Cannot reprocess this type`). Reusing the app's direct encoder
avoids that incompatible HAL route rather than changing permissions or labeling
JPEG data as HEIF. Other image formats retain the original dispatch.

### [alioth-heif-lifecycle.patch](alioth-heif-lifecycle.patch)

Extends creation of the HEIF completion callback to Alioth so images are released
when encoding completes. Also selects a multi-buffer SurfaceTexture input queue
for Alioth: ImageWriter cannot attach to the previous single-buffer queue on
AOSP (`Set buffer count failed`). The callback and queue changes accompany the
direct encoder; changing dispatch alone was insufficient.

### [alioth-heif-planar-input.patch](alioth-heif-planar-input.patch)

Adds `AliothHeifPlanes.pack()` and routes Alioth image packing through it.
The helper accounts for image-plane row/pixel strides and converts the processed
YUV layout for the encoder. The historical paired JPEG/HEIF check initially
showed blue output: the Alioth MIVI path required U/V plane-order correction.
This also bypasses the old packing adjustment for the new Alioth buffer.
Do not generalize that chroma ordering to every device or every YUV producer.

### [alioth-heif-final-thumbnail.patch](alioth-heif-final-thumbnail.patch)

Publishes a thumbnail of the completed Alioth HEIF even if a provisional preview
was supplied. The temporary parallel thumbnail URI differed from the final saved
URI, leaving the camera thumbnail pointing at the wrong item. Completion, final
MediaStore visibility and thumbnail identity must agree.

## Gallery integration without MIUI Gallery

### [gallery-media-format-and-trash.patch](gallery-media-format-and-trash.patch)

Detects JPEG signature bytes in a nominal HEIF result and uses JPEG handling for
that actual payload. It also excludes pending/trashed MediaStore rows from
thumbnail selection and checks URI visibility before reopening media on Android
11+. This addresses mislabeled output and stale/deleted thumbnails; it does not
convert JPEG into HEIF or remove files from storage.

### [gallery-optional-binding.patch](gallery-optional-binding.patch)

Resolves the gallery service before binding and stores the real `bindService()`
return value. MIUI Gallery is optional on this ROM, so binding state cannot be
set to true unconditionally when its service is unavailable.

### [gallery-optional-mediastore.patch](gallery-optional-mediastore.patch)

When the MIUI Gallery package is absent, selects the existing camera-owned
MediaStore protocol (value 4). It avoids falling through to cached Gallery
version decisions or Gallery's scanner provider. This supports saving media
without requiring installation of the stock Gallery application.

## VideoSAT and supported video modes

### [alioth-video-sat.patch](alioth-video-sat.patch)

Enables VideoSAT in the Alioth profile and chooses role 60 (`0x3c`). The runtime
role mapping is logical camera 4 with physical members 0 and 2; generic role 62
was absent. DataItemFeature overrides prevent stale cached support=false or a
Universal role default from defeating the profile. Initial 1080p30 testing
verified real SAT master handoffs while logical camera 4 remained open.

### [alioth-video-sat-high-quality.patch](alioth-video-sat-high-quality.patch)

Allows Alioth quality strings `8` (4K30), `6,60` (1080p60) and `8,60` (4K60)
through the VideoSAT eligibility check. It also disables rear 4K EIS because
vendor crop margins were invalid. The EIS check reads the preference directly:
calling the higher-level quality helper there would recurse through `F4`/`Z9`.
Eligibility alone does not prove every physical lens supports the requested
resolution or frame rate; the two following corrections are required.

### [alioth-videosat60-session-mode.patch](alioth-videosat60-session-mode.patch)

Preserves the already selected non-EIS mode `0xf010` for Alioth/Aliothin logical
camera 4 when EIS is disabled. The later 60fps branch previously replaced it
with `0x803c`, undoing the effective stabilization decision. Device evidence
showed request stabilization OFF but result ON, repeated EIS-margin/CHIEISV3
errors and striped main-camera 4K60 output. The corrected path produced clean
main-camera 4K30/60 recordings. Other device/camera/EIS combinations retain their
original session selection.

### [alioth-ultrawide-video-limits.patch](alioth-ultrawide-video-limits.patch)

Prevents sub-1x selection in normal Alioth/Aliothin 4K Video mode. It filters
zoom stops, clamps the shared zoom range and handles a stale toolbar index when
changing resolution from 0.6x. The installed IMX355 advertises a 3280-pixel
maximum width; selecting it in the current 3840-pixel pipeline caused
`DSX_ProcessNcLib` error 67108866, DSX10 calculation failure and invalid MNDS
output for DS16, followed by pipeline recovery.

This fixes a selectable broken mode; it does **not** implement ultrawide 4K.
An intermediate guard exposed an `Illegal zoom ratio: 0.6` toolbar exception;
the final index clamp was added and both quality transitions were rerun.

September 23 final-device checks:

- Main 4K30/60 clips decoded as H.264/AAC at about 30.03/60.04 fps.
- Ultrawide 1080p30 clips decoded at about 30.05 fps.
- Changing from 1080p ultrawide to either 4K mode safely restored 1x, without
  crashes or DSX10/MNDS errors in those transition logs.
- Ultrawide with the UI set to 1080p60 still measured about 30.05 fps in the
  test scene. True ultrawide 60fps remains unverified.

Tests used a temporary Magisk system-path APK mount, not a ROM rebuild. Other
camera features and long-duration recording were outside that test scope.

## Updating the patches

1. Identify the exact new input APK and retain an untouched copy/hash. Decode it
   with a compatible apktool version. Do not use the already patched GitLab APK
   as an unmodified input and blindly reapply the full patch set.
2. Inspect changed methods, vendor tags and resource names. Port the behavioral
   checks, not old line numbers or obfuscated names by assumption. Keep device,
   lens and mode guards as narrow as the corresponding failure requires.
3. Exercise the extraction hook in [extract-files.py](../extract-files.py):
   `blob_fixup().apktool_patch('patches')`. The current extract-utils implementation
   selects only filenames ending in `.patch` and sorts them lexicographically.
   This README is ignored. Several diffs touch the same methods; verify the whole
   ordered series against the intended input, not only each patch in isolation.
4. Inspect the resulting DEX/resource changes, assemble the APK and align it:

   ```sh
   apktool b decoded -o MiuiCamera-unaligned.apk
   zipalign -P 16 4 MiuiCamera-unaligned.apk MiuiCamera.apk
   zipalign -c -P 16 4 MiuiCamera.apk
   ```

   Use a zipalign version supporting `-P 16`. ROM packaging owns platform
   signing; alignment is not signature verification or a successful install.
5. Reproduce the original failure and test adjacent modes on-device. Inspect
   saved file dimensions, timestamps/frame rate, audio and decoded frames.
   A preview, an FPS label, or a successful encoder start is insufficient.
6. Commit the updated patch and matching prebuilt to their respective device
   and GitLab vendor repositories. Record exact hashes and verified results in
   the project knowledge store. Keep the root README focused on integration.

Do not remove a guard merely because the UI offers a mode. Prove the vendor
pipeline works first. Do not change ROM build variants or run a full ROM build
as part of routine patch documentation or APK-only testing.
