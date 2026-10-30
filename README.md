# Recko Restaurant – Customer Feedback (Kattuwa, Negombo)

Customer scans the QR code -> opens this page -> picks:
- Great experience -> goes to the Google review page for Recko Restaurant
- Bad experience   -> short form, sent to 0774109038 via WhatsApp or SMS

## Setup
1. Edit `lib/config.dart` (Google review link, hosted URL).
2. `flutter pub get`
3. Test: `flutter run -d chrome`
4. Publish the web version: `flutter build web --release`
   then upload the `build/web` folder to Netlify / Firebase Hosting / GitHub Pages.
5. Put the hosted address into `hostedAppUrl`, run the app, long-press the
   "Recko Restaurant" title to open the QR screen, and print the QR code.
