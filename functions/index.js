const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();

const db = admin.firestore();

/**
 * Send FCM push notification to a user.
 */
async function sendNotification(uid, title, body) {
  if (!uid) return;
  try {
    const userDoc = await db.collection('users').doc(uid).get();
    const token = userDoc.data()?.fcmToken;
    if (!token) return;
    await admin.messaging().send({
      token,
      notification: { title, body },
      data: { click_action: 'FLUTTER_NOTIFICATION_CLICK' },
    });
  } catch (e) {
    console.warn(`FCM send failed for ${uid}:`, e.message);
  }
}

/**
 * Create a Stripe PaymentIntent (called from the app).
 */
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated', 'You must be logged in to make a payment'
    );
  }

  const stripeKey = functions.config().stripe?.secret_key;
  if (!stripeKey) {
    throw new functions.https.HttpsError(
      'failed-precondition', 'Stripe is not configured. Set stripe.secret_key'
    );
  }

  const stripe = require('stripe')(stripeKey);
  const { amount, currency, description } = data;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: currency || 'kes',
      description: description || 'Rent payment',
      metadata: { userId: context.auth.uid },
    });
    return { clientSecret: paymentIntent.client_secret };
  } catch (e) {
    console.error('Stripe error:', e);
    throw new functions.https.HttpsError('internal', e.message);
  }
});

/**
 * M-Pesa STK Push Callback.
 * Safaricom calls this URL after a customer completes/ cancels the STK push.
 */
exports.mpesaCallback = functions.https.onRequest(async (req, res) => {
  // Respond to Safaricom immediately (200 OK) to avoid retries
  res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });

  try {
    const body = req.body;
    const stkCallback = body?.Body?.stkCallback;
    if (!stkCallback) return;

    const {
      MerchantRequestID,
      CheckoutRequestID,
      ResultCode,
      ResultDesc,
      CallbackMetadata,
    } = stkCallback;

    // Find the pending payment in Firestore using CheckoutRequestID
    const paymentQuery = await db
      .collection('payments')
      .where('checkoutRequestId', '==', CheckoutRequestID)
      .limit(1)
      .get();

    if (paymentQuery.empty) {
      console.warn(`No pending payment for CheckoutRequestID: ${CheckoutRequestID}`);
      return;
    }

    const paymentDoc = paymentQuery.docs[0];
    const paymentData = paymentDoc.data();
    const tenantId = paymentData.tenantId;
    const leaseId = paymentData.leaseId;

    if (ResultCode === 0) {
      // Payment successful — extract metadata
      const meta = {};
      if (CallbackMetadata?.Item) {
        for (const item of CallbackMetadata.Item) {
          meta[item.Name] = item.Value;
        }
      }

      await paymentDoc.ref.update({
        status: 'Paid',
        mpesaReceipt: meta['MpesaReceiptNumber'] || null,
        transactionId: meta['TransactionId'] || CheckoutRequestID,
        paymentDate: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Notify tenant and landlord
      await sendNotification(
        tenantId,
        'Payment Received',
        `KES ${meta['Amount'] || ''} received. Receipt: ${meta['MpesaReceiptNumber'] || ''}`
      );
    } else {
      // Payment failed
      await paymentDoc.ref.update({
        status: 'Failed',
        errorDescription: ResultDesc || 'Payment cancelled',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await sendNotification(
        tenantId,
        'Payment Failed',
        `Payment of KES ${paymentData.amount || ''} was not completed. ${ResultDesc || ''}`
      );
    }
  } catch (e) {
    console.error('M-Pesa callback error:', e);
  }
});

/**
 * Triggered when an application status changes.
 */
exports.onApplicationStatusChange = functions.firestore
  .document('applications/{appId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return;
    if (before.status === after.status) return;

    const { unitId, tenantId, caretakerId, tenantName } = after;

    switch (after.status) {
      case 'pending':
        await sendNotification(
          caretakerId,
          'New Application',
          `${tenantName || 'A tenant'} applied for unit ${unitId || ''}`
        );
        break;

      case 'approved':
        await sendNotification(
          tenantId,
          'Application Approved',
          `Your application for unit ${unitId || ''} has been approved!`
        );
        break;

      case 'accepted':
        await sendNotification(
          caretakerId,
          'Offer Accepted',
          `${tenantName || 'Tenant'} accepted your counter-offer for unit ${unitId || ''}`
        );
        break;

      case 'countered': {
        const counterRent = after.caretakerCounterRent || '';
        await sendNotification(
          tenantId,
          'Counter Offer',
          `CareTaker proposed KES ${counterRent}/mo for unit ${unitId || ''}`
        );
        break;
      }

      case 'rejected':
        await sendNotification(
          tenantId,
          'Application Not Approved',
          `Your application for unit ${unitId || ''} was not approved.`
        );
        break;
    }
  });

/**
 * Triggered when a maintenance ticket status changes.
 */
exports.onMaintenanceStatusChange = functions.firestore
  .document('maintenance/{ticketId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;

    const { unitId, tenantId, issue } = after;

    if (after.status === 'resolved') {
      await sendNotification(
        tenantId,
        'Issue Resolved',
        `"${issue || 'Maintenance issue'}" has been resolved.`
      );
    } else if (after.status === 'in_progress') {
      await sendNotification(
        tenantId,
        'Issue In Progress',
        `"${issue || 'Maintenance issue'}" is being worked on.`
      );
    }
  });

/**
 * Scheduled function: checks for late payments daily and applies late fees.
 * Runs at 00:00 Africa/Nairobi time.
 */
exports.applyLateFees = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('Africa/Nairobi')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const cutoff = admin.firestore.Timestamp.fromMillis(
      now.toMillis() - 30 * 24 * 60 * 60 * 1000 // 30 days ago
    );

    // Get active leases
    const leasesSnap = await db
      .collection('leases')
      .where('isActive', '==', true)
      .get();

    for (const leaseDoc of leasesSnap.docs) {
      const lease = leaseDoc.data();
      const leaseId = leaseDoc.id;
      const tenantId = lease.tenantId;
      const rentAmount = lease.rentAmount || 0;
      const lateFeePercent = lease.lateFeePercent || 5; // Default 5% late fee
      const gracePeriodDays = lease.gracePeriodDays || 5;

      // Get the last payment for this lease
      const paymentsSnap = await db
        .collection('payments')
        .where('leaseId', '==', leaseId)
        .where('status', '==', 'Paid')
        .orderBy('paymentDate', 'desc')
        .limit(1)
        .get();

      const lastPaymentDate = paymentsSnap.empty
        ? null
        : paymentsSnap.docs[0].data().paymentDate?.toDate();

      const dueDate = new Date(now.toMillis());
      dueDate.setDate(1); // Rent due on 1st of month

      // If no payment this month and past grace period, apply late fee
      const daysSinceDue = Math.floor(
        (now.toMillis() - dueDate.getTime()) / (1000 * 60 * 60 * 24)
      );

      if (daysSinceDue > gracePeriodDays) {
        const lateFee = (rentAmount * lateFeePercent) / 100;

        // Check if late fee was already applied this month
        const lateFeesSnap = await db
          .collection('payments')
          .where('leaseId', '==', leaseId)
          .where('paymentType', '==', 'Late Fee')
          .where('periodStart', '==', dueDate.toISOString().substring(0, 7))
          .limit(1)
          .get();

        if (lateFeesSnap.empty) {
          // Create a late fee payment record
          await db.collection('payments').add({
            leaseId,
            tenantId,
            amount: lateFee,
            paymentType: 'Late Fee',
            status: 'Pending',
            paymentMethod: 'Automatic',
            paidBy: 'tenant',
            lateFee: lateFee,
            periodStart: dueDate.toISOString(),
            notes: `Auto-applied late fee (${lateFeePercent}%) for overdue rent`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          await sendNotification(
            tenantId,
            'Late Fee Applied',
            `KES ${lateFee.toFixed(2)} late fee has been applied to your account for ${dueDate.toLocaleDateString()}.`
          );
        }
      }
    }
  });
