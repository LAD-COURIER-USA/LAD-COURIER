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
 * REGIÓN: us-central1 (Baja latencia para USA)
 */
const REGION = "us-central1";

// --- HELPERS PARA CARGA PERESOZA (OPTIMIZACIÓN DE RECURSOS) ---
let stripeInstance;
function getStripe() {
    if (!stripeInstance) {
        const secret = process.env.STRIPE_SECRET_TEST || "";
        stripeInstance = require("stripe")(secret);
    }
    return stripeInstance;
}

let rekognitionInstance;
function getRekognition() {
    if (!rekognitionInstance) {
        const AWS = require('aws-sdk');
        rekognitionInstance = new AWS.Rekognition({
            accessKeyId: process.env.AWS_ACCESS_KEY || null,
            secretAccessKey: process.env.AWS_SECRET_KEY || null,
            region: process.env.AWS_REGION || 'us-east-1'
        });
    }
    return rekognitionInstance;
}

/**
 * 🛡️ 1. VÍNCULO INVISIBLE DE INVITACIÓN (RESILIENCIA DE REFERIDOS)
 */
exports.logReferral = onRequest({ region: REGION, invoker: "public" }, async (req, res) => {
    const driverId = req.query.id;
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    console.log(`[LOG REFERIDO] Procesando IP: ${ip} para Driver: ${driverId}`);
    if (driverId && ip) {
        const docId = ip.replace(/\./g, "_").replace(/:/g, "_");
        await admin.firestore().collection("temp_referrals").doc(docId).set({
            driverId: driverId,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            userAgent: req.headers['user-agent']
        });
    }
    res.status(200).send("Referral logged");
});

/**
 * 🛡️ 2. VALIDACIÓN BIOMÉTRICA REFORZADA (AMAZON REKOGNITION)
 */
exports.verifyBiometricIdentity = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    let uid = request.auth?.uid || request.data.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sesión inválida.");
    const { selfieUrl, masterPhotoUrl } = request.data;
    if (!selfieUrl || !masterPhotoUrl) throw new HttpsError("invalid-argument", "Faltan imágenes.");
    try {
        const axios = require('axios');
        const stripeSecret = process.env.STRIPE_SECRET_TEST;
        const [masterRes, selfieRes] = await Promise.all([
            axios.get(masterPhotoUrl, { responseType: 'arraybuffer', headers: { 'Authorization': `Bearer ${stripeSecret}` } }),
            axios.get(selfieUrl, { responseType: 'arraybuffer' })
        ]);
        const params = {
            SourceImage: { Bytes: Buffer.from(masterRes.data, 'binary') },
            TargetImage: { Bytes: Buffer.from(selfieRes.data, 'binary') },
            SimilarityThreshold: 70
        };
        const response = await getRekognition().compareFaces(params).promise();
        const isMatch = response.FaceMatches && response.FaceMatches.length > 0;
        const confidence = isMatch ? response.FaceMatches[0].Similarity : 0;
        await admin.firestore().collection("users").doc(uid).update({
            lastIdentityVerification: admin.firestore.FieldValue.serverTimestamp(),
            biometric_confidence: confidence,
            verificationStatus: isMatch ? 'APROBADO' : 'FALLO_BIOMETRICO',
            isIdentityVerified: isMatch
        });
        return { success: isMatch, confidence: confidence };
    } catch (error) {
        logger.error("❌ [BIOMETRÍA] Error Rekognition:", error);
        throw new HttpsError("internal", error.message);
    }
});

/**
 * 💳 3. STRIPE CONNECT: ONBOARDING (EXPRESS)
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
                email: request.auth.token.email,
                business_profile: { name: `LAD Driver - ${uid}` },
                capabilities: { card_payments: { requested: true }, transfers: { requested: true } },
                controller: { fees: { payer: 'account' }, losses: { payments: 'account' } },
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
 * 💳 4. RETENCIÓN (HOLD): MODO DIRECT CHARGE CON CLONACIÓN
 */
exports.authorizeOrderPayment = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "No logueado.");
    const { amount, driverStripeAccountId, orderId, paymentMethodId } = request.data;
    const stripe = getStripe();
    try {
        const orderDoc = await admin.firestore().collection("orders").doc(orderId).get();
        const orderData = orderDoc.data();
        const clientEmail = orderData.clientEmail || `cliente_${orderData.clientId}@ladcourier.com`;

        // 1. Crear el Cliente "Espejo" en la cuenta del Driver
        const customerMirror = await stripe.customers.create({
            email: clientEmail,
            metadata: { platformClientId: orderData.clientId }
        }, { stripeAccount: driverStripeAccountId });

        // 2. Clonar el método de pago VINCULÁNDOLO al cliente espejo
        const clonedMethod = await stripe.paymentMethods.create({
            payment_method: paymentMethodId,
            customer: customerMirror.id,
        }, { stripeAccount: driverStripeAccountId });

        // 3. Crear el cobro con captura manual (HOLD)
        const paymentIntent = await stripe.paymentIntents.create({
            amount,
            currency: 'usd',
            payment_method: clonedMethod.id,
            customer: customerMirror.id,
            capture_method: 'manual',
            confirm: true,
            off_session: true,
            application_fee_amount: 50,
            metadata: { orderId: orderId, type: 'LAD_HOLD_DIRECT_SECURE' }
        }, { stripeAccount: driverStripeAccountId });

        await admin.firestore().collection("orders").doc(orderId).update({
            stripePaymentIntentId: paymentIntent.id,
            stripeMirrorCustomerId: customerMirror.id,
            paymentStatus: 'authorized',
            ladNetProfit: 50,
            chargeType: 'direct_cloned_secure'
        });
        return { success: true, paymentIntentId: paymentIntent.id };
    } catch (error) {
        console.error("❌ [STRIPE HOLD ERROR]:", error.message);
        return { success: false, error: error.message };
    }
});

/**
 * 💳 5. COBRO (CAPTURE): EJECUTAR EL COBRO AL ENTREGAR
 */
exports.captureOrderPayment = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    const { orderId } = request.data;
    const stripe = getStripe();
    try {
        const orderDoc = await admin.firestore().collection("orders").doc(orderId).get();
        const orderData = orderDoc.data();
        const piId = orderData?.stripePaymentIntentId;
        const driverFirebaseId = orderData?.assignedMessengerId;
        if (!piId) throw new Error("No hay PaymentIntent para capturar.");
        const driverDoc = await admin.firestore().collection("users").doc(driverFirebaseId).get();
        const stripeAccountId = driverDoc.data()?.stripeAccountId;
        if (!stripeAccountId) throw new Error("El Driver no tiene cuenta de Stripe.");

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
 * 💳 6. CANCELAR (CANCEL): LIBERAR FONDOS
 */
exports.cancelOrderPayment = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    const { orderId } = request.data;
    const stripe = getStripe();
    try {
        const orderDoc = await admin.firestore().collection("orders").doc(orderId).get();
        const piId = orderDoc.data()?.stripePaymentIntentId;
        const driverId = orderData?.assignedMessengerId;
        const driverDoc = await admin.firestore().collection("users").doc(driverId).get();
        const stripeAccountId = driverDoc.data()?.stripeAccountId;

        if (piId && stripeAccountId) {
            await stripe.paymentIntents.cancel(piId, {}, { stripeAccount: stripeAccountId });
        }
        await admin.firestore().collection("orders").doc(orderId).update({ paymentStatus: 'cancelled' });
        return { success: true };
    } catch (error) { return { success: false, error: error.message }; }
});

/**
 * 💳 7. SETUP INTENT (BÓVEDA DE TARJETAS)
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
 * 💳 8. DASHBOARD LOGIN LINK (EXPRESS)
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
 * 🗑️ 9. ELIMINAR CUENTA (BORRADO TÁCTICO)
 */
exports.deleteUserAccount = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Debe iniciar sesión.");
    const uid = request.auth.uid;
    const stripe = getStripe();
    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const stripeAccountId = userDoc.data()?.stripeAccountId;
        if (stripeAccountId) { try { await stripe.accounts.del(stripeAccountId); } catch (e) {} }
        await admin.firestore().collection("users").doc(uid).delete();
        await admin.auth().deleteUser(uid);
        return { success: true };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 🔄 10. SINCRONIZACIÓN MANUAL DE MÉTODO DE PAGO
 */
exports.syncPaymentMethod = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "No logueado.");
    const stripe = getStripe();
    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const customerId = userDoc.data()?.stripeCustomerId;
        if (!customerId) throw new Error("No hay CustomerId de Stripe.");
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
        if (isActive) {
            await admin.firestore().collection("users").doc(uid).update({ stripeStatus: 'active', isStripeConnected: true });
        }
        return { status: isActive ? 'active' : 'pending' };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 💳 12. WEBHOOK DE STRIPE
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
 * 💳 15. COBRO INMEDIATO (SaaS MODEL - PRUEBA)
 */
exports.processImmediatePayment = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST"] }, async (request) => {
    const { amount, driverStripeAccountId, orderId, paymentMethodId, customerId } = request.data;
    const stripe = getStripe();

    console.log(`[PAGO INMEDIATO] Iniciando cobro de $${amount/100} para Orden: ${orderId}`);

    try {
        // 1. Intentar crear el Cliente Espejo (Mirror) con seguridad ante IDs huérfanos
        let customerMirrorId;
        try {
            const customerMirror = await stripe.customers.create({
                description: `Mirror for Order ${orderId}`,
                metadata: { platformClientId: customerId || "unknown" }
            }, { stripeAccount: driverStripeAccountId });
            customerMirrorId = customerMirror.id;
            console.log(`[PAGO INMEDIATO] Cliente Mirror creado: ${customerMirrorId}`);
        } catch (e) {
            console.warn("[PAGO INMEDIATO] No se pudo crear mirror con customerId base, intentando modo emergencia...");
            const emergencyMirror = await stripe.customers.create({
                description: `Emergency Mirror for Order ${orderId}`
            }, { stripeAccount: driverStripeAccountId });
            customerMirrorId = emergencyMirror.id;
        }

        // 2. Clonar el método de pago vinculado al nuevo espejo
        const clonedMethod = await stripe.paymentMethods.create({
            payment_method: paymentMethodId,
            customer: customerMirrorId,
        }, { stripeAccount: driverStripeAccountId });

        console.log(`[PAGO INMEDIATO] Tarjeta clonada: ${clonedMethod.id}`);

        // 3. Ejecutar el cobro real e inmediato
        const charge = await stripe.paymentIntents.create({
            amount,
            currency: 'usd',
            payment_method: clonedMethod.id,
            customer: customerMirrorId,
            confirm: true,
            off_session: true,
            application_fee_amount: 50,
            metadata: { orderId: orderId, type: 'LAD_IMMEDIATE_SECURE' }
        }, { stripeAccount: driverStripeAccountId });

        console.log(`[PAGO INMEDIATO EXITOSO] Charge ID: ${charge.id}`);
        return { success: true, chargeId: charge.id };

    } catch (error) {
        console.error("❌ [PAGO INMEDIATO CRÍTICO]:", error.message);
        return { success: false, error: error.message };
    }
});
