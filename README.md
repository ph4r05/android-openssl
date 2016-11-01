# Android build environment for OpenSSL

* Supports build for multiple architectures - ARM, ARMv7, X86
* Uses OpenSSL source codes
* Integrated with Android.mk build
* Contains pre-compiled OpenSSL 1.0.2j (use if you want or compile your own)

## How to compile

```bash
cd jni/openssl
./build.sh
```

Optionally, set variables on the beginning of the `build.sh` according to your Android NDK.

In the global JNI Android.mk you can then simply include Android.mk from openssl directory so the
static or dynamic libraries are linked to the rest of your project.

```
include jni/openssl/Android.mk
```

Include paths for header files are not set, headers will be after compilation present at

```
jni/openssl/sources/include
```

