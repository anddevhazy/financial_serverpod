# Fine Man

A budget ledger in naira. Each table splits spending into five columns (Need, Work, Want, Luxury, Tithe), with sub-entries, a single reorderable list of entries, free-form notes with images, and JSON backups.

This is the Flutter and Serverpod rebuild of the Firebase version of the app.

| Folder | What it is |
| --- | --- |
| `fine_man_flutter` | The app. It's built for the web; backups and note images aren't implemented on other platforms. |
| `fine_man_server` | The Serverpod server and its PostgreSQL schema. |
| `fine_man_client` | Generated code that connects the two. Don't edit it. |

## Run it

The project pins Flutter 3.47.7 in `.fvmrc`, and needs the Serverpod CLI 4.0.4. No Docker is needed: the server runs its own embedded PostgreSQL in development and tests.

```sh
fvm install
export PATH="$PWD/.fvm/flutter_sdk/bin:$PATH"
dart pub get
serverpod start
```

`serverpod start` applies migrations, starts the server on port 8080 and launches the app. Sign-up codes are printed in its terminal during development.

To run without a server or accounts, keeping tables in the browser only:

```sh
cd fine_man_flutter
flutter run -d chrome --dart-define=LOCAL_MODE=true
```

## Test it

```sh
cd fine_man_server && dart test
cd fine_man_flutter && flutter test
```

## Move data from the Firebase version

Backup files use the same format as before:

1. In the old app, open the menu on the tables page and choose **Export backup**.
2. In this app, sign in, open the same menu and choose **Import backup**.

Tables keep their ids and creation dates. Images already in notes stay on Cloudinary and keep working, so don't delete that Cloudinary account until they've been re-uploaded. Firebase accounts don't carry over, so each user signs up again with an email and password.

## How it works

**Tables** are rows in `stored_table`, one per table per user, with entries, notes and list order held in JSON columns because they always load and save together. Every query is scoped to the signed-in user.

**Sync** is handled by `ServerLedgerRepository`, which replaces what Firestore did on its own:

- A single event stream (`ledger.events`) sends a snapshot of the user's tables, then every change, and reconnects whenever it drops.
- Changes show immediately. They're sent one at a time, in order, and retried until the connection returns. An update from the server can't overwrite a change that's still on its way.
- If the server refuses a change, it's undone on screen and the user is told why.
- Waiting changes are held in memory only, so closing the app while offline loses them. A banner warns about this while the server can't be reached.

**Images** go to Serverpod cloud storage. The server authorizes each upload and then checks that the file really is an image. Anyone with an image's link can view it; links contain a random part so they can't be guessed.

## Before going to production

- **Hosting:** fill in the real domains and database in `fine_man_server/config/production.yaml`, and the secrets in `config/passwords.yaml` (which is not in version control). The server can serve the web app itself: run the `flutter_build` script defined in `fine_man_server/pubspec.yaml`.
- **Sign-up email:** `lib/server.dart` uses `ServerpodCloudEmailIdpConfig`, which sends codes through Serverpod Cloud. If you host elsewhere, switch to `EmailIdpConfigFromPasswords` with your own email provider, or nobody will receive a sign-up code.
- **Image storage:** outside Serverpod Cloud, images are stored in the database. That's fine at small scale; for more, use one of Serverpod's S3 or Google Cloud storage packages.
- **More than one server:** live updates only reach users connected to the same server unless Redis is enabled in the config.
