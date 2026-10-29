const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

const projectId = process.env.GCLOUD_PROJECT || process.argv[2];
const uid = process.env.GCLOUD_PROJECT ? process.argv[2] : process.argv[3];
if (!projectId || !uid) {
  console.error('Usage: GCLOUD_PROJECT=<firebase-project> node scripts/grant-admin.js <uid>');
  process.exit(1);
}

initializeApp({ projectId });
getAuth().getUser(uid)
  .then((user) => getAuth().setCustomUserClaims(uid, { ...(user.customClaims || {}), admin: true }))
  .then(() => console.log(`Admin role granted to ${uid} in ${projectId}.`))
  .catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
