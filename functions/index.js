const { onCall, HttpsError, onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const vision = require('@google-cloud/vision'); // ✅ IA DE GOOGLE INTEGRADA
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
async function getStripeInstance() {
    const stripeConfig = await admin.firestore().collection("admin_settings").doc("stripe").get();
    const mode = stripeConfig.data()?.stripe_mode || "test";

    const secret = mode === "live"
        ? process.env.STRIPE_SECRET_LIVE
        : process.env.STRIPE_SECRET_TEST;

    return {
        stripe: require("stripe")(secret),
        mode: mode,
        isLive: mode === "live",
        fields: {
            customerId: mode === "live" ? "stripeCustomerIdLive" : "stripeCustomerId",
            accountId: mode === "live" ? "stripeAccountIdLive" : "stripeAccountId",
            paymentMethod: mode === "live" ? "defaultPaymentMethodIdLive" : "defaultPaymentMethodId",
            status: mode === "live" ? "stripeStatusLive" : "stripeStatus"
        }
    };
}

/**
 * 🔴 SISTEMA DE REFERIDOS SOBERANO
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
 * 💳 3. STRIPE CONNECT: ONBOARDING (SOBERANÍA TOTAL V16.1)
 */
exports.setupDriverBank = onCall({
    region: REGION,
    invoker: "public",
    enforceAppCheck: false, // 🛡️ LIBERACIÓN TOTAL PARA PRUEBAS REALES
    secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"]
}, async (request) => {
    console.log("🔔 [LAD AUDITORÍA] setupDriverBank iniciada.");

    if (!request.auth) {
        console.error("❌ ERROR: Sin autenticación.");
        throw new HttpsError("unauthenticated", "Sesión requerida.");
    }

    const uid = request.auth.uid;
    const { stripe, fields } = await getStripeInstance();

    try {
        console.log(`🔍 Buscando usuario ${uid} (Campos: ${fields.accountId}, ${fields.status})`);
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const userData = userDoc.data();
        let stripeAccountId = userData?.[fields.accountId];

        if (!stripeAccountId) {
            console.log("📦 Creando cuenta Express con MCC 4215 y Pago Semanal diferido...");
            const account = await stripe.accounts.create({
                type: 'express',
                country: 'US',
                email: userData?.email,
                capabilities: {
                    card_payments: { requested: true },
                    transfers: { requested: true },
                },
                business_type: 'individual',
                settings: {
                    payouts: {
                        schedule: {
                            interval: 'weekly',
                            weekly_anchor: 'monday', // 📅 Pago todos los lunes
                            delay_days: 7,           // 🛡️ 7 días de retraso para seguridad
                        },
                    },
                },
                business_profile: {
                    mcc: '4215',
                    url: 'https://ladcourier.com',
                },
                metadata: { firebaseUid: uid }
            });
            stripeAccountId = account.id;
            await admin.firestore().collection("users").doc(uid).update({
                [fields.accountId]: stripeAccountId,
                [fields.status]: 'pending'
            });
            console.log(`✅ Cuenta creada: ${stripeAccountId}`);
        }

        console.log(`🔗 Generando link de onboarding para: ${stripeAccountId}`);
        const accountLink = await stripe.accountLinks.create({
            account: stripeAccountId,
            refresh_url: 'https://connect.stripe.com/setup/s/' + stripeAccountId,
            return_url: 'https://ladcourier.com',
            type: 'account_onboarding',
            collect: 'eventually_due',
        });

        return { url: accountLink.url };
    } catch (error) {
        console.error("❌ STRIPE ERROR FATAL:", error.message);
        throw new HttpsError("internal", `Stripe: ${error.message}`);
    }
});

/**
 * 🧪 FUNCIÓN PING (DIAGNÓSTICO IAM)
 */
exports.pingLAD = onCall({ region: REGION, invoker: "public" }, async (request) => {
    return { message: "PONG - El búnker está abierto", timestamp: new Date().toISOString() };
});

/**
 * 💳 4. RETENCIÓN (HOLD)
 */
exports.authorizeOrderPayment = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"] }, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "No logueado.");
    const { amount, driverStripeAccountId, orderId } = request.data;
    const { stripe, fields } = await getStripeInstance();

    try {
        const orderDoc = await admin.firestore().collection("orders").doc(orderId).get();
        const orderData = orderDoc.data();
        const clientDoc = await admin.firestore().collection("users").doc(orderData.clientId).get();
        const clientData = clientDoc.data();

        // 🛡️ BYPASS VIP: Si el cliente es inspector, aprobamos sin Stripe
        if (clientData?.isVipTester === true) {
            console.log("💎 VIP DETECTADO: Autorizando orden sin cobro de Stripe.");
            await admin.firestore().collection("orders").doc(orderId).update({
                paymentStatus: 'authorized',
                isVipOrder: true
            });
            return { success: true, isVip: true };
        }

        const platformCustomerId = clientData?.[fields.customerId];
        const platformPaymentMethodId = clientData?.[fields.paymentMethod];

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
            application_fee_amount: 70,
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
 */
exports.captureOrderPayment = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"] }, async (request) => {
    const { orderId } = request.data;
    const { stripe } = await getStripeInstance();
    try {
        const orderDoc = await admin.firestore().collection("orders").doc(orderId).get();
        const orderData = orderDoc.data();

        // 🛡️ BYPASS VIP: Si la orden fue marcada como VIP, no llamamos a Stripe
        if (orderData?.isVipOrder === true) {
            console.log("💎 VIP DETECTADO: Capturando orden sin cobro real.");
            await admin.firestore().collection("orders").doc(orderId).update({
                paymentStatus: 'captured',
                capturedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            return { success: true, isVip: true };
        }

        const piId = orderData?.stripePaymentIntentId;
        const driverDoc = await admin.firestore().collection("users").doc(orderData.assignedMessengerId).get();
        const mode = (await admin.firestore().collection("admin_settings").doc("stripe").get()).data()?.stripe_mode || "test";
        const stripeAccountId = mode === "live" ? driverDoc.data()?.stripeAccountIdLive : driverDoc.data()?.stripeAccountId;

        if (!piId || !stripeAccountId) throw new Error("Faltan datos de pago o cuenta del driver.");

        await stripe.paymentIntents.capture(piId, {}, { stripeAccount: stripeAccountId });
        await admin.firestore().collection("orders").doc(orderId).update({
            paymentStatus: 'captured',
            feeCharged: 70,
            capturedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        return { success: true };
    } catch (error) { return { success: false, error: error.message }; }
});

/**
 * 💳 6. CANCELAR (CANCEL)
 */
exports.cancelOrderPayment = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"] }, async (request) => {
    const { orderId } = request.data;
    const { stripe } = await getStripeInstance();
    try {
        const orderDoc = await admin.firestore().collection("orders").doc(orderId).get();
        const orderData = orderDoc.data();

        // 🛡️ BYPASS VIP: Si la orden fue marcada como VIP
        if (orderData?.isVipOrder === true) {
            await admin.firestore().collection("orders").doc(orderId).update({ paymentStatus: 'cancelled' });
            return { success: true, isVip: true };
        }

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
 */
exports.createSetupIntent = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"] }, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "No logueado.");
    const uid = request.auth.uid;
    const { stripe, fields } = await getStripeInstance();

    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        let customerId = userDoc.data()?.[fields.customerId];

        if (!customerId) {
            const customer = await stripe.customers.create({ email: request.auth.token.email, metadata: { firebaseUid: uid } });
            customerId = customer.id;
            await admin.firestore().collection("users").doc(uid).update({ [fields.customerId]: customerId });
        }

        const ephemeralKey = await stripe.ephemeralKeys.create({ customer: customerId }, { apiVersion: '2022-11-15' });
        const setupIntent = await stripe.setupIntents.create({ customer: customerId, payment_method_types: ['card'] });
        return { setupIntentClientSecret: setupIntent.client_secret, customerId: customerId, ephemeralKeySecret: ephemeralKey.secret };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 💳 8. DASHBOARD LOGIN LINK
 */
exports.createStripeLoginLink = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"] }, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "No logueado.");
    const uid = request.auth.uid;
    const { stripe, fields } = await getStripeInstance();

    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const stripeAccountId = userDoc.data()?.[fields.accountId];
        if (!stripeAccountId) throw new Error("No tienes cuenta de Stripe vinculada.");
        const loginLink = await stripe.accounts.createLoginLink(stripeAccountId);
        return { url: loginLink.url };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 🗑️ 9. ELIMINAR CUENTA
 */
exports.deleteUserAccount = onCall({ region: REGION, invoker: "public" }, async (request) => {
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
 */
exports.syncPaymentMethod = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"] }, async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "No logueado.");
    const { stripe, fields } = await getStripeInstance();

    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const customerId = userDoc.data()?.[fields.customerId];
        if (!customerId) throw new Error("No hay CustomerId.");
        const paymentMethods = await stripe.paymentMethods.list({ customer: customerId, type: 'card' });
        if (paymentMethods.data.length > 0) {
            const latestMethodId = paymentMethods.data[0].id;
            await admin.firestore().collection("users").doc(uid).update({ [fields.paymentMethod]: latestMethodId });
            return { success: true, methodId: latestMethodId };
        }
        return { success: false, error: "No se encontraron tarjetas." };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 🔄 11. SINCRONIZACIÓN MANUAL STRIPE (STATUS DRIVER)
 */
exports.syncStripeStatus = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"] }, async (request) => {
    const uid = request.auth?.uid || request.data?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "No logueado.");
    const { stripe, fields } = await getStripeInstance();

    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const stripeAccountId = userDoc.data()?.[fields.accountId];
        if (!stripeAccountId) return { status: 'no_account' };
        const account = await stripe.accounts.retrieve(stripeAccountId);
        const isActive = account.details_submitted && account.charges_enabled;

        await admin.firestore().collection("users").doc(uid).update({
            [fields.status]: isActive ? 'active' : 'pending',
            isStripeConnected: isActive
        });
        return { status: isActive ? 'active' : 'pending' };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 💳 12. WEBHOOK DE STRIPE: EL VIGILANTE SOBERANO (V17.0)
 */
exports.stripeWebhook = onRequest({
    region: REGION,
    secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"]
}, async (req, res) => {
    const { stripe } = await getStripeInstance();
    let event = req.body;

    try {
        if (event.type === 'account.updated') {
            const account = event.data.object;
            const uid = account.metadata.firebaseUid;

            if (uid && account.requirements.currently_due.length > 0) {
                const userDoc = await admin.firestore().collection("users").doc(uid).get();
                const fcmToken = userDoc.data()?.fcmToken;

                if (fcmToken) {
                    await admin.messaging().send({
                        notification: {
                            title: "🏦 ACCIÓN BANCARIA REQUERIDA",
                            body: "Stripe necesita información adicional para habilitar tus pagos. Entra a tu perfil."
                        },
                        android: { priority: "high" },
                        token: fcmToken,
                    });
                }
            }

            const isActive = account.details_submitted && account.charges_enabled;
            await admin.firestore().collection("users").doc(uid).update({
                stripeStatusLive: isActive ? 'active' : 'pending',
                isStripeConnected: isActive
            });
        }

        if (event.type === 'payment_intent.succeeded') {
            const pi = event.data.object;
            const orderId = pi.metadata.orderId;
            if (orderId) {
                await admin.firestore().collection("orders").doc(orderId).update({
                    paymentStatus: 'captured',
                    stripeChargeId: pi.id
                });
            }
        }

        res.status(200).json({ received: true });
    } catch (err) {
        console.error(`❌ Webhook Error: ${err.message}`);
        res.status(400).send(`Webhook Error: ${err.message}`);
    }
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
 * 💳 15. COBRO DIRECTO (SAAS MODEL)
 */
exports.processImmediatePayment = onCall({ region: REGION, invoker: "public", secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"] }, async (request) => {
    const { amount, driverStripeAccountId, orderId } = request.data;
    const { stripe, fields } = await getStripeInstance();

    try {
        const orderRef = admin.firestore().collection("orders").doc(orderId);
        const orderDoc = await orderRef.get();
        if (!orderDoc.exists) throw new Error("La orden no existe.");
        const orderData = orderDoc.data();
        const clientDoc = await admin.firestore().collection("users").doc(orderData.clientId).get();
        const clientData = clientDoc.data();

        // 🛡️ BYPASS VIP: Si el cliente es inspector
        if (clientData?.isVipTester === true) {
            console.log("💎 VIP DETECTADO: Procesando cobro directo simbólico.");
            await orderRef.update({
                paymentStatus: 'captured',
                isVipOrder: true,
                completedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            return { success: true, isVip: true };
        }

        const platformCustomerId = clientData?.[fields.customerId];
        const platformPaymentMethodId = clientData?.[fields.paymentMethod];

        if (!platformCustomerId || !platformPaymentMethodId) throw new Error("Falta método de pago.");

        const mirror = await stripe.customers.create({ email: clientDoc.data().email }, { stripeAccount: driverStripeAccountId });
        const clonedMethod = await stripe.paymentMethods.create({
            payment_method: platformPaymentMethodId,
            customer: platformCustomerId,
        }, { stripeAccount: driverStripeAccountId });

        await stripe.paymentMethods.attach(clonedMethod.id, { customer: mirror.id }, { stripeAccount: driverStripeAccountId });

        const charge = await stripe.paymentIntents.create({
            amount,
            currency: 'usd',
            customer: mirror.id,
            payment_method: clonedMethod.id,
            confirm: true,
            off_session: true,
            application_fee_amount: 70,
            metadata: { orderId, type: 'LAD_DIRECT_CHARGE_V6_FINAL' }
        }, { stripeAccount: driverStripeAccountId });

        await orderRef.update({
            paymentStatus: 'captured',
            stripePaymentIntentId: charge.id,
            completedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return { success: true, chargeId: charge.id };
    } catch (error) {
        return { success: false, error: error.message };
    }
});

/**
 * 💳 17. STRIPE IDENTITY
 */
exports.createIdentitySession = onCall({
    region: REGION,
    invoker: "public",
    enforceAppCheck: false,
    secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"]
}, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sesión requerida.");
    const { stripe } = await getStripeInstance();

    try {
        const session = await stripe.identity.verificationSessions.create({
            type: 'document',
            metadata: { firebaseUid: request.auth.uid },
        });

        return {
            url: session.url,
            sessionId: session.id
        };
    } catch (error) {
        throw new HttpsError("internal", error.message);
    }
});

/**
 * 💳 18. WEB SETUP SESSION
 */
exports.createWebSetupSession = onCall({
    region: REGION,
    invoker: "public",
    secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"]
}, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sesión requerida.");
    const { stripe, fields } = await getStripeInstance();
    const uid = request.auth.uid;

    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        let customerId = userDoc.data()?.[fields.customerId];

        if (!customerId) {
            const customer = await stripe.customers.create({
                email: request.auth.token.email,
                metadata: { firebaseUid: uid }
            });
            customerId = customer.id;
            await admin.firestore().collection("users").doc(uid).update({ [fields.customerId]: customerId });
        }

        const session = await stripe.checkout.sessions.create({
            payment_method_types: ['card'],
            mode: 'setup',
            customer: customerId,
            success_url: 'https://ladcourier.com/#/profile?setup=success',
            cancel_url: 'https://ladcourier.com/#/profile?setup=cancel',
        });

        return { url: session.url };
    } catch (error) {
        throw new HttpsError("internal", error.message);
    }
});

/**
 * 🛡️ 19. AUDITORÍA FORENSE (VISION)
 */
exports.verifyLivenessCloud = onCall({
    region: REGION,
    invoker: "public",
    secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"]
}, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sesión requerida.");
    const { imageUrl } = request.data;
    const client = new vision.ImageAnnotatorClient();
    try {
        const [result] = await client.faceDetection({ image: { source: { imageUri: imageUrl } } });
        const faces = result.faceAnnotations;
        if (!faces || faces.length === 0) return { success: false, error: "No rostro." };
        return { success: true, confidence: faces[0].detectionConfidence };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 🛰️ 20. MOTOR OCR CLOUD
 */
exports.analyzeReceiptCloud = onCall({ region: REGION, invoker: "public" }, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sesión requerida.");
    const { imageUrl } = request.data;
    const client = new vision.ImageAnnotatorClient();
    try {
        const [result] = await client.textDetection({ image: { source: { imageUri: imageUrl } } });
        const fullText = result.fullTextAnnotation ? result.fullTextAnnotation.text : "";
        if (!fullText) return { success: false, error: "No texto." };
        return { success: true, rawText: fullText };
    } catch (error) { throw new HttpsError("internal", error.message); }
});

/**
 * 🧹 16. EL GRAN BARRENDERO LAD (ÚNICO RELOJ SOBERANO)
 */
exports.autoLADSystemCleanup = onSchedule({
    schedule: "every 5 minutes",
    region: REGION,
    secrets: ["STRIPE_SECRET_TEST", "STRIPE_SECRET_LIVE"]
}, async (event) => {
    const db = admin.firestore();
    const batch = db.batch();
    let totalOpCount = 0;

    const orderExpiry = 30 * 60 * 1000;
    const rejectedOrderExpiry = 24 * 60 * 60 * 1000;
    const completedOrderExpiry = 10 * 24 * 60 * 60 * 1000; // 🛡️ SOBERANÍA: 10 días de auditoría

    const ordersSnapshot = await db.collection("orders")
        .where("status", "in", ["rejected", "cancelled", "negotiating", "price_proposed", "en_route_to_pickup", "picked_up", "completed"])
        .get();

    for (const doc of ordersSnapshot.docs) {
        const data = doc.data();
        const nowMs = admin.firestore().Timestamp.now().toMillis();
        const lastUpdate = data.updatedAt ? data.updatedAt.toMillis() : data.createdAt.toMillis();

        let currentExpiry = orderExpiry;
        if (data.status === "rejected") currentExpiry = rejectedOrderExpiry;
        if (data.status === "completed") currentExpiry = completedOrderExpiry;

        if ((nowMs - lastUpdate) > currentExpiry) {
            batch.delete(doc.ref);
            totalOpCount++;
        }
    }

    const chatExpiry = 10 * 24 * 60 * 60 * 1000; // 🛡️ Chats también viven 10 días
    const chatsSnapshot = await db.collection("chats").get();
    for (const chatDoc of chatsSnapshot.docs) {
        if (totalOpCount >= 450) break;
        const lastTimestamp = chatDoc.data().lastTimestamp ? chatDoc.data().lastTimestamp.toMillis() : 0;
        if (admin.firestore.Timestamp.now().toMillis() - lastTimestamp > chatExpiry) {
            batch.delete(chatDoc.ref);
            totalOpCount++;
        }
    }

    if (totalOpCount > 0) await batch.commit();
});
