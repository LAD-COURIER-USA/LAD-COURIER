const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
    admin.initializeApp();
}

// --- HELPERS PARA CARGA PERESOZA ---
let stripeInstance;
function getStripe() {
    if (!stripeInstance) {
        // 🛡️ SISTEMA LAD: La llave secreta ahora se lee de las variables de entorno de Firebase.
        // NO dejar llaves harcodeadas en el código para evitar bloqueos de GitHub.
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
 * 🛡️ VÍNCULO INVISIBLE DE INVITACIÓN
 */
exports.logReferral = onRequest({ invoker: "public" }, async (req, res) => {
    const driverId = req.query.id;
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;

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
 * 🛡️ VALIDACIÓN BIOMÉTRICA REFORZADA (AMAZON REKOGNITION)
 */
exports.verifyBiometricIdentity = onCall({
    invoker: "public",
    secrets: ["STRIPE_SECRET_TEST"]
}, async (request) => {
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
        logger.error("❌ Error Rekognition:", error);
        throw new HttpsError("internal", error.message);
    }
});

/**
 * 💳 1. STRIPE CONNECT: ONBOARDING (EXPRESS)
 */
exports.createStripeAccount = onCall({
    invoker: "public",
    secrets: ["STRIPE_SECRET_TEST"]
}, async (request) => {
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
                capabilities: {
                    card_payments: { requested: true },
                    transfers: { requested: true },
                },
                metadata: { firebaseUid: uid }
            });
            stripeAccountId = account.id;
            await admin.firestore().collection("users").doc(uid).update({
                stripeAccountId,
                stripeStatus: 'pending'
            });
        }

        console.log(`[AUDITORÍA B] Creando link para cuenta: ${stripeAccountId}`);
        const accountLink = await stripe.accountLinks.create({
            account: stripeAccountId,
            refresh_url: 'https://ladcourier.com/stripe-return',
            return_url: 'https://ladcourier.com/stripe-return',
            type: 'account_onboarding',
        });
        console.log(`[AUDITORÍA C] URL Generada por Stripe: ${accountLink.url}`);

        return { url: accountLink.url };
    } catch (error) {
        throw new HttpsError("internal", error.message);
    }
});

/**
 * 💳 2. RETENCIÓN (HOLD): RESERVAR FONDOS ANTES DE RECOGER
 */
exports.authorizeOrderPayment = onCall({
    invoker: "public",
    secrets: ["STRIPE_SECRET_TEST"]
}, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "No logueado.");
    const { amount, driverStripeAccountId, orderId, paymentMethodId, customerId } = request.data;
    const stripe = getStripe();

    try {
        const stripe = getStripe();

        /**
         * ⚖️ NOTA CONTABLE PARA LAD DIGITAL SYSTEMS LLC:
         * El 'totalApplicationFee' incluye los $0.50 netos de LAD + la comisión de Stripe (2.9% + $0.30).
         * Se cobra así para que el Driver absorba el costo de procesamiento y LAD reciba sus $0.50 íntegros.
         * Para la declaración de impuestos:
         * Ingreso Bruto = totalApplicationFee | Gasto (Stripe Fee) = stripeFee | Utilidad Neta = $0.50
         */
        const stripeFee = Math.round(amount * 0.029 + 30);
        const ladFee = 50;
        const totalApplicationFee = ladFee + stripeFee;

        const paymentIntent = await stripe.paymentIntents.create({
            amount,
            currency: 'usd',
            payment_method: paymentMethodId,
            customer: customerId,
            capture_method: 'manual',
            confirm: true,
            off_session: true,
            application_fee_amount: totalApplicationFee,
            transfer_data: { destination: driverStripeAccountId },
            on_behalf_of: driverStripeAccountId,
            metadata: {
                orderId: orderId,
                type: 'LAD_HOLD',
                lad_net_profit: "0.50",
                stripe_processing_fee: (stripeFee / 100).toFixed(2)
            }
        });

        await admin.firestore().collection("orders").doc(orderId).update({
            stripePaymentIntentId: paymentIntent.id,
            paymentStatus: 'authorized',
            totalFeeCharged: totalApplicationFee, // Registro total para auditoría
            ladNetProfit: 50 // Registro neto para reportes rápidos
        });

        return { success: true, paymentIntentId: paymentIntent.id };
    } catch (error) {
        return { success: false, error: error.message };
    }
});

/**
 * 💳 3. COBRO (CAPTURE): EJECUTAR EL COBRO AL ENTREGAR
 */
exports.captureOrderPayment = onCall({
    invoker: "public",
    secrets: ["STRIPE_SECRET_TEST"]
}, async (request) => {
    const { orderId } = request.data;
    const stripe = getStripe();
    try {
        const orderDoc = await admin.firestore().collection("orders").doc(orderId).get();
        const piId = orderDoc.data()?.stripePaymentIntentId;

        if (!piId) throw new Error("No hay PaymentIntent para capturar.");

        await stripe.paymentIntents.capture(piId);

        await admin.firestore().collection("orders").doc(orderId).update({
            paymentStatus: 'captured',
            feeCharged: 50
        });

        return { success: true };
    } catch (error) {
        return { success: false, error: error.message };
    }
});

/**
 * 💳 4. SETUP INTENT (CLIENTES GUARDANDO TARJETA)
 */
exports.createSetupIntent = onCall({
    invoker: "public",
    secrets: ["STRIPE_SECRET_TEST"]
}, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "No logueado.");
    const uid = request.auth.uid;
    const stripe = getStripe();

    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        let customerId = userDoc.data()?.stripeCustomerId;

        if (!customerId) {
            const customer = await stripe.customers.create({
                email: request.auth.token.email,
                metadata: { firebaseUid: uid }
            });
            customerId = customer.id;
            await admin.firestore().collection("users").doc(uid).update({ stripeCustomerId: customerId });
        }

        const ephemeralKey = await stripe.ephemeralKeys.create({ customer: customerId }, { apiVersion: '2022-11-15' });
        const setupIntent = await stripe.setupIntents.create({ customer: customerId, payment_method_types: ['card'] });

        return {
            setupIntentClientSecret: setupIntent.client_secret,
            customerId: customerId,
            ephemeralKeySecret: ephemeralKey.secret
        };
    } catch (error) {
        throw new HttpsError("internal", error.message);
    }
});

/**
 * 💳 5. DASHBOARD LOGIN LINK (EXPRESS)
 */
exports.createStripeLoginLink = onCall({
    invoker: "public",
    secrets: ["STRIPE_SECRET_TEST"]
}, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "No logueado.");
    const uid = request.auth.uid;
    const stripe = getStripe();

    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const stripeAccountId = userDoc.data()?.stripeAccountId;
        if (!stripeAccountId) throw new Error("No tienes cuenta de Stripe vinculada.");

        const loginLink = await stripe.accounts.createLoginLink(stripeAccountId);
        return { url: loginLink.url };
    } catch (error) {
        throw new HttpsError("internal", error.message);
    }
});

/**
 * 🗑️ ELIMINAR CUENTA (LIMPIEZA TOTAL)
 */
exports.deleteUserAccount = onCall({
    invoker: "public",
    secrets: ["STRIPE_SECRET_TEST"]
}, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Debe iniciar sesión.");
    const uid = request.auth.uid;
    const stripe = getStripe();

    try {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const stripeAccountId = userDoc.data()?.stripeAccountId;

        if (stripeAccountId) {
            try { await stripe.accounts.del(stripeAccountId); } catch (e) {}
        }
        await admin.firestore().collection("users").doc(uid).delete();
        await admin.auth().deleteUser(uid);
        return { success: true };
    } catch (error) {
        throw new HttpsError("internal", error.message);
    }
});

/**
 * 🔄 SINCRONIZACIÓN MANUAL DE MÉTODO DE PAGO (CLIENTES)
 */
exports.syncPaymentMethod = onCall({
    invoker: "public",
    secrets: ["STRIPE_SECRET_TEST"]
}, async (request) => {
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
            await admin.firestore().collection("users").doc(uid).update({
                defaultPaymentMethodId: latestMethodId,
                lastPaymentMethodUpdate: admin.firestore.FieldValue.serverTimestamp()
            });
            return { success: true, methodId: latestMethodId };
        }
        return { success: false, error: "No se encontraron tarjetas." };
    } catch (error) {
        throw new HttpsError("internal", error.message);
    }
});

/**
 * 🔄 SINCRONIZACIÓN MANUAL STRIPE (DRIVERS)
 */
exports.syncStripeStatus = onCall({
    invoker: "public",
    secrets: ["STRIPE_SECRET_TEST"]
}, async (request) => {
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
            await admin.firestore().collection("users").doc(uid).update({
                stripeStatus: 'active',
                isStripeConnected: true,
                verificationStatus: 'APROBADO_DOC'
            });
        }
        return { status: isActive ? 'active' : 'pending' };
    } catch (error) {
        throw new HttpsError("internal", error.message);
    }
});

/**
 * 2. WEBHOOK DE STRIPE
 */
exports.stripeWebhook = onRequest({
    invoker: "public",
    secrets: ["STRIPE_SECRET_TEST", "STRIPE_WEBHOOK_SECRET_TEST"]
}, async (req, res) => {
    const sig = req.headers['stripe-signature'];
    const secret = process.env.STRIPE_WEBHOOK_SECRET_TEST;
    try {
        const event = getStripe().webhooks.constructEvent(req.rawBody, sig, secret);
        // ... Lógica de webhook ...
        res.status(200).json({received: true});
    } catch (err) {
        res.status(200).send("Webhook Error");
    }
});

/**
 * 🔔 NOTIFICACIONES
 */
exports.notifyDriverOnNewOrder = onDocumentCreated("orders/{orderId}", async (event) => {
    const orderData = event.data.data();
    const driverId = orderData.driverId;
    if (driverId) {
        const driverDoc = await admin.firestore().collection("users").doc(driverId).get();
        const fcmToken = driverDoc.data()?.fcmToken;
        if (fcmToken) {
            const message = {
                notification: { title: "¡Nueva Orden!", body: `Nueva solicitud de ${orderData.clientName || 'Cliente'}.` },
                token: fcmToken,
            };
            try { await admin.messaging().send(message); } catch (e) {}
        }
    }
});
