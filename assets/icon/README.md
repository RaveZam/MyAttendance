# App Icon Setup Instructions

## How to Update Your App Logo

1. **Prepare your icon image:**

   - Create a square image (1024x1024 pixels recommended)
   - Use PNG format with transparent background (if needed)
   - Ensure the icon looks good at small sizes (it will be scaled down)

2. **Place your icon:**

   - Save your icon image as `icon.png` in this directory (`assets/icon/icon.png`)
   - The file should be named exactly `icon.png`

3. **Generate the icons:**

   ```bash
   flutter pub get
   dart run flutter_launcher_icons
   ```

4. **Verify:**
   - The command will automatically generate all required icon sizes for:
     - Android (all density folders)
     - iOS (all required sizes)
     - Web (192x192 and 512x512)
   - You may need to rebuild your app to see the changes

## Notes

- The icon will be automatically resized for all platforms
- For Android adaptive icons, the background color is set to white (#ffffff) - you can change this in `pubspec.yaml`
- For best results, use a square image with your logo centered and some padding around the edges
