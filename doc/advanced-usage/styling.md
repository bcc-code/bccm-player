### Styling / theming

#### Theme

You can set a theme to customize some colors and text, similarly to how you set a Material theme.
Wrap with BccmPlayerTheme somewhere high in the hierarchy.

Example:

```dart
BccmPlayerTheme(
    playerTheme: BccmPlayerThemeData(
        controls: BccmControlsThemeData(
            primaryColor: Colors.lightGreen,
            durationTextStyle: const TextStyle(color: Colors.green),
        ),
    ),
    child: BccmPlayerView(BccmPlayerController.primary),
)
```
