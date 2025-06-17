const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

const transporter = nodemailer.createTransport({
  host: functions.config().smtp.host,
  port: functions.config().smtp.port,
  secure: functions.config().smtp.secure,
  auth: {
    user: functions.config().smtp.user,
    pass: functions.config().smtp.pass,
  },
});

function buildEmailHtml(reports) {
  let html = '<h1>Weekly Snapshot</h1>';
  html += '<p>Here is a summary of your recent reports.</p>';
  for (const r of reports) {
    const addr = r.inspectionMetadata?.propertyAddress || '';
    const link = r.publicViewLink || '#';
    html += `<p><a href="${link}">${addr}</a></p>`;
  }
  return html;
}

exports.sendWeeklySnapshots = functions.pubsub
  .schedule('0 * * * *')
  .timeZone('UTC')
  .onRun(async () => {
    const prefsSnap = await admin
      .firestore()
      .collection('clientPreferences')
      .where('weeklySnapshot.enabled', '==', true)
      .get();

    const now = new Date();
    for (const doc of prefsSnap.docs) {
      const data = doc.data();
      const email = data.email;
      const day = data.weeklySnapshot.day || 1;
      const hour = data.weeklySnapshot.hour || 8;
      if (now.getUTCDay() !== day || now.getUTCHours() !== hour) continue;

      const since = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      const reportSnap = await admin
        .firestore()
        .collection('reports')
        .where('clientEmail', '==', email)
        .where('createdAt', '>=', since)
        .get();
      if (reportSnap.empty) continue;
      const reports = reportSnap.docs.map((d) => d.data());
      const mailOptions = {
        from: 'ClearSky <no-reply@clearsky.com>',
        to: email,
        subject: 'Your Weekly Snapshot',
        html: buildEmailHtml(reports),
      };
      await transporter.sendMail(mailOptions);
      await admin
        .firestore()
        .collection('snapshotEmails')
        .add({ email, sentAt: admin.firestore.FieldValue.serverTimestamp() });
    }
  });
