## Building WebRTC

---

### Setup:

- `sudo python ~/react-native-webrtc/tools/build-webrtc.py --setup --android ~/src/`

Time to setup: ~30min [@ Amazon's EC2 c5n.2xlarge]

### Build (debug):

- `sudo python ~/react-native-webrtc/tools/build-webrtc.py --build --android --debug ~/src/`

Time to build: ~15min [@ Amazon's EC2 c5n.2xlarge]

### Build (release):

- `sudo python ~/react-native-webrtc/tools/build-webrtc.py --build --android ~/src/`

Time to build: ~18min [@ Amazon's EC2 c5n.2xlarge]

### Useful commands:

### Zip webrtc sources only

```
sudo zip -r webrtc.zip webrtc/ -x webrtc/android/src/third_party/**\* webrtc/android/src/tools/**\* webrtc/android/.cipd/pkgs/**\* webrtc/android/src/.git/**\* webrtc/android/src/base/.git/**\* webrtc/android/src/buildtools/third_party/**\* webrtc/android/src/build/**\* webrtc/android/src/examples/**\* webrtc/android/src/	resources/**\*
```

### Zip examples:

```bash
sudo zip -r examples_source.zip examples/ -x examples/androidtests/third_party/**\*
```

### Extract modified webrtc:

```bash
sudo unzip android.zip -d webrtc/; sudo chmod -R +x webrtc/
```

### Extract modified examples:

```bash
sudo unzip examples.zip -d webrtc/android/src; sudo chmod -R +x webrtc/android/src/examples
```

### Zip compiled libs:

```bash
sudo rm -Rf libs.zip; sudo zip -r libs.zip ~/src/build_webrtc/build/android/*
```

### Update build tool code:

```bash
sudo nano ~/react-native-webrtc/tools/build-webrtc.py
```
