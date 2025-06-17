const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const express = require("express");

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
  let html = "<h1>Weekly Snapshot</h1>";
  html += "<p>Here is a summary of your recent reports.</p>";
  for (const r of reports) {
    const addr = r.inspectionMetadata?.propertyAddress || "";
    const link = r.publicViewLink || "#";
    html += `<p><a href="${link}">${addr}</a></p>`;
  }
  return html;
}

exports.sendWeeklySnapshots = functions.pubsub
  .schedule("0 * * * *")
  .timeZone("UTC")
  .onRun(async () => {
    const prefsSnap = await admin
      .firestore()
      .collection("clientPreferences")
      .where("weeklySnapshot.enabled", "==", true)
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
        .collection("reports")
        .where("clientEmail", "==", email)
        .where("createdAt", ">=", since)
        .get();
      if (reportSnap.empty) continue;
      const reports = reportSnap.docs.map((d) => d.data());
      const mailOptions = {
        from: "ClearSky <no-reply@clearsky.com>",
        to: email,
        subject: "Your Weekly Snapshot",
        html: buildEmailHtml(reports),
      };
      await transporter.sendMail(mailOptions);
      await admin
        .firestore()
        .collection("snapshotEmails")
        .add({ email, sentAt: admin.firestore.FieldValue.serverTimestamp() });
    }
  });

exports.notifyPartnerOnReportUpdate = functions.firestore
  .document("reports/{id}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!after.partnerId) return;
    if (
      before.isFinalized === after.isFinalized &&
      before.publicViewLink === after.publicViewLink
    ) {
      return;
    }
    const partnerDoc = await admin
      .firestore()
      .collection("partners")
      .doc(after.partnerId)
      .get();
    if (!partnerDoc.exists) return;
    const email = partnerDoc.data().email;
    await transporter.sendMail({
      from: "ClearSky <no-reply@clearsky.com>",
      to: email,
      subject: "Report Update",
      text: `Report for ${after.inspectionMetadata?.propertyAddress || ""} updated.`,
    });
  });

const app = express();

app.get("/report/:id", async (req, res) => {
  const id = req.params.id;
  const password = req.query.password;
  const snap = await admin
    .firestore()
    .collection("reports")
    .where("publicReportId", "==", id)
    .limit(1)
    .get();
  if (snap.empty) {
    res.status(404).send("Report not found");
    return;
  }
  const data = snap.docs[0].data();
  if (data.publicViewEnabled === false) {
    res.status(403).send("Access revoked");
    return;
  }
  if (data.publicViewPassword && data.publicViewPassword !== password) {
    res.status(403).send("Invalid password");
    return;
  }
  if (data.publicViewExpiry) {
    const expiry = data.publicViewExpiry.toDate
      ? data.publicViewExpiry.toDate()
      : new Date(data.publicViewExpiry);
    if (expiry < new Date()) {
      res.status(403).send("Link expired");
      return;
    }
  }
  let html = "<html><head><title>ClearSky Report</title></head><body>";
  html += "<h1>ClearSky Roof Inspection Report</h1>";
  html += `<h3>${data.inspectionMetadata?.propertyAddress || ""}</h3>`;
  if (data.summaryText) {
    html += `<h2>Summary</h2><p>${data.summaryText}</p>`;
  }
  if (Array.isArray(data.attachments)) {
    html += "<h2>Attachments</h2>";
    for (const att of data.attachments) {
      if (att.url) {
        const name = att.name || att.url;
        html += `<div><a href="${att.url}">${name}</a></div>`;
      }
    }
  }
  html += "</body></html>";
  res.set("Content-Type", "text/html");
  res.send(html);
});

exports.clientPortal = functions.https.onRequest(app);
