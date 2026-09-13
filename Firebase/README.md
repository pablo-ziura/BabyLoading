# Backup security rules

These files are deployment inputs. Implementation and tests do not deploy them to
Lab or production.

## Run locally

Use Node.js 22 or newer and Java 21 or newer:

```sh
npm ci
npm test
```

The test command starts Firestore and Storage emulators for the non-production
`demo-babyloading-backup` project, runs ownership/schema/tombstone/receipt/image
rules tests, and shuts the emulators down. Ports are 8088 and 9198.

For this workspace, a disposable Corretto 21 runtime was downloaded under the
ignored `.runtime/` directory because the system runtime is Java 17:

```sh
PATH="$PWD/.runtime/amazon-corretto-21.jdk/Contents/Home/bin:$PATH" npm test
```

## Deploy deliberately

Verify the Firebase project ID against the intended environment's plist, review the
rules, then deploy to that explicitly selected project from this directory:

```sh
npx firebase deploy --project YOUR_LAB_PROJECT_ID --only firestore:rules,storage
```

Deploy production separately after validation. Do not use an implicit default
project or reuse production resources for Lab. Cross-service Storage rule reads
require the Firebase service permissions prompted during deployment.

The client deletes only Firebase Auth accounts. Configure and verify your separate
backend cleanup for `users/{uid}` documents, operation receipts and Storage objects.
Do not expire operation receipts or tombstones while other devices can replay old
queued changes.
