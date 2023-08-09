# Installation

- Package: [https://pub.dev/packages/bccm_player](https://pub.dev/packages/bccm_player)

- Github: [https://github.com/bcc-code/bccm-player](https://github.com/bcc-code/bccm-player)

---

1. Add the dependency

   ```bash
   flutter pub add bccm_player
   ```

2. (Android) For native fullscreen and picture-in-picture to work correctly, you need to override these 2 methods on your MainActivity:

   ```kotlin
   class MainActivity : FlutterFragmentActivity() {
       @SuppressLint("MissingSuperCall")
       override fun onPictureInPictureModeChanged(
           isInPictureInPictureMode: Boolean,
           newConfig: Configuration?
       ) {
           super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
           // This is important for PiP to behave correctly (e.g. pause video when exiting PiP).
           val bccmPlayer =
               flutterEngine?.plugins?.get(BccmPlayerPlugin::class.javaObjectType) as BccmPlayerPlugin?
           bccmPlayer?.handleOnPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
       }

       override fun onBackPressed() {
           // This makes the back button work correctly in the native fullscreen player.
           // Returns true if the event was handled.
           if (!BccmPlayerPlugin.handleOnBackPressed(this)) {
               super.onBackPressed()
           }
       }
   }
   ```

3. (Android) Add `supportsPictureInPicture="true"` to your AndroidManifest for MainActivity:

```xml
        <activity
            android:name=".MainActivity"
            android:supportsPictureInPicture="true"
            ...
```

4. For chromecast support, you need to do a few more things, check out the "Chromecast" docs.
