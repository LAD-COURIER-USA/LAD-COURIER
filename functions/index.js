const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * 🛡️ CONFIGURACIÓN GLOBAL LAD DIGITAL SYSTEMS LLC
 * REGIÓN: us-central1
 */
const REGION = "us-central1";

// --- HELPERS ---
let stripeInstance;
function getStripe() {
    if (!stripeInstance) {
        const secret = process.env.STRIPE_SECRET_TEST || "";
        stripeInstance = require("stripe")(secret);
    }
    return stripeInstance;
}

/**
 * 🔴 NO TOCAR BAJO NINGUN CONCEPTO - SISTEMA DE REFERIDOS PROBADO
 */
exports.logReferral = onRequest({ region: REGION, invoker: "public" }, async (req, res) => {
    const driverId = req.query.id;
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (driverId && ip) {
        const docId = ip.replace(/\./g, "_").replace(/:/g, "_");
        await admin.firestore().collection("temp_referrals").doc(docId).set({
            driverId: driverId,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
    }
    res.status(200).send("Referral logged");
});

/**
 * 💳 3. STRIPE CONNECT: ONBOARDING
 * 🔴 NO TOCAR BAJO NINGUN CONCEPTO - FLUJO DE REGISTRO BANCARIO PROBADO
 */
exports.createStripeAccount = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "No logueado.");
    const uid = request.auth.uid;
    const stripe = getStripe();
    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        let stripeAccountId = userDoc.data()?.stripeAccountId;
        if (!stripeAccountId) {
            const account = await stripe.accounts.create({
                type: 'express',
                capabilities: { card_payments: { requested: true }, transfers: { requested: true } },
                metadata: { firebaseUid: uid }
            });
            stripeAccountId = account.id;
            await admin.firestore().collection("users").doc(uid).update({ stripeAccountId, stripeStatus: 'pending' });
        }
        const accountLink = await stripe.accountLinks.create({
            account: stripeAccountId,
            refresh_url: 'https://ladcourier.com/stripe-return',
            return_url: 'https://ladcourier.com/stripe-return',
            type: 'account_onboarding',
        });
        return { url: accountLink.url };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 💳 4. RETENCIÓN (HOLD)
 * 🟡 ÁREA DE TRABAJO ACTUAL - MODELO SAAS DIRECTO
 */
exports.authorizeOrderPayment = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "No logueado.");
    const { amount, driverStripeAccountId, orderId } = request.data;
    const stripe = getStripe();
    try {
        const orderDoc = await admin.firestore().collection("orders").doc(orderId).get();
        const orderData = orderDoc.data();
        const clientDoc = await admin.firestore().collection("users").doc(orderData.clientId).get();
        const platformCustomerId = clientDoc.data()?.stripeCustomerId;
        const platformPaymentMethodId = clientDoc.data()?.defaultPaymentMethodId;

        if (!platformCustomerId || !platformPaymentMethodId) throw new Error("Cliente no configurado.");

        const mirror = await stripe.customers.create({ email: clientDoc.data().email }, { stripeAccount: driverStripeAccountId });
        const clonedMethod = await stripe.paymentMethods.create({
            payment_method: platformPaymentMethodId,
            customer: platformCustomerId
        }, { stripeAccount: driverStripeAccountId });

        await stripe.paymentMethods.attach(clonedMethod.id, { customer: mirror.id }, { stripeAccount: driverStripeAccountId });

        const paymentIntent = await stripe.paymentIntents.create({
            amount,
            currency: 'usd',
            customer: mirror.id,
            payment_method: clonedMethod.id,
            capture_method: 'manual',
            confirm: true,
            off_session: true,
            application_fee_amount: 50,
            metadata: { orderId, type: 'LAD_HOLD_DIRECT' }
        }, { stripeAccount: driverStripeAccountId });

        await admin.firestore().collection("orders").doc(orderId).update({
            stripePaymentIntentId: paymentIntent.id,
            paymentStatus: 'authorized'
        });
        return { success: true, paymentIntentId: paymentIntent.id };
    } catch (error) { return { success: false, error: error.message }; }
});

/**
 * 💳 5. COBRO (CAPTURE)
 * 🔴 NO TOCAR BAJO NINGUN CONCEPTO - LÓGICA DE CIERRE PROBADA
 */
exports.captureOrderPayment = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    const { orderId } = request.data;
    const stripe = getStripe();
    try {
        const orderDoc = await admin.firestore().collection("orders").doc(orderId).get();
        const orderData = orderDoc.data();
        const piId = orderData?.stripePaymentIntentId;
        const driverDoc = await admin.firestore().collection("users").doc(orderData.assignedMessengerId).get();
        const stripeAccountId = driverDoc.data()?.stripeAccountId;

        await stripe.paymentIntents.capture(piId, {}, { stripeAccount: stripeAccountId });
        await admin.firestore().collection("orders").doc(orderId).update({
            paymentStatus: 'captured',
            feeCharged: 50,
            capturedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        return { success: true };
    } catch (error) { return { success: false, error: error.message }; }
});

/**
 * 💳 6. CANCELAR (CANCEL)
 * 🔴 NO TOCAR BAJO NINGUN CONCEPTO - LIBERACIÓN DE FONDOS PROBADA
 */
exports.cancelOrderPayment = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    const { orderId } = request.data;
    const stripe = getStripe();
    try {
        const orderDoc = await admin.firestore().collection("orders").doc(orderId).get();
        const orderData = orderDoc.data();
        const piId = orderData?.stripePaymentIntentId;
        const driverDoc = await admin.firestore().collection("users").doc(orderData.assignedMessengerId).get();
        const stripeAccountId = driverDoc.data()?.stripeAccountId;

        if (piId && stripeAccountId) {
            await stripe.paymentIntents.cancel(piId, {}, { stripeAccount: stripeAccountId });
        }
        await admin.firestore().collection("orders").doc(orderId).update({ paymentStatus: 'cancelled' });
        return { success: true };
    } catch (error) { return { success: false, error: error.message }; }
});

/**
 * 💳 7. SETUP INTENT
 * 🔴 NO TOCAR BAJO NINGUN CONCEPTO - BÓVEDA DE SEGURIDAD PROBADA
 */
exports.createSetupIntent = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "No logueado.");
    const uid = request.auth.uid;
    const stripe = getStripe();
    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        let customerId = userDoc.data()?.stripeCustomerId;
        if (!customerId) {
            const customer = await stripe.customers.create({ email: request.auth.token.email, metadata: { firebaseUid: uid } });
            customerId = customer.id;
            await admin.firestore().collection("users").doc(uid).update({ stripeCustomerId: customerId });
        }
        const ephemeralKey = await stripe.ephemeralKeys.create({ customer: customerId }, { apiVersion: '2022-11-15' });
        const setupIntent = await stripe.setupIntents.create({ customer: customerId, payment_method_types: ['card'] });
        return { setupIntentClientSecret: setupIntent.client_secret, customerId: customerId, ephemeralKeySecret: ephemeralKey.secret };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 💳 8. DASHBOARD LOGIN LINK
 * 🔴 NO TOCAR BAJO NINGUN CONCEPTO
 */
exports.createStripeLoginLink = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "No logueado.");
    const uid = request.auth.uid;
    const stripe = getStripe();
    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const stripeAccountId = userDoc.data()?.stripeAccountId;
        if (!stripeAccountId) throw new Error("No tienes cuenta de Stripe vinculada.");
        const loginLink = await stripe.accounts.createLoginLink(stripeAccountId);
        return { url: loginLink.url };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 🗑️ 9. ELIMINAR CUENTA
 * 🔴 NO TOCAR BAJO NINGUN CONCEPTO
 */
exports.deleteUserAccount = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "No logueado.");
    const uid = request.auth.uid;
    try {
        await admin.firestore().collection("users").doc(uid).delete();
        await admin.auth().deleteUser(uid);
        return { success: true };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 🔄 10. SINCRONIZACIÓN MANUAL DE TARJETA
 * 🔴 NO TOCAR BAJO NINGUN CONCEPTO
 */
exports.syncPaymentMethod = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "No logueado.");
    const stripe = getStripe();
    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const customerId = userDoc.data()?.stripeCustomerId;
        if (!customerId) throw new Error("No hay CustomerId.");
        const paymentMethods = await stripe.paymentMethods.list({ customer: customerId, type: 'card' });
        if (paymentMethods.data.length > 0) {
            const latestMethodId = paymentMethods.data[0].id;
            await admin.firestore().collection("users").doc(uid).update({ defaultPaymentMethodId: latestMethodId });
            return { success: true, methodId: latestMethodId };
        }
        return { success: false, error: "No se encontraron tarjetas." };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 🔄 11. SINCRONIZACIÓN MANUAL STRIPE (STATUS DRIVER)
 * 🔴 NO TOCAR BAJO NINGUN CONCEPTO
 */
exports.syncStripeStatus = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    const uid = request.auth?.uid || request.data?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "No logueado.");
    const stripe = getStripe();
    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const stripeAccountId = userDoc.data()?.stripeAccountId;
        if (!stripeAccountId) return { status: 'no_account' };
        const account = await stripe.accounts.retrieve(stripeAccountId);
        const isActive = account.details_submitted && account.charges_enabled;
        if (isActive) { await admin.firestore().collection("users").doc(uid).update({ stripeStatus: 'active', isStripeConnected: true }); }
        return { status: isActive ? 'active' : 'pending' };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 💳 12. WEBHOOK DE STRIPE
 * 🔴 NO TOCAR BAJO NINGUN CONCEPTO
 */
exports.stripeWebhook = onRequest({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST", "STRIPE_WEBHOOK_SECRET_TEST"] }, async (req, res) => {
    const sig = req.headers['stripe-signature'];
    const secret = process.env.STRIPE_WEBHOOK_SECRET_TEST;
    try {
        const event = getStripe().webhooks.constructEvent(req.rawBody, sig, secret);
        console.log(`[WEBHOOK] Evento: ${event.type}`);
        res.status(200).json({received: true});
    } catch (err) { res.status(200).send("Webhook Error"); }
});

/**
 * 🔔 13. NOTIFICACIÓN DE NUEVA MISIÓN
 * 🔴 NO TOCAR BAJO NINGUN CONCEPTO
 */
exports.notifyDriverOnNewOrder = onDocumentCreated({ region: REGION, document: "orders/{orderId}" }, async (event) => {
    const orderData = event.data.data();
    const driverId = orderData.assignedMessengerId;
    if (driverId) {
        const driverDoc = await admin.firestore().collection("users").doc(driverId).get();
        const fcmToken = driverDoc.data()?.fcmToken;
        if (fcmToken) {
            const message = {
                notification: { title: "🚀 ¡NUEVA MISIÓN!", body: `Nueva solicitud de ${orderData.clientName || 'Cliente'}.` },
                android: { priority: "high", notification: { channel_id: "high_importance_channel", sound: "default", click_action: "FLUTTER_NOTIFICATION_CLICK" } },
                token: fcmToken,
            };
            try { await admin.messaging().send(message); } catch (e) { console.error("❌ [FCM ERROR]:", e); }
        }
    }
});

/**
 * 🔔 14. NOTIFICACIÓN DE NEGOCIACIÓN
 * 🔴 NO TOCAR BAJO NINGUN CONCEPTO
 */
exports.notifyOnNegotiationUpdate = onDocumentUpdated({ region: REGION, document: "orders/{orderId}" }, async (event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();
    if (newData.negotiationHistory?.length !== oldData.negotiationHistory?.length) {
        const lastOffer = newData.negotiationHistory[newData.negotiationHistory.length - 1];
        const isClientOffer = lastOffer.offeredBy === 'client';
        const targetId = isClientOffer ? newData.assignedMessengerId : newData.clientId;
        const targetDoc = await admin.firestore().collection("users").doc(targetId).get();
        const fcmToken = targetDoc.data()?.fcmToken;
        if (fcmToken) {
            const message = {
                notification: { title: isClientOffer ? "💰 CONTRAOFERTA" : "🏷️ NUEVA OFERTA", body: `Precio: $${lastOffer.price}.` },
                android: { priority: "high", notification: { channel_id: "high_importance_channel", sound: "default" } },
                token: fcmToken
            };
            try { await admin.messaging().send(message); } catch (e) {}
        }
    }
});

/**
 * 💳 15. COBRO DIRECTO (SAAS MODEL - EL QUE PROTEGE TU LLC)
 * 🛡️ SISTEMA LAD: Amanda le paga DIRECTO a Lucrecio.
 * 🟡 ÁREA DE TRABAJO ACTUAL - BLINDAJE FINANCIERO V6
 */
exports.processImmediatePayment = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    const { amount, driverStripeAccountId, orderId } = request.data;
    const stripe = getStripe();
    console.log(`[LAD SAAS] Iniciando Cobro Directo para Orden: ${orderId}`);
    try {
        const orderRef = admin.firestore().collection("orders").doc(orderId);
        const orderDoc = await orderRef.get();
        if (!orderDoc.exists) throw new Error("La orden no existe.");
        const orderData = orderDoc.data();

        // 1. Obtener al cliente real de la plataforma
        const clientDoc = await admin.firestore().collection("users").doc(orderData.clientId).get();
        const platformCustomerId = clientDoc.data()?.stripeCustomerId;
        const platformPaymentMethodId = clientDoc.data()?.defaultPaymentMethodId;

        if (!platformCustomerId || !platformPaymentMethodId) throw new Error("Falta método de pago.");

        // 2. CREAR ESPEJO (MIRROR)
        const mirror = await stripe.customers.create({ email: clientDoc.data().email }, { stripeAccount: driverStripeAccountId });

        // 3. CLONAR TARJETA (LA LLAVE MAESTRA)
        const clonedMethod = await stripe.paymentMethods.create({
            payment_method: platformPaymentMethodId,
            customer: platformCustomerId, // ✅ LLAVE DE SEGURIDAD
        }, { stripeAccount: driverStripeAccountId });

        // 4. VINCULAR TARJETA AL ESPEJO
        await stripe.paymentMethods.attach(clonedMethod.id, {
            customer: mirror.id,
        }, { stripeAccount: driverStripeAccountId });

        // 5. EJECUTAR EL COBRO (DIRECT CHARGE)
        const charge = await stripe.paymentIntents.create({
            amount,
            currency: 'usd',
            customer: mirror.id,
            payment_method: clonedMethod.id,
            confirm: true,
            off_session: true,
            application_fee_amount: 50, // 💵 Tu comisión de $0.50
            metadata: { orderId, type: 'LAD_DIRECT_CHARGE_V6_FINAL' }
        }, { stripeAccount: driverStripeAccountId });

        await orderRef.update({
            paymentStatus: 'captured',
            stripePaymentIntentId: charge.id,
            completedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`[ÉXITO] Cobro Directo realizado. ID: ${charge.id}`);
        return { success: true, chargeId: charge.id };
    } catch (error) {
        console.error("❌ [LAD SAAS ERROR]:", error.message);
        return { success: false, error: error.message };
    }
});

/**
 * 🧹 16. EL BARRENDERO LAD
 * 🔴 NO TOCAR BAJO NINGUN CONCEPTO - LÓGICA DE LIMPIEZA PROBADA
 */
const { onSchedule } = require("firebase-functions/v2/scheduler");
exports.autoCleanupOrders = onSchedule({ schedule: "every 5 minutes", region: REGION }, async (event) => {
    const now = admin.firestore.Timestamp.now().toMillis();
    const expiryTime = 30 * 60 * 1000;
    const snapshot = await admin.firestore().collection("orders")
        .where("status", "in", ["rejected", "cancelled", "negotiating"])
        .get();
    const batch = admin.firestore().batch();
    let count = 0;
    snapshot.forEach(doc => {
        if (now - doc.data().createdAt.toMillis() > expiryTime) { batch.delete(doc.ref); count++; }
    });
    if (count > 0) await batch.commit();
});
