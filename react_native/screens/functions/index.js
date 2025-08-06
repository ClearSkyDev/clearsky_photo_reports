// functions/index.js - Firebase Cloud Function to notify admin of restore or undo
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const { google } = require('googleapis');

admin.initializeApp();

const CLIENT_ID = functions.config().gmail.client_id;
const CLIENT_SECRET = functions.config().gmail.client_secret;
const REFRESH_TOKEN = functions.config().gmail.refresh_token;
const SENDER_EMAIL = functions.config().gmail.email;

const oAuth2Client = new google.auth.OAuth2(CLIENT_ID, CLIENT_SECRET);
oAuth2Client.setCredentials({ refresh_token: REFRESH_TOKEN });

const getAccessToken = async () => {
  const accessToken = await oAuth2Client.getAccessToken();
  return accessToken.token;
};

exports.alertRestore = functions.firestore
  .document('admin_restore_log/{logId}')
  .onCreate(async (snap, context) => {
    const log = snap.data();
    const accessToken = await getAccessToken();

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        type: 'OAuth2',
        user: SENDER_EMAIL,
        clientId: CLIENT_ID,
        clientSecret: CLIENT_SECRET,
        refreshToken: REFRESH_TOKEN,
        accessToken: accessToken,
      },
    });

    const mailOptions = {
      from: SENDER_EMAIL,
      to: 'admin@example.com',
      subject: 'Restore/Undo Triggered',
      text: `A restore/undo was performed.\n\nDetails:\n${JSON.stringify(log, null, 2)}`,
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log('Restore alert sent.');
    } catch (error) {
      console.error('Email failed:', error);
    }
  });
