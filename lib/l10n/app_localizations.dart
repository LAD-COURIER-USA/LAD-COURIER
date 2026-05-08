import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ht.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ht'),
    Locale('pt'),
  ];

  /// No description provided for @earnings_title.
  ///
  /// In es, this message translates to:
  /// **'ZONAS DE TRABAJO'**
  String get earnings_title;

  /// No description provided for @earnings_period_today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get earnings_period_today;

  /// No description provided for @earnings_period_week.
  ///
  /// In es, this message translates to:
  /// **'Esta Semana'**
  String get earnings_period_week;

  /// No description provided for @earnings_period_month.
  ///
  /// In es, this message translates to:
  /// **'Mes Actual'**
  String get earnings_period_month;

  /// No description provided for @earnings_period_year.
  ///
  /// In es, this message translates to:
  /// **'Año Fiscal'**
  String get earnings_period_year;

  /// No description provided for @earnings_stat_gross.
  ///
  /// In es, this message translates to:
  /// **'INGRESOS BRUTOS'**
  String get earnings_stat_gross;

  /// No description provided for @earnings_stat_miles.
  ///
  /// In es, this message translates to:
  /// **'MILLAS FISCALES'**
  String get earnings_stat_miles;

  /// No description provided for @earnings_stat_missions.
  ///
  /// In es, this message translates to:
  /// **'MISIONES'**
  String get earnings_stat_missions;

  /// No description provided for @earnings_stat_efficiency.
  ///
  /// In es, this message translates to:
  /// **'EFECTIVIDAD'**
  String get earnings_stat_efficiency;

  /// No description provided for @earnings_history_title.
  ///
  /// In es, this message translates to:
  /// **'HISTORIAL DE MISIONES'**
  String get earnings_history_title;

  /// No description provided for @earnings_empty_history.
  ///
  /// In es, this message translates to:
  /// **'Sin misiones en este periodo.'**
  String get earnings_empty_history;

  /// No description provided for @earnings_network_title.
  ///
  /// In es, this message translates to:
  /// **'MI RADIO DE ACCIÓN'**
  String get earnings_network_title;

  /// No description provided for @earnings_linked_users.
  ///
  /// In es, this message translates to:
  /// **'USUARIOS VINCULADOS'**
  String get earnings_linked_users;

  /// No description provided for @earnings_referrals_count.
  ///
  /// In es, this message translates to:
  /// **'Referidos'**
  String get earnings_referrals_count;

  /// No description provided for @earnings_plan_label.
  ///
  /// In es, this message translates to:
  /// **'ZONA SELECCIONADA'**
  String get earnings_plan_label;

  /// No description provided for @earnings_refund_title.
  ///
  /// In es, this message translates to:
  /// **'ESTADO DE ZONA'**
  String get earnings_refund_title;

  /// No description provided for @earnings_refund_covered.
  ///
  /// In es, this message translates to:
  /// **'ACTIVA'**
  String get earnings_refund_covered;

  /// No description provided for @earnings_refund_saving.
  ///
  /// In es, this message translates to:
  /// **'GRATIS'**
  String get earnings_refund_saving;

  /// No description provided for @earnings_refund_status_free_current.
  ///
  /// In es, this message translates to:
  /// **'ZONA SIN CARGO'**
  String get earnings_refund_status_free_current;

  /// No description provided for @earnings_refund_status_free_next.
  ///
  /// In es, this message translates to:
  /// **'CAMBIO DISPONIBLE'**
  String get earnings_refund_status_free_next;

  /// No description provided for @earnings_refund_goal_msg.
  ///
  /// In es, this message translates to:
  /// **'Configura tu radio de alcance libremente.'**
  String get earnings_refund_goal_msg;

  /// No description provided for @earnings_refund_success_msg.
  ///
  /// In es, this message translates to:
  /// **'Zona configurada correctamente.'**
  String get earnings_refund_success_msg;

  /// No description provided for @earnings_refund_pending_msg.
  ///
  /// In es, this message translates to:
  /// **'Configuración en curso...'**
  String get earnings_refund_pending_msg;

  /// No description provided for @earnings_refund_anti_fraud_rule.
  ///
  /// In es, this message translates to:
  /// **'El cambio de zona es instantáneo y sin costo.'**
  String get earnings_refund_anti_fraud_rule;

  /// No description provided for @earnings_refund_disclaimer.
  ///
  /// In es, this message translates to:
  /// **'LAD Courier no cobra mensualidad. Solo un service fee de 0.50 \$ por orden exitosa, sin importar precio pactado.'**
  String get earnings_refund_disclaimer;

  /// No description provided for @driver_dash_title.
  ///
  /// In es, this message translates to:
  /// **'CENTRO DE MANDO DRIVER'**
  String get driver_dash_title;

  /// No description provided for @driver_status_online.
  ///
  /// In es, this message translates to:
  /// **'DRIVER EN LÍNEA'**
  String get driver_status_online;

  /// No description provided for @driver_status_offline.
  ///
  /// In es, this message translates to:
  /// **'FUERA DE SERVICIO'**
  String get driver_status_offline;

  /// No description provided for @driver_btn_work_zone.
  ///
  /// In es, this message translates to:
  /// **'MAPA OPERATIVO'**
  String get driver_btn_work_zone;

  /// No description provided for @driver_menu_services.
  ///
  /// In es, this message translates to:
  /// **'SERVICIOS'**
  String get driver_menu_services;

  /// No description provided for @driver_menu_profile.
  ///
  /// In es, this message translates to:
  /// **'MI PERFIL'**
  String get driver_menu_profile;

  /// No description provided for @driver_menu_earnings.
  ///
  /// In es, this message translates to:
  /// **'ZONAS'**
  String get driver_menu_earnings;

  /// No description provided for @driver_menu_invite.
  ///
  /// In es, this message translates to:
  /// **'INVITAR'**
  String get driver_menu_invite;

  /// No description provided for @driver_dialog_services_title.
  ///
  /// In es, this message translates to:
  /// **'SERVICIOS ACTIVOS'**
  String get driver_dialog_services_title;

  /// No description provided for @driver_btn_confirm.
  ///
  /// In es, this message translates to:
  /// **'CONFIRMAR'**
  String get driver_btn_confirm;

  /// No description provided for @driver_error_no_photo.
  ///
  /// In es, this message translates to:
  /// **'FALTA FOTO DE PERFIL'**
  String get driver_error_no_photo;

  /// No description provided for @driver_error_no_photo_msg.
  ///
  /// In es, this message translates to:
  /// **'Debes subir una foto profesional para que tus clientes puedan identificarte.'**
  String get driver_error_no_photo_msg;

  /// No description provided for @driver_error_incomplete_data.
  ///
  /// In es, this message translates to:
  /// **'DATOS INCOMPLETOS'**
  String get driver_error_incomplete_data;

  /// No description provided for @driver_error_incomplete_data_msg.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre y teléfono son obligatorios para la seguridad del servicio.'**
  String get driver_error_incomplete_data_msg;

  /// No description provided for @driver_error_no_vehicle.
  ///
  /// In es, this message translates to:
  /// **'DETALLE DEL VEHÍCULO'**
  String get driver_error_no_vehicle;

  /// No description provided for @driver_error_no_vehicle_msg.
  ///
  /// In es, this message translates to:
  /// **'Describe tu medio de transporte en la sección Mi Perfil.'**
  String get driver_error_no_vehicle_msg;

  /// No description provided for @driver_error_no_membership.
  ///
  /// In es, this message translates to:
  /// **'ZONA NO SELECCIONADA'**
  String get driver_error_no_membership;

  /// No description provided for @driver_error_no_membership_msg.
  ///
  /// In es, this message translates to:
  /// **'Debes seleccionar una \'Zona de Trabajo\' (Lite, Standard o Pro) para recibir órdenes.'**
  String get driver_error_no_membership_msg;

  /// No description provided for @driver_error_no_stripe.
  ///
  /// In es, this message translates to:
  /// **'STRIPE NO VINCULADO'**
  String get driver_error_no_stripe;

  /// No description provided for @driver_error_no_stripe_msg.
  ///
  /// In es, this message translates to:
  /// **'Para ponerte online, debes configurar tu cuenta de Stripe Connect en \'Mi Perfil\'.'**
  String get driver_error_no_stripe_msg;

  /// No description provided for @driver_error_no_verification.
  ///
  /// In es, this message translates to:
  /// **'VERIFICACIÓN PENDIENTE'**
  String get driver_error_no_verification;

  /// No description provided for @driver_error_no_verification_msg.
  ///
  /// In es, this message translates to:
  /// **'Debes completar tu verificación de identidad y background check para ponerte online.'**
  String get driver_error_no_verification_msg;

  /// No description provided for @driver_error_no_services.
  ///
  /// In es, this message translates to:
  /// **'SIN SERVICIOS ACTIVOS'**
  String get driver_error_no_services;

  /// No description provided for @driver_error_no_services_msg.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos un servicio antes de ponerte en línea.'**
  String get driver_error_no_services_msg;

  /// No description provided for @driver_active_missions_alert.
  ///
  /// In es, this message translates to:
  /// **'⚠️ TIENES MISIONES ACTIVAS. Termínalas primero.'**
  String get driver_active_missions_alert;

  /// No description provided for @driver_btn_understand.
  ///
  /// In es, this message translates to:
  /// **'ENTENDIDO'**
  String get driver_btn_understand;

  /// No description provided for @driver_selection_title.
  ///
  /// In es, this message translates to:
  /// **'Elegir Driver'**
  String get driver_selection_title;

  /// No description provided for @driver_card_plan.
  ///
  /// In es, this message translates to:
  /// **'Zona'**
  String get driver_card_plan;

  /// No description provided for @driver_card_coverage.
  ///
  /// In es, this message translates to:
  /// **'Cobertura'**
  String get driver_card_coverage;

  /// No description provided for @driver_selection_no_drivers_title.
  ///
  /// In es, this message translates to:
  /// **'Lo sentimos'**
  String get driver_selection_no_drivers_title;

  /// No description provided for @driver_selection_no_drivers_body.
  ///
  /// In es, this message translates to:
  /// **'No hay drivers disponibles cuyo rango de trabajo cubra estas direcciones. Intenta con un trayecto más corto.'**
  String get driver_selection_no_drivers_body;

  /// No description provided for @notification_order_sent_success.
  ///
  /// In es, this message translates to:
  /// **'Misión enviada al driver'**
  String get notification_order_sent_success;

  /// No description provided for @prof_title.
  ///
  /// In es, this message translates to:
  /// **'MI PERFIL OPERATIVO'**
  String get prof_title;

  /// No description provided for @prof_radar_title.
  ///
  /// In es, this message translates to:
  /// **'MI RADAR DE RECLUTAMIENTO'**
  String get prof_radar_title;

  /// No description provided for @prof_radar_body.
  ///
  /// In es, this message translates to:
  /// **'Tus clientes escanean este QR para vincularse a tu red personal.'**
  String get prof_radar_body;

  /// No description provided for @prof_section_id.
  ///
  /// In es, this message translates to:
  /// **'DATOS DE IDENTIFICACIÓN'**
  String get prof_section_id;

  /// No description provided for @prof_label_name.
  ///
  /// In es, this message translates to:
  /// **'Nombre Completo'**
  String get prof_label_name;

  /// No description provided for @prof_label_phone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono de Contacto'**
  String get prof_label_phone;

  /// No description provided for @prof_label_vehicle.
  ///
  /// In es, this message translates to:
  /// **'Descripción del Vehículo'**
  String get prof_label_vehicle;

  /// No description provided for @prof_section_mem.
  ///
  /// In es, this message translates to:
  /// **'ZONAS DE TRABAJO'**
  String get prof_section_mem;

  /// No description provided for @prof_section_pay.
  ///
  /// In es, this message translates to:
  /// **'HERRAMIENTAS DE PAGO (STRIPE)'**
  String get prof_section_pay;

  /// No description provided for @prof_pay_stripe.
  ///
  /// In es, this message translates to:
  /// **'Vincular Stripe Connect'**
  String get prof_pay_stripe;

  /// No description provided for @prof_pay_stripe_sub.
  ///
  /// In es, this message translates to:
  /// **'Para recibir tus pagos al instante'**
  String get prof_pay_stripe_sub;

  /// No description provided for @prof_pay_paypal.
  ///
  /// In es, this message translates to:
  /// **'PayPal (Opcional)'**
  String get prof_pay_paypal;

  /// No description provided for @prof_pay_paypal_sub.
  ///
  /// In es, this message translates to:
  /// **'Solo para cobros manuales'**
  String get prof_pay_paypal_sub;

  /// No description provided for @prof_btn_save.
  ///
  /// In es, this message translates to:
  /// **'GUARDAR CAMBIOS'**
  String get prof_btn_save;

  /// No description provided for @prof_btn_switch.
  ///
  /// In es, this message translates to:
  /// **'CAMBIAR A MODO CLIENTE'**
  String get prof_btn_switch;

  /// No description provided for @work_title.
  ///
  /// In es, this message translates to:
  /// **'MAPA DE OPERACIONES'**
  String get work_title;

  /// No description provided for @work_panel_title.
  ///
  /// In es, this message translates to:
  /// **'SOLICITUDES PENDIENTES'**
  String get work_panel_title;

  /// No description provided for @work_waiting.
  ///
  /// In es, this message translates to:
  /// **'Esperando nuevas misiones...'**
  String get work_waiting;

  /// No description provided for @work_alert_title.
  ///
  /// In es, this message translates to:
  /// **'🚀 ¡NUEVA MISIÓN DETECTADA!'**
  String get work_alert_title;

  /// No description provided for @work_alert_body.
  ///
  /// In es, this message translates to:
  /// **'Tienes una nueva solicitud en el radar.'**
  String get work_alert_body;

  /// No description provided for @work_notif_channel_name.
  ///
  /// In es, this message translates to:
  /// **'Alertas de Pedidos Urgentes'**
  String get work_notif_channel_name;

  /// No description provided for @work_notif_channel_desc.
  ///
  /// In es, this message translates to:
  /// **'Canal para notificaciones de misiones nuevas'**
  String get work_notif_channel_desc;

  /// No description provided for @sub_title.
  ///
  /// In es, this message translates to:
  /// **'ZONAS DE TRABAJO'**
  String get sub_title;

  /// No description provided for @sub_promo.
  ///
  /// In es, this message translates to:
  /// **'ELABORA TU PROPIA RUTA LIBREMENTE'**
  String get sub_promo;

  /// No description provided for @sub_free.
  ///
  /// In es, this message translates to:
  /// **'GRATIS'**
  String get sub_free;

  /// No description provided for @sub_radius.
  ///
  /// In es, this message translates to:
  /// **'Alcance: {radius}'**
  String sub_radius(String radius);

  /// No description provided for @sub_bonus.
  ///
  /// In es, this message translates to:
  /// **'Costo: {bonus}'**
  String sub_bonus(String bonus);

  /// No description provided for @sub_btn_activate.
  ///
  /// In es, this message translates to:
  /// **'ACTIVAR ZONA'**
  String get sub_btn_activate;

  /// No description provided for @welcome_title.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido a Bordo!'**
  String get welcome_title;

  /// No description provided for @welcome_body.
  ///
  /// In es, this message translates to:
  /// **'Para finalizar tu registro, por favor, elige tu rol en nuestra comunidad.'**
  String get welcome_body;

  /// No description provided for @welcome_btn_client.
  ///
  /// In es, this message translates to:
  /// **'Soy Cliente'**
  String get welcome_btn_client;

  /// No description provided for @welcome_btn_driver.
  ///
  /// In es, this message translates to:
  /// **'Soy Mensajero'**
  String get welcome_btn_driver;

  /// No description provided for @client_dash_title.
  ///
  /// In es, this message translates to:
  /// **'CENTRO DE MANDO CLIENTE'**
  String get client_dash_title;

  /// No description provided for @client_dash_welcome.
  ///
  /// In es, this message translates to:
  /// **'SISTEMA LAD COURIER'**
  String get client_dash_welcome;

  /// No description provided for @client_dash_requested_services.
  ///
  /// In es, this message translates to:
  /// **'SERVICIOS SOLICITADOS'**
  String get client_dash_requested_services;

  /// No description provided for @client_dash_no_requests.
  ///
  /// In es, this message translates to:
  /// **'Sin solicitudes pendientes.'**
  String get client_dash_no_requests;

  /// No description provided for @client_dash_new_request.
  ///
  /// In es, this message translates to:
  /// **'NUEVA SOLICITUD'**
  String get client_dash_new_request;

  /// No description provided for @client_dash_first_offer.
  ///
  /// In es, this message translates to:
  /// **'PRIMERA OFERTA RECIBIDA'**
  String get client_dash_first_offer;

  /// No description provided for @client_dash_counter_offer.
  ///
  /// In es, this message translates to:
  /// **'CONTRAOFERTA RECIBIDA'**
  String get client_dash_counter_offer;

  /// No description provided for @client_dash_driver_label.
  ///
  /// In es, this message translates to:
  /// **'Driver: {name}'**
  String client_dash_driver_label(String name);

  /// No description provided for @client_dash_active_missions.
  ///
  /// In es, this message translates to:
  /// **'MISIONES EN CURSO'**
  String get client_dash_active_missions;

  /// No description provided for @client_dash_price_label.
  ///
  /// In es, this message translates to:
  /// **'PRECIO: {price}'**
  String client_dash_price_label(String price);

  /// No description provided for @client_dash_status_label.
  ///
  /// In es, this message translates to:
  /// **'Status: {status}'**
  String client_dash_status_label(String status);

  /// No description provided for @client_dash_linked_drivers.
  ///
  /// In es, this message translates to:
  /// **'LISTADO DE DRIVERS'**
  String get client_dash_linked_drivers;

  /// No description provided for @client_dash_no_linked_drivers.
  ///
  /// In es, this message translates to:
  /// **'No tienes drivers vinculados.'**
  String get client_dash_no_linked_drivers;

  /// No description provided for @client_dash_driver_available.
  ///
  /// In es, this message translates to:
  /// **'DISPONIBLE'**
  String get client_dash_driver_available;

  /// No description provided for @client_dash_driver_resting.
  ///
  /// In es, this message translates to:
  /// **'EN DESCANSO'**
  String get client_dash_driver_resting;

  /// No description provided for @client_dash_services_label.
  ///
  /// In es, this message translates to:
  /// **'SERVICIOS: {services}'**
  String client_dash_services_label(String services);

  /// No description provided for @client_dash_plan_label.
  ///
  /// In es, this message translates to:
  /// **'ZONA: {plan}'**
  String client_dash_plan_label(String plan);

  /// No description provided for @client_dash_radius_label.
  ///
  /// In es, this message translates to:
  /// **'RADIO: {radius}'**
  String client_dash_radius_label(String radius);

  /// No description provided for @client_dash_no_phone.
  ///
  /// In es, this message translates to:
  /// **'Sin Tel'**
  String get client_dash_no_phone;

  /// No description provided for @client_dash_unlink_title.
  ///
  /// In es, this message translates to:
  /// **'DESVINCULAR DRIVER'**
  String get client_dash_unlink_title;

  /// No description provided for @client_dash_unlink_confirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar a {name} de tu lista de confianza?'**
  String client_dash_unlink_confirm(String name);

  /// No description provided for @client_dash_unlink_button.
  ///
  /// In es, this message translates to:
  /// **'DESVINCULAR'**
  String get client_dash_unlink_button;

  /// No description provided for @client_dash_unlink_success.
  ///
  /// In es, this message translates to:
  /// **'Driver desvinculado con éxito'**
  String get client_dash_unlink_success;

  /// No description provided for @client_dash_invite_title.
  ///
  /// In es, this message translates to:
  /// **'VINCULAR DRIVER'**
  String get client_dash_invite_title;

  /// No description provided for @client_dash_invite_hint.
  ///
  /// In es, this message translates to:
  /// **'Código o ID del Driver'**
  String get client_dash_invite_hint;

  /// No description provided for @common_confirm.
  ///
  /// In es, this message translates to:
  /// **'CONFIRMAR'**
  String get common_confirm;

  /// No description provided for @common_cancel.
  ///
  /// In es, this message translates to:
  /// **'CANCELAR'**
  String get common_cancel;

  /// No description provided for @client_prof_title.
  ///
  /// In es, this message translates to:
  /// **'MI PERFIL CLIENTE'**
  String get client_prof_title;

  /// No description provided for @client_prof_contact_details.
  ///
  /// In es, this message translates to:
  /// **'DATOS DE CONTACTO'**
  String get client_prof_contact_details;

  /// No description provided for @client_prof_name_label.
  ///
  /// In es, this message translates to:
  /// **'Nombre Completo'**
  String get client_prof_name_label;

  /// No description provided for @client_prof_phone_label.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get client_prof_phone_label;

  /// No description provided for @client_prof_address_label.
  ///
  /// In es, this message translates to:
  /// **'Dirección Principal'**
  String get client_prof_address_label;

  /// No description provided for @client_prof_payment_methods.
  ///
  /// In es, this message translates to:
  /// **'MÉTODOS DE PAGO'**
  String get client_prof_payment_methods;

  /// No description provided for @client_prof_stripe_title.
  ///
  /// In es, this message translates to:
  /// **'Stripe'**
  String get client_prof_stripe_title;

  /// No description provided for @client_prof_stripe_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta de Crédito/Débito'**
  String get client_prof_stripe_subtitle;

  /// No description provided for @client_prof_paypal_title.
  ///
  /// In es, this message translates to:
  /// **'PayPal'**
  String get client_prof_paypal_title;

  /// No description provided for @client_prof_paypal_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuenta Digital'**
  String get client_prof_paypal_subtitle;

  /// No description provided for @client_prof_cta_title.
  ///
  /// In es, this message translates to:
  /// **'¡GANA DINERO COMO DRIVER!'**
  String get client_prof_cta_title;

  /// No description provided for @client_prof_cta_body.
  ///
  /// In es, this message translates to:
  /// **'Únete a nuestra red de mensajeros y genera ingresos en tu tiempo libre.'**
  String get client_prof_cta_body;

  /// No description provided for @client_prof_cta_button.
  ///
  /// In es, this message translates to:
  /// **'VER ZONAS DRIVER'**
  String get client_prof_cta_button;

  /// No description provided for @client_prof_save_button.
  ///
  /// In es, this message translates to:
  /// **'GUARDAR CAMBIOS'**
  String get client_prof_save_button;

  /// No description provided for @client_prof_switch_button.
  ///
  /// In es, this message translates to:
  /// **'CAMBIAR A MODO DRIVER'**
  String get client_prof_switch_button;

  /// No description provided for @client_prof_update_success.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado'**
  String get client_prof_update_success;

  /// No description provided for @client_prof_update_error.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar: {error}'**
  String client_prof_update_error(String error);

  /// No description provided for @client_prof_completed_orders.
  ///
  /// In es, this message translates to:
  /// **'ÓRDENES COMPLETADAS'**
  String get client_prof_completed_orders;

  /// No description provided for @client_dash_history_title.
  ///
  /// In es, this message translates to:
  /// **'HISTORIAL DE MISIONES (36H)'**
  String get client_dash_history_title;

  /// No description provided for @order_details_title.
  ///
  /// In es, this message translates to:
  /// **'ORDEN {type} #{index}'**
  String order_details_title(String type, int index);

  /// No description provided for @order_details_id.
  ///
  /// In es, this message translates to:
  /// **'ID Orden: {id}'**
  String order_details_id(String id);

  /// No description provided for @order_details_pickup.
  ///
  /// In es, this message translates to:
  /// **'PUNTO DE RECOGIDA'**
  String get order_details_pickup;

  /// No description provided for @order_details_delivery.
  ///
  /// In es, this message translates to:
  /// **'PUNTO DE ENTREGA'**
  String get order_details_delivery;

  /// No description provided for @order_details_instructions.
  ///
  /// In es, this message translates to:
  /// **'INSTRUCCIONES DE LA MISIÓN'**
  String get order_details_instructions;

  /// No description provided for @order_details_no_instructions.
  ///
  /// In es, this message translates to:
  /// **'Sin instrucciones específicas del cliente.'**
  String get order_details_no_instructions;

  /// No description provided for @order_details_proximity_on.
  ///
  /// In es, this message translates to:
  /// **'¡ESTÁS EN EL LUGAR!'**
  String get order_details_proximity_on;

  /// No description provided for @order_details_proximity_off.
  ///
  /// In es, this message translates to:
  /// **'DISTANCIA AL PUNTO'**
  String get order_details_proximity_off;

  /// No description provided for @order_details_meters.
  ///
  /// In es, this message translates to:
  /// **'{meters} metros'**
  String order_details_meters(String meters);

  /// No description provided for @order_details_btn_go_pickup.
  ///
  /// In es, this message translates to:
  /// **'IR A RECOGIDA'**
  String get order_details_btn_go_pickup;

  /// No description provided for @order_details_btn_arrived.
  ///
  /// In es, this message translates to:
  /// **'LLEGUÉ / RECOGIDO'**
  String get order_details_btn_arrived;

  /// No description provided for @order_details_btn_go_delivery.
  ///
  /// In es, this message translates to:
  /// **'IR A ENTREGA'**
  String get order_details_btn_go_delivery;

  /// No description provided for @order_details_btn_photo.
  ///
  /// In es, this message translates to:
  /// **'TOMAR FOTO PRUEBA'**
  String get order_details_btn_photo;

  /// No description provided for @order_details_btn_finish.
  ///
  /// In es, this message translates to:
  /// **'FINALIZAR MISIÓN'**
  String get order_details_btn_finish;

  /// No description provided for @order_details_photo_success.
  ///
  /// In es, this message translates to:
  /// **'Foto capturada'**
  String get order_details_photo_success;

  /// No description provided for @order_details_evidence_msg.
  ///
  /// In es, this message translates to:
  /// **'Evidencia guardada con coordenadas GPS'**
  String get order_details_evidence_msg;

  /// No description provided for @order_details_btn_view_proof.
  ///
  /// In es, this message translates to:
  /// **'VER PRUEBA DE ENTREGA'**
  String get order_details_btn_view_proof;

  /// No description provided for @order_details_multiple_warning.
  ///
  /// In es, this message translates to:
  /// **'TIENES {count} ÓRDENES MÁS AQUÍ'**
  String order_details_multiple_warning(int count);

  /// No description provided for @neg_title.
  ///
  /// In es, this message translates to:
  /// **'NEGOCIACIÓN'**
  String get neg_title;

  /// No description provided for @neg_client_initial.
  ///
  /// In es, this message translates to:
  /// **'SOLICITUD INICIAL (SIN PRECIO)'**
  String get neg_client_initial;

  /// No description provided for @neg_client_counter.
  ///
  /// In es, this message translates to:
  /// **'CONTRAOFERTA DEL CLIENTE'**
  String get neg_client_counter;

  /// No description provided for @neg_driver_last.
  ///
  /// In es, this message translates to:
  /// **'TU ÚLTIMA OFERTA'**
  String get neg_driver_last;

  /// No description provided for @neg_input_label.
  ///
  /// In es, this message translates to:
  /// **'TU PROPUESTA (\$)'**
  String get neg_input_label;

  /// No description provided for @neg_btn_accept.
  ///
  /// In es, this message translates to:
  /// **'ACEPTAR'**
  String get neg_btn_accept;

  /// No description provided for @neg_btn_first.
  ///
  /// In es, this message translates to:
  /// **'PRIMERA OFERTA'**
  String get neg_btn_first;

  /// No description provided for @neg_btn_counter.
  ///
  /// In es, this message translates to:
  /// **'NUEVA CONTRAOFERTA'**
  String get neg_btn_counter;

  /// No description provided for @neg_btn_final.
  ///
  /// In es, this message translates to:
  /// **'ENVIAR OFERTA FINAL'**
  String get neg_btn_final;

  /// No description provided for @neg_btn_reject.
  ///
  /// In es, this message translates to:
  /// **'RECHAZAR Y CERRAR'**
  String get neg_btn_reject;

  /// No description provided for @neg_impact_single.
  ///
  /// In es, this message translates to:
  /// **'Esta orden representa un viaje total de {miles} millas.'**
  String neg_impact_single(String miles);

  /// No description provided for @neg_impact_multi.
  ///
  /// In es, this message translates to:
  /// **'Sumar esta orden añade {miles} millas extra a tu ruta.'**
  String neg_impact_multi(String miles);

  /// No description provided for @create_order_title.
  ///
  /// In es, this message translates to:
  /// **'CREAR LA ORDEN'**
  String get create_order_title;

  /// No description provided for @create_order_service_label.
  ///
  /// In es, this message translates to:
  /// **'Tipo de servicio disponible'**
  String get create_order_service_label;

  /// No description provided for @create_order_pickup_hint.
  ///
  /// In es, this message translates to:
  /// **'Origen (Dirección exacta)'**
  String get create_order_pickup_hint;

  /// No description provided for @create_order_dropoff_hint.
  ///
  /// In es, this message translates to:
  /// **'Destino (Dirección exacta)'**
  String get create_order_dropoff_hint;

  /// No description provided for @create_order_details_hint.
  ///
  /// In es, this message translates to:
  /// **'Detalles del paquete'**
  String get create_order_details_hint;

  /// No description provided for @create_order_pickup_label.
  ///
  /// In es, this message translates to:
  /// **'4. PUNTO DE RECOGIDA'**
  String get create_order_pickup_label;

  /// No description provided for @create_order_dropoff_label.
  ///
  /// In es, this message translates to:
  /// **'5. PUNTO DE ENTREGA'**
  String get create_order_dropoff_label;

  /// No description provided for @create_order_description_label.
  ///
  /// In es, this message translates to:
  /// **'3. DESCRIPCIÓN DEL PAQUETE'**
  String get create_order_description_label;

  /// No description provided for @create_order_btn_send.
  ///
  /// In es, this message translates to:
  /// **'ENVIAR ORDEN'**
  String get create_order_btn_send;

  /// No description provided for @create_order_success.
  ///
  /// In es, this message translates to:
  /// **'✅ ORDEM ENVIADA'**
  String get create_order_success;

  /// No description provided for @create_order_error_address.
  ///
  /// In es, this message translates to:
  /// **'Dirección no válida.'**
  String get create_order_error_address;

  /// No description provided for @create_order_error_radius.
  ///
  /// In es, this message translates to:
  /// **'El destino está fuera del radio permitido ({radius} mi).'**
  String create_order_error_radius(String radius);

  /// No description provided for @create_order_error_session.
  ///
  /// In es, this message translates to:
  /// **'Sesión expirada.'**
  String get create_order_error_session;

  /// No description provided for @create_order_required.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio'**
  String get create_order_required;

  /// No description provided for @create_order_geofence_error.
  ///
  /// In es, this message translates to:
  /// **'⚠️ FUERA DE COBERTURA: Este Driver opera en un radio de {radius} mi. La recogida y entrega deben estar en su zona.'**
  String create_order_geofence_error(String radius);

  /// No description provided for @create_order_sent_toast.
  ///
  /// In es, this message translates to:
  /// **'🚀 SOLICITUD ENVIADA'**
  String get create_order_sent_toast;

  /// No description provided for @create_order_client_default.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get create_order_client_default;

  /// No description provided for @neg_client_details_title.
  ///
  /// In es, this message translates to:
  /// **'DETALLES DE LA OFERTA'**
  String get neg_client_details_title;

  /// No description provided for @neg_client_closing.
  ///
  /// In es, this message translates to:
  /// **'Cerrando negociación...'**
  String get neg_client_closing;

  /// No description provided for @neg_client_waiting.
  ///
  /// In es, this message translates to:
  /// **'Esperando oferta...'**
  String get neg_client_waiting;

  /// No description provided for @neg_client_driver_assigned.
  ///
  /// In es, this message translates to:
  /// **'DRIVER ASIGNADO'**
  String get neg_client_driver_assigned;

  /// No description provided for @neg_client_order_details.
  ///
  /// In es, this message translates to:
  /// **'DETALLES DE LA ORDEN'**
  String get neg_client_order_details;

  /// No description provided for @neg_client_price_proposal.
  ///
  /// In es, this message translates to:
  /// **'PROPUESTA DE PRECIO'**
  String get neg_client_price_proposal;

  /// No description provided for @neg_client_price_final.
  ///
  /// In es, this message translates to:
  /// **'OFERTA FINAL DEL DRIVER'**
  String get neg_client_price_final;

  /// No description provided for @neg_client_btn_accept.
  ///
  /// In es, this message translates to:
  /// **'ACEPTAR Y PEDIR AHORA'**
  String get neg_client_btn_accept;

  /// No description provided for @neg_client_btn_accept_final.
  ///
  /// In es, this message translates to:
  /// **'ACEPTAR ÚLTIMA OFERTA'**
  String get neg_client_btn_accept_final;

  /// No description provided for @neg_client_btn_counter.
  ///
  /// In es, this message translates to:
  /// **'HACER CONTRAOFERTA'**
  String get neg_client_btn_counter;

  /// No description provided for @neg_client_btn_reject_cancel.
  ///
  /// In es, this message translates to:
  /// **'RECHAZAR Y CANCELAR'**
  String get neg_client_btn_reject_cancel;

  /// No description provided for @neg_client_dialog_title.
  ///
  /// In es, this message translates to:
  /// **'TU CONTRAOFERTA'**
  String get neg_client_dialog_title;

  /// No description provided for @neg_client_dialog_body.
  ///
  /// In es, this message translates to:
  /// **'Propón un nuevo precio al driver:'**
  String get neg_client_dialog_body;

  /// No description provided for @neg_client_dialog_label.
  ///
  /// In es, this message translates to:
  /// **'Nuevo precio'**
  String get neg_client_dialog_label;

  /// No description provided for @neg_client_dialog_btn_cancel.
  ///
  /// In es, this message translates to:
  /// **'RECHAZAR'**
  String get neg_client_dialog_btn_cancel;

  /// No description provided for @neg_client_dialog_btn_send.
  ///
  /// In es, this message translates to:
  /// **'ENVIAR'**
  String get neg_client_dialog_btn_send;

  /// No description provided for @auth_sync_security.
  ///
  /// In es, this message translates to:
  /// **'Sincronización de seguridad...'**
  String get auth_sync_security;

  /// No description provided for @auth_sync_timeout.
  ///
  /// In es, this message translates to:
  /// **'Si tarda demasiado, pulsa el botón de abajo.'**
  String get auth_sync_timeout;

  /// No description provided for @auth_cancel_retry.
  ///
  /// In es, this message translates to:
  /// **'Cancelar y reintentar'**
  String get auth_cancel_retry;

  /// No description provided for @auth_login_welcome.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido de vuelta, soldado!'**
  String get auth_login_welcome;

  /// No description provided for @auth_login_email.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get auth_login_email;

  /// No description provided for @auth_login_password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get auth_login_password;

  /// No description provided for @auth_login_btn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get auth_login_btn;

  /// No description provided for @auth_login_not_member.
  ///
  /// In es, this message translates to:
  /// **'¿No eres miembro?'**
  String get auth_login_not_member;

  /// No description provided for @auth_login_register_now.
  ///
  /// In es, this message translates to:
  /// **'Regístrate ahora'**
  String get auth_login_register_now;

  /// No description provided for @auth_register_title.
  ///
  /// In es, this message translates to:
  /// **'¡Crea una cuenta para comenzar!'**
  String get auth_register_title;

  /// No description provided for @auth_register_name.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get auth_register_name;

  /// No description provided for @auth_register_confirm_pass.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get auth_register_confirm_pass;

  /// No description provided for @auth_register_btn.
  ///
  /// In es, this message translates to:
  /// **'REGISTRARSE'**
  String get auth_register_btn;

  /// No description provided for @auth_register_already_member.
  ///
  /// In es, this message translates to:
  /// **'¿Ya eres miembro?'**
  String get auth_register_already_member;

  /// No description provided for @auth_register_login_now.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión ahora'**
  String get auth_register_login_now;

  /// No description provided for @auth_error_fields.
  ///
  /// In es, this message translates to:
  /// **'Por favor rellene todos los campos.'**
  String get auth_error_fields;

  /// No description provided for @auth_error_pass_match.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get auth_error_pass_match;

  /// No description provided for @auth_error_name.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu nombre completo'**
  String get auth_error_name;

  /// No description provided for @auth_role_title.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido a LAD!'**
  String get auth_role_title;

  /// No description provided for @auth_role_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo quieres usar la plataforma:'**
  String get auth_role_subtitle;

  /// No description provided for @auth_role_client.
  ///
  /// In es, this message translates to:
  /// **'SOY CLIENTE'**
  String get auth_role_client;

  /// No description provided for @auth_role_messenger.
  ///
  /// In es, this message translates to:
  /// **'SOY MENSAJERO'**
  String get auth_role_messenger;

  /// No description provided for @auth_role_preparing.
  ///
  /// In es, this message translates to:
  /// **'Preparando tu cuenta...'**
  String get auth_role_preparing;

  /// No description provided for @service_location_disabled.
  ///
  /// In es, this message translates to:
  /// **'Los servicios de ubicación están desactivados.'**
  String get service_location_disabled;

  /// No description provided for @service_location_denied.
  ///
  /// In es, this message translates to:
  /// **'Los permisos de ubicación han sido denegados.'**
  String get service_location_denied;

  /// No description provided for @service_location_denied_forever.
  ///
  /// In es, this message translates to:
  /// **'Los permisos de ubicación están permanentemente denegados.'**
  String get service_location_denied_forever;

  /// No description provided for @service_invitation_error_user.
  ///
  /// In es, this message translates to:
  /// **'Error: El usuario no pudo ser identificado.'**
  String get service_invitation_error_user;

  /// No description provided for @service_invitation_share_msg.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! 👋 Te invito a unirte a mi red personal en LAD Courier. Es la forma más rápida y segura de gestionar tus envíos conmigo. Regístrate aquí: {link}'**
  String service_invitation_share_msg(String link);

  /// No description provided for @service_invitation_subject.
  ///
  /// In es, this message translates to:
  /// **'🚚 ¡Únete a mi red de mensajeros en LAD!'**
  String get service_invitation_subject;

  /// No description provided for @service_recommend_share_msg.
  ///
  /// In es, this message translates to:
  /// **'🚀 ¡Hola! Te recomiendo a {name} para tus entregas. Es mi mensajero de confianza en LAD COURIER. Puedes contactarlo descargando la app aquí: {link}'**
  String service_recommend_share_msg(String name, String link);

  /// No description provided for @service_recommend_subject.
  ///
  /// In es, this message translates to:
  /// **'Te recomiendo a mi mensajero en LAD Courier'**
  String get service_recommend_subject;

  /// No description provided for @auth_error_role_save.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar el rol: {error}'**
  String auth_error_role_save(String error);

  /// No description provided for @order_error_deleted.
  ///
  /// In es, this message translates to:
  /// **'La orden ha sido eliminada.'**
  String get order_error_deleted;

  /// No description provided for @order_status_active_msg.
  ///
  /// In es, this message translates to:
  /// **'ORDEN ACTIVA'**
  String get order_status_active_msg;

  /// No description provided for @order_status_timeout_msg.
  ///
  /// In es, this message translates to:
  /// **'Tiempo agotado (30 min).'**
  String get order_status_timeout_msg;

  /// No description provided for @order_status_timeout_full_msg.
  ///
  /// In es, this message translates to:
  /// **'Debido a la gran cantidad de órdenes, el driver no pudo atenderla a tiempo. Por favor, envíela a otro driver disponible. ¡Gracias!'**
  String get order_status_timeout_full_msg;

  /// Error genérico
  ///
  /// In es, this message translates to:
  /// **'Error de seguridad: {message}'**
  String auth_error_generic(String message);

  /// No description provided for @deliver_label.
  ///
  /// In es, this message translates to:
  /// **'ENTREGAR'**
  String get deliver_label;

  /// No description provided for @pickup_label.
  ///
  /// In es, this message translates to:
  /// **'RECOGER'**
  String get pickup_label;

  /// No description provided for @notification_new_order_title.
  ///
  /// In es, this message translates to:
  /// **'🚀 ¡NUEVA MISIÓN DETECTADA!'**
  String get notification_new_order_title;

  /// No description provided for @notification_new_order_body.
  ///
  /// In es, this message translates to:
  /// **'Tienes una nueva solicitud en el radar.'**
  String get notification_new_order_body;

  /// No description provided for @driver_work_zone_title.
  ///
  /// In es, this message translates to:
  /// **'MAPA DE OPERACIONES'**
  String get driver_work_zone_title;

  /// No description provided for @driver_work_zone_pending_requests.
  ///
  /// In es, this message translates to:
  /// **'SOLICITUDES PENDIENTES'**
  String get driver_work_zone_pending_requests;

  /// No description provided for @driver_work_zone_waiting.
  ///
  /// In es, this message translates to:
  /// **'Esperando nuevas misiones...'**
  String get driver_work_zone_waiting;

  /// No description provided for @dashboard_btn_create_order.
  ///
  /// In es, this message translates to:
  /// **'Crear Orden'**
  String get dashboard_btn_create_order;

  /// No description provided for @client_label.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get client_label;

  /// No description provided for @counter_offer_label.
  ///
  /// In es, this message translates to:
  /// **'CONTRAOFERTA'**
  String get counter_offer_label;

  /// No description provided for @new_order_label.
  ///
  /// In es, this message translates to:
  /// **'NUEVA ORDEN'**
  String get new_order_label;

  /// No description provided for @create_order_requirements.
  ///
  /// In es, this message translates to:
  /// **'REQUISITOS'**
  String get create_order_requirements;

  /// No description provided for @create_order_section_messenger.
  ///
  /// In es, this message translates to:
  /// **'6. SELECCIONA TU DRIVER'**
  String get create_order_section_messenger;

  /// No description provided for @create_order_search_available.
  ///
  /// In es, this message translates to:
  /// **'Cualquier Driver'**
  String get create_order_search_available;

  /// No description provided for @create_order_add_photo.
  ///
  /// In es, this message translates to:
  /// **'2. FOTO O RECIBO'**
  String get create_order_add_photo;

  /// No description provided for @create_order_service_type.
  ///
  /// In es, this message translates to:
  /// **'1. ELEGIR SERVICIO'**
  String get create_order_service_type;

  /// No description provided for @create_order_btn_search_drivers.
  ///
  /// In es, this message translates to:
  /// **'Buscar drivers disponibles'**
  String get create_order_btn_search_drivers;

  /// No description provided for @order_details_product_photo.
  ///
  /// In es, this message translates to:
  /// **'FOTO PRODUCTO'**
  String get order_details_product_photo;

  /// No description provided for @order_details_save_photo.
  ///
  /// In es, this message translates to:
  /// **'GUARDAR REFERENCIA'**
  String get order_details_save_photo;

  /// No description provided for @order_details_photo_saved.
  ///
  /// In es, this message translates to:
  /// **'Foto guardada en la galería'**
  String get order_details_photo_saved;

  /// No description provided for @order_details_photo_error.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar la foto'**
  String get order_details_photo_error;

  /// No description provided for @create_order_shopping_nav_btn.
  ///
  /// In es, this message translates to:
  /// **'SHOPPING NAVIGATOR (TIENDA)'**
  String get create_order_shopping_nav_btn;

  /// No description provided for @create_order_shopping_nav_success.
  ///
  /// In es, this message translates to:
  /// **'✅ TIENDA CAPTURADA CON ÉXITO'**
  String get create_order_shopping_nav_success;

  /// No description provided for @shopping_nav_capture.
  ///
  /// In es, this message translates to:
  /// **'CAPTURAR'**
  String get shopping_nav_capture;

  /// No description provided for @shopping_nav_title.
  ///
  /// In es, this message translates to:
  /// **'SHOPPING NAVIGATOR'**
  String get shopping_nav_title;

  /// No description provided for @catalog_title.
  ///
  /// In es, this message translates to:
  /// **'SHOPPING NAVIGATOR'**
  String get catalog_title;

  /// No description provided for @catalog_no_stores.
  ///
  /// In es, this message translates to:
  /// **'SIN TIENDAS CERCANAS EN EL RADIO DEL MENSAJERO'**
  String get catalog_no_stores;

  /// No description provided for @shopping_nav_capturing.
  ///
  /// In es, this message translates to:
  /// **'Subiendo evidencias...'**
  String get shopping_nav_capturing;

  /// No description provided for @shopping_nav_error_photo.
  ///
  /// In es, this message translates to:
  /// **'⚠️ Foto del recibo obligatoria para continuar'**
  String get shopping_nav_error_photo;

  /// No description provided for @shopping_nav_success_full.
  ///
  /// In es, this message translates to:
  /// **'✅ Tienda y recibo capturados con éxito'**
  String get shopping_nav_success_full;

  /// No description provided for @sub_plan_lite_title.
  ///
  /// In es, this message translates to:
  /// **'ZONA LITE'**
  String get sub_plan_lite_title;

  /// No description provided for @sub_plan_lite_desc.
  ///
  /// In es, this message translates to:
  /// **'Ideal para entregas locales rápidas.'**
  String get sub_plan_lite_desc;

  /// No description provided for @sub_plan_standart_title.
  ///
  /// In es, this message translates to:
  /// **'ZONA STANDARD'**
  String get sub_plan_standart_title;

  /// No description provided for @sub_plan_standart_desc.
  ///
  /// In es, this message translates to:
  /// **'Cubre toda tu ciudad y alrededores.'**
  String get sub_plan_standart_desc;

  /// No description provided for @sub_plan_pro_title.
  ///
  /// In es, this message translates to:
  /// **'ZONA PRO'**
  String get sub_plan_pro_title;

  /// No description provided for @sub_plan_pro_desc.
  ///
  /// In es, this message translates to:
  /// **'Máximo alcance para fletes largos.'**
  String get sub_plan_pro_desc;

  /// No description provided for @sub_price_per_month.
  ///
  /// In es, this message translates to:
  /// **'{price} / mes'**
  String sub_price_per_month(String price);

  /// No description provided for @catalog_cat_all.
  ///
  /// In es, this message translates to:
  /// **'TODO'**
  String get catalog_cat_all;

  /// No description provided for @catalog_cat_food.
  ///
  /// In es, this message translates to:
  /// **'GASTRO'**
  String get catalog_cat_food;

  /// No description provided for @catalog_cat_fashion.
  ///
  /// In es, this message translates to:
  /// **'MODA'**
  String get catalog_cat_fashion;

  /// No description provided for @catalog_cat_auto.
  ///
  /// In es, this message translates to:
  /// **'MOTOR'**
  String get catalog_cat_auto;

  /// No description provided for @catalog_cat_health.
  ///
  /// In es, this message translates to:
  /// **'SALUD'**
  String get catalog_cat_health;

  /// No description provided for @catalog_cat_grocery.
  ///
  /// In es, this message translates to:
  /// **'MERCADOS'**
  String get catalog_cat_grocery;

  /// No description provided for @catalog_cat_home.
  ///
  /// In es, this message translates to:
  /// **'HOGAR'**
  String get catalog_cat_home;

  /// No description provided for @catalog_cat_tech.
  ///
  /// In es, this message translates to:
  /// **'TECH'**
  String get catalog_cat_tech;

  /// No description provided for @catalog_radius.
  ///
  /// In es, this message translates to:
  /// **'Radio de Búsqueda'**
  String get catalog_radius;

  /// No description provided for @catalog_select_cat.
  ///
  /// In es, this message translates to:
  /// **'Seleccione una categoría'**
  String get catalog_select_cat;

  /// No description provided for @catalog_no_results.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados en esta categoría'**
  String get catalog_no_results;

  /// No description provided for @catalog_no_results_area.
  ///
  /// In es, this message translates to:
  /// **'SIN RESULTADOS EN ESTA ÁREA'**
  String get catalog_no_results_area;

  /// No description provided for @shopping_nav_instruction_title.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones de Compra'**
  String get shopping_nav_instruction_title;

  /// No description provided for @shopping_nav_instruction_body.
  ///
  /// In es, this message translates to:
  /// **'Navega, realiza tu compra y cuando veas el recibo final, pulsa CAPTURAR.'**
  String get shopping_nav_instruction_body;

  /// No description provided for @catalog_no_results_detail.
  ///
  /// In es, this message translates to:
  /// **'Intenta cambiar de categoría o verifica si el Driver tiene radio de acción.'**
  String get catalog_no_results_detail;

  /// No description provided for @catalog_default_name.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get catalog_default_name;

  /// No description provided for @driver_service_courier.
  ///
  /// In es, this message translates to:
  /// **'Mensajería y Paquetes'**
  String get driver_service_courier;

  /// No description provided for @driver_service_logistics.
  ///
  /// In es, this message translates to:
  /// **'Logística Especializada'**
  String get driver_service_logistics;

  /// No description provided for @driver_service_shopping.
  ///
  /// In es, this message translates to:
  /// **'Compras y Recados'**
  String get driver_service_shopping;

  /// No description provided for @shopping_nav_instruction_title_alt.
  ///
  /// In es, this message translates to:
  /// **'💡 PLAN DE RESPALDO'**
  String get shopping_nav_instruction_title_alt;

  /// No description provided for @shopping_nav_instruction_body_alt.
  ///
  /// In es, this message translates to:
  /// **'Si el local te obliga a usar su App oficial, haz tu pedido allí, toma un screenshot del recibo y súbelo aquí.'**
  String get shopping_nav_instruction_body_alt;

  /// No description provided for @client_dash_order_here.
  ///
  /// In es, this message translates to:
  /// **'ORDENE AQUÍ'**
  String get client_dash_order_here;

  /// No description provided for @prof_btn_business_card.
  ///
  /// In es, this message translates to:
  /// **'MI TARJETA DE NEGOCIOS'**
  String get prof_btn_business_card;

  /// No description provided for @business_card_title.
  ///
  /// In es, this message translates to:
  /// **'TARJETA DE NEGOCIOS LAD COURIER'**
  String get business_card_title;

  /// No description provided for @business_card_scan_msg.
  ///
  /// In es, this message translates to:
  /// **'Escanea para descargar LAD y vincularte a mi red'**
  String get business_card_scan_msg;

  /// No description provided for @common_delete_account.
  ///
  /// In es, this message translates to:
  /// **'ELIMINAR MI CUENTA'**
  String get common_delete_account;

  /// No description provided for @delete_account_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'¿ELIMINAR CUENTA DEFINITIVAMENTE?'**
  String get delete_account_confirm_title;

  /// No description provided for @delete_account_confirm_body.
  ///
  /// In es, this message translates to:
  /// **'Esta acción borrará todos tus datos, historial y conexiones. No se puede deshacer.'**
  String get delete_account_confirm_body;

  /// No description provided for @delete_account_btn_confirm.
  ///
  /// In es, this message translates to:
  /// **'SÍ, ELIMINAR TODO'**
  String get delete_account_btn_confirm;

  /// No description provided for @delete_account_reauth_required.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, debes iniciar sesión de nuevo antes de borrar tu cuenta.'**
  String get delete_account_reauth_required;

  /// No description provided for @common_payment_required_title.
  ///
  /// In es, this message translates to:
  /// **'VINCULACIÓN DE PAGO'**
  String get common_payment_required_title;

  /// No description provided for @common_payment_required_msg.
  ///
  /// In es, this message translates to:
  /// **'Para garantizar la seguridad de tus pedidos, debes vincular un método de pago en tu perfil.'**
  String get common_payment_required_msg;

  /// No description provided for @driver_inactivity_title.
  ///
  /// In es, this message translates to:
  /// **'MODO DESCANSO'**
  String get driver_inactivity_title;

  /// No description provided for @driver_inactivity_msg.
  ///
  /// In es, this message translates to:
  /// **'Tu disponibilidad se ha cerrado automáticamente por llevar más de 4 horas sin actividad. Si estás listo para trabajar, vuelve a ponerte online.'**
  String get driver_inactivity_msg;

  /// No description provided for @common_logout.
  ///
  /// In es, this message translates to:
  /// **'CERRAR SESIÓN'**
  String get common_logout;

  /// No description provided for @common_logout_confirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres salir? Tendrás que poner tu email y contraseña de nuevo para refrescar la seguridad.'**
  String get common_logout_confirm;

  /// No description provided for @common_exit.
  ///
  /// In es, this message translates to:
  /// **'SALIR'**
  String get common_exit;

  /// No description provided for @common_continue.
  ///
  /// In es, this message translates to:
  /// **'CONTINUAR'**
  String get common_continue;

  /// No description provided for @auth_verification_required_title.
  ///
  /// In es, this message translates to:
  /// **'🛡️ VERIFICACIÓN OBLIGATORIA'**
  String get auth_verification_required_title;

  /// No description provided for @auth_verification_required_body.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, debes validar tu identidad con una selfie y tu huella dactilar para comenzar a trabajar.'**
  String get auth_verification_required_body;

  /// No description provided for @client_dash_negotiations_title.
  ///
  /// In es, this message translates to:
  /// **'NEGOCIACIONES'**
  String get client_dash_negotiations_title;

  /// No description provided for @client_dash_no_negotiations.
  ///
  /// In es, this message translates to:
  /// **'Sin negociaciones pendientes'**
  String get client_dash_no_negotiations;

  /// No description provided for @client_dash_no_active_missions.
  ///
  /// In es, this message translates to:
  /// **'Sin misiones activas'**
  String get client_dash_no_active_missions;

  /// No description provided for @client_dash_order_active.
  ///
  /// In es, this message translates to:
  /// **'ORDEN ACTIVA'**
  String get client_dash_order_active;

  /// No description provided for @client_dash_driver_resting_body.
  ///
  /// In es, this message translates to:
  /// **'EL DRIVER {name} NO ESTÁ RECIBIENDO ÓRDENES EN ESTE MOMENTO. ¿DESEAS BUSCAR OTRO DRIVER DISPONIBLE?'**
  String client_dash_driver_resting_body(String name);

  /// No description provided for @client_dash_invite_code_label.
  ///
  /// In es, this message translates to:
  /// **'INGRESE EL CÓDIGO DE VINCULACIÓN DEL DRIVER:'**
  String get client_dash_invite_code_label;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'ht', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ht':
      return AppLocalizationsHt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
