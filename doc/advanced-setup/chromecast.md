### Chromecast

Casting requires some extra steps to setup.

You need a [receiver app ID](https://developers.google.com/cast/docs/overview). Recommend starting with the receiver code at https://github.com/bcc-code/bccm-player-chromecast, as it includes support for [default languages](#configure-default-languages). That receiver is also available at this appId for testing: `519C9F80`.

## Android

1. Change your android FlutterActivity to be a FlutterFragmentActivity (required for the native chromecast views):

   ```diff
   // android/app/src/main/kotlin/your/bundle/name/MainActivity.kt
   - class MainActivity : FlutterActivity() {
   + class MainActivity : FlutterFragmentActivity() {
   ```

2. Add a values.xml with your own receiver id:

   ```
   <string name="cast_app_id">ABCD1234</string>
   ```

3. Update `NormalTheme` in your `styles.xml` to use an AppCompat theme and have a `colorPrimary`. This is a requirement from the Cast SDK.

   ```xml
   <style name="NormalTheme" parent="@style/Theme.AppCompat.Light.NoActionBar"> <!-- Change to use "AppCompat" -->
         <item name="android:windowBackground">?android:colorBackground</item> <!-- This was already there -->
         <item name="colorPrimary">#ffffffff</item> <!-- Added -->
   </style>
   ```

4. Update `NormalTheme` in your `night/styles.xml` too:

   ```xml
         <style name="NormalTheme" parent="@style/Theme.AppCompat.NoActionBar"> <!-- Note there's no "Light" -->
         <item name="android:windowBackground">?android:colorBackground</item>
         <item name="colorPrimary">#ffffffff</item>  <!-- Added -->
      </style>
   ```

## iOS

1. Follow the cast sdk documentation on how to add the "NSBonjourServices" and "NSLocalNetworkUsageDescription" plist values: [https://developers.google.com/cast/docs/ios_sender#ios_14](https://developers.google.com/cast/docs/ios_sender#ios_14)
2. Add your receiver id to your Info.plist:

   ```xml
      <key>cast_app_id</key>
      <string>ABCD1234</string>
   ```

3. Example Info.plist for step 4 and 5:

   ```xml
      <key>cast_app_id</key>
      <string>519C9F80</string>
      <key>NSLocalNetworkUsageDescription</key>
      <string>${PRODUCT_NAME} uses the local network to discover Cast-enabled devices on your WiFi
      network.</string>
      <key>NSBonjourServices</key>
      <array>
         <string>_519C9F80._googlecast._tcp</string>
         <string>_googlecast._tcp</string>
      </array>
   ```
