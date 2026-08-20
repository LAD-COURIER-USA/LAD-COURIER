// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get earnings_title => 'ZONAS DE TRABAJO';

  @override
  String get earnings_period_today => 'Hoy';

  @override
  String get earnings_period_week => 'Esta Semana';

  @override
  String get earnings_period_month => 'Mes Actual';

  @override
  String get earnings_period_year => 'Año Fiscal';

  @override
  String get earnings_stat_gross => 'INGRESOS BRUTOS';

  @override
  String get earnings_stat_miles => 'MILLAS FISCALES';

  @override
  String get earnings_stat_missions => 'MISIONES';

  @override
  String get earnings_stat_efficiency => 'EFECTIVIDAD';

  @override
  String get earnings_history_title => 'HISTORIAL DE MISIONES';

  @override
  String get earnings_empty_history => 'Sin misiones en este periodo.';

  @override
  String get earnings_network_title => 'MI RADIO DE ACCIÓN';

  @override
  String get earnings_linked_users => 'USUARIOS VINCULADOS';

  @override
  String get earnings_referrals_count => 'Referidos';

  @override
  String get earnings_plan_label => 'ZONA SELECCIONADA';

  @override
  String get earnings_refund_title => 'ESTADO DE ZONA';

  @override
  String get earnings_refund_covered => 'ACTIVA';

  @override
  String get earnings_refund_saving => 'GRATIS';

  @override
  String get earnings_refund_status_free_current => 'ZONA SIN CARGO';

  @override
  String get earnings_refund_status_free_next => 'CAMBIO DISPONIBLE';

  @override
  String get earnings_refund_goal_msg =>
      'Configura tu radio de alcance libremente.';

  @override
  String get earnings_refund_success_msg => 'Zona configurada correctamente.';

  @override
  String get earnings_refund_pending_msg => 'Configuración en curso...';

  @override
  String get earnings_refund_anti_fraud_rule =>
      'El cambio de zona es instantáneo y sin costo.';

  @override
  String get earnings_refund_disclaimer =>
      'LAD Courier no cobra mensualidad. Solo un service fee de 0.70 \$ por orden exitosa, sin importar precio pactado.';

  @override
  String get driver_dash_title => 'CENTRO DE MANDO DRIVER';

  @override
  String get driver_status_online => 'DRIVER EN LÍNEA';

  @override
  String get driver_status_offline => 'FUERA DE SERVICIO';

  @override
  String get driver_btn_work_zone => 'MAPA OPERATIVO';

  @override
  String get driver_menu_services => 'SERVICIOS';

  @override
  String get driver_menu_profile => 'MI PERFIL';

  @override
  String get driver_menu_earnings => 'ZONAS';

  @override
  String get driver_menu_invite => 'INVITAR';

  @override
  String get driver_dialog_services_title => 'SERVICIOS ACTIVOS';

  @override
  String get driver_btn_confirm => 'CONFIRMAR';

  @override
  String get driver_error_no_photo => 'FALTA FOTO DE PERFIL';

  @override
  String get driver_error_no_photo_msg =>
      'Debes subir una foto profesional para que tus clientes puedan identificarte.';

  @override
  String get driver_error_incomplete_data => 'DATOS INCOMPLETOS';

  @override
  String get driver_error_incomplete_data_msg =>
      'Tu nombre y teléfono son obligatorios para la seguridad del servicio.';

  @override
  String get driver_error_no_vehicle => 'DETALLE DEL VEHÍCULO';

  @override
  String get driver_error_no_vehicle_msg =>
      'Describe tu medio de transporte en la sección Mi Perfil.';

  @override
  String get driver_error_no_membership => 'ZONA NO SELECCIONADA';

  @override
  String get driver_error_no_membership_msg =>
      'Debes seleccionar una \'Zona de Trabajo\' (Lite, Standard o Pro) para recibir órdenes.';

  @override
  String get driver_error_no_stripe => 'STRIPE NO VINCULADO';

  @override
  String get driver_error_no_stripe_msg =>
      'Para ponerte online, debes configurar tu cuenta de Stripe Connect en \'Mi Perfil\'.';

  @override
  String get driver_error_no_verification => 'VERIFICACIÓN PENDIENTE';

  @override
  String get driver_error_no_verification_msg =>
      'Debes completar tu verificación de identidad y background check para ponerte online.';

  @override
  String get driver_error_no_services => 'SIN SERVICIOS ACTIVOS';

  @override
  String get driver_error_no_services_msg =>
      'Selecciona al menos un servicio antes de ponerte en línea.';

  @override
  String get driver_active_missions_alert =>
      '⚠️ TIENES MISIONES ACTIVAS. Termínalas primero.';

  @override
  String get driver_btn_understand => 'ENTENDIDO';

  @override
  String get driver_selection_title => 'Elegir Driver';

  @override
  String get driver_card_plan => 'Zona';

  @override
  String get driver_card_coverage => 'Cobertura';

  @override
  String get driver_selection_no_drivers_title => 'Lo sentimos';

  @override
  String get driver_selection_no_drivers_body =>
      'No hay drivers disponibles cuyo rango de trabajo cubra estas direcciones. Intenta con un trayecto más corto.';

  @override
  String get notification_order_sent_success => 'Misión enviada al driver';

  @override
  String get prof_title => 'MI PERFIL OPERATIVO';

  @override
  String get prof_radar_title => 'MI RADAR DE RECLUTAMIENTO';

  @override
  String get prof_radar_body =>
      'Tus clientes escanean este QR para vincularse a tu red personal.';

  @override
  String get prof_section_id => 'DATOS DE IDENTIFICACIÓN';

  @override
  String get prof_label_name => 'Nombre Completo';

  @override
  String get prof_label_phone => 'Teléfono de Contacto';

  @override
  String get prof_label_vehicle => 'Descripción del Vehículo';

  @override
  String get prof_section_mem => 'ZONAS DE TRABAJO';

  @override
  String get prof_section_pay => 'HERRAMIENTAS DE PAGO (STRIPE)';

  @override
  String get prof_pay_stripe => 'Vincular Stripe Connect';

  @override
  String get prof_pay_stripe_sub => 'Para recibir tus pagos al instante';

  @override
  String get prof_pay_paypal => 'PayPal (Opcional)';

  @override
  String get prof_pay_paypal_sub => 'Solo para cobros manuales';

  @override
  String get prof_btn_save => 'GUARDAR CAMBIOS';

  @override
  String get prof_btn_switch => 'CAMBIAR A MODO CLIENTE';

  @override
  String get work_title => 'MAPA DE OPERACIONES';

  @override
  String get work_panel_title => 'SOLICITUDES PENDIENTES';

  @override
  String get work_waiting => 'Esperando nuevas misiones...';

  @override
  String get work_alert_title => '🚀 ¡NUEVA MISIÓN DETECTADA!';

  @override
  String get work_alert_body => 'Tienes una nueva solicitud en el radar.';

  @override
  String get work_notif_channel_name => 'Alertas de Pedidos Urgentes';

  @override
  String get work_notif_channel_desc =>
      'Canal para notificaciones de misiones nuevas';

  @override
  String get sub_title => 'ZONAS DE TRABAJO';

  @override
  String get sub_promo => 'ELABORA TU PROPIA RUTA LIBREMENTE';

  @override
  String get sub_free => 'GRATIS';

  @override
  String sub_radius(String radius) {
    return 'Alcance: $radius';
  }

  @override
  String sub_bonus(String bonus) {
    return 'Costo: $bonus';
  }

  @override
  String get sub_btn_activate => 'ACTIVAR ZONA';

  @override
  String get welcome_title => '¡Bienvenido a Bordo!';

  @override
  String get welcome_body =>
      'Para finalizar tu registro, por favor, elige tu rol en nuestra comunidad.';

  @override
  String get welcome_btn_client => 'Soy Cliente';

  @override
  String get welcome_btn_driver => 'Soy Mensajero';

  @override
  String get client_dash_title => 'CENTRO DE MANDO CLIENTE';

  @override
  String get client_dash_welcome => 'SISTEMA LAD COURIER';

  @override
  String get client_dash_requested_services => 'SERVICIOS SOLICITADOS';

  @override
  String get client_dash_no_requests => 'Sin solicitudes pendientes.';

  @override
  String get client_dash_new_request => 'NUEVA SOLICITUD';

  @override
  String get client_dash_first_offer => 'PRIMERA OFERTA RECIBIDA';

  @override
  String get client_dash_counter_offer => 'CONTRAOFERTA RECIBIDA';

  @override
  String client_dash_driver_label(String name) {
    return 'Driver: $name';
  }

  @override
  String get client_dash_active_missions => 'MISIONES EN CURSO';

  @override
  String client_dash_price_label(String price) {
    return 'PRECIO: $price';
  }

  @override
  String client_dash_status_label(String status) {
    return 'Status: $status';
  }

  @override
  String get client_dash_linked_drivers => 'LISTADO DE DRIVERS';

  @override
  String get client_dash_no_linked_drivers => 'No tienes drivers vinculados.';

  @override
  String get client_dash_driver_available => 'DISPONIBLE';

  @override
  String get client_dash_driver_resting => 'EN DESCANSO';

  @override
  String client_dash_services_label(String services) {
    return 'SERVICIOS: $services';
  }

  @override
  String client_dash_plan_label(String plan) {
    return 'ZONA: $plan';
  }

  @override
  String client_dash_radius_label(String radius) {
    return 'RADIO: $radius';
  }

  @override
  String get client_dash_no_phone => 'Sin Tel';

  @override
  String get client_dash_unlink_title => 'DESVINCULAR DRIVER';

  @override
  String client_dash_unlink_confirm(String name) {
    return '¿Estás seguro de que deseas eliminar a $name de tu lista de confianza?';
  }

  @override
  String get client_dash_unlink_button => 'DESVINCULAR';

  @override
  String get client_dash_unlink_success => 'Driver desvinculado con éxito';

  @override
  String get client_dash_invite_title => 'VINCULAR DRIVER';

  @override
  String get client_dash_invite_hint => 'Código o ID del Driver';

  @override
  String get common_confirm => 'CONFIRMAR';

  @override
  String get common_cancel => 'CANCELAR';

  @override
  String get client_prof_title => 'MI PERFIL CLIENTE';

  @override
  String get client_prof_contact_details => 'DATOS DE CONTACTO';

  @override
  String get client_prof_name_label => 'Nombre Completo';

  @override
  String get client_prof_phone_label => 'Teléfono';

  @override
  String get client_prof_address_label => 'Dirección Principal';

  @override
  String get client_prof_payment_methods => 'MÉTODOS DE PAGO';

  @override
  String get client_prof_stripe_title => 'Stripe';

  @override
  String get client_prof_stripe_subtitle => 'Tarjeta de Crédito/Débito';

  @override
  String get client_prof_paypal_title => 'PayPal';

  @override
  String get client_prof_paypal_subtitle => 'Cuenta Digital';

  @override
  String get client_prof_cta_title => '¡GANA DINERO COMO DRIVER!';

  @override
  String get client_prof_cta_body =>
      'Únete a nuestra red de mensajeros y genera ingresos en tu tiempo libre.';

  @override
  String get client_prof_cta_button => 'VER ZONAS DRIVER';

  @override
  String get client_prof_save_button => 'GUARDAR CAMBIOS';

  @override
  String get client_prof_switch_button => 'CAMBIAR A MODO DRIVER';

  @override
  String get client_prof_update_success => 'Perfil actualizado';

  @override
  String client_prof_update_error(String error) {
    return 'Error al actualizar: $error';
  }

  @override
  String get client_prof_completed_orders => 'ÓRDENES COMPLETADAS';

  @override
  String get client_dash_history_title => 'HISTORIAL DE MISIONES (36H)';

  @override
  String order_details_title(String type, int index) {
    return 'ORDEN $type #$index';
  }

  @override
  String order_details_id(String id) {
    return 'ID Orden: $id';
  }

  @override
  String get order_details_pickup => 'PUNTO DE RECOGIDA';

  @override
  String get order_details_delivery => 'PUNTO DE ENTREGA';

  @override
  String get order_details_instructions => 'INSTRUCCIONES DE LA MISIÓN';

  @override
  String get order_details_no_instructions =>
      'Sin instrucciones específicas del cliente.';

  @override
  String get order_details_proximity_on => '¡ESTÁS EN EL LUGAR!';

  @override
  String get order_details_proximity_off => 'DISTANCIA AL PUNTO';

  @override
  String order_details_meters(String meters) {
    return '$meters metros';
  }

  @override
  String get order_details_btn_go_pickup => 'IR A RECOGIDA';

  @override
  String get order_details_btn_arrived => 'LLEGUÉ / RECOGIDO';

  @override
  String get order_details_btn_go_delivery => 'IR A ENTREGA';

  @override
  String get order_details_btn_photo => 'TOMAR FOTO PRUEBA';

  @override
  String get order_details_btn_finish => 'FINALIZAR MISIÓN';

  @override
  String get order_details_photo_success => 'Foto capturada';

  @override
  String get order_details_evidence_msg =>
      'Evidencia guardada con coordenadas GPS';

  @override
  String get order_details_btn_view_proof => 'VER PRUEBA DE ENTREGA';

  @override
  String order_details_multiple_warning(int count) {
    return 'TIENES $count ÓRDENES MÁS AQUÍ';
  }

  @override
  String get neg_title => 'NEGOCIACIÓN';

  @override
  String get neg_client_initial => 'SOLICITUD INICIAL (SIN PRECIO)';

  @override
  String get neg_client_counter => 'CONTRAOFERTA DEL CLIENTE';

  @override
  String get neg_driver_last => 'TU ÚLTIMA OFERTA';

  @override
  String get neg_input_label => 'TU PROPUESTA (\$)';

  @override
  String get neg_btn_accept => 'ACEPTAR';

  @override
  String get neg_btn_first => 'PRIMERA OFERTA';

  @override
  String get neg_btn_counter => 'NUEVA CONTRAOFERTA';

  @override
  String get neg_btn_final => 'ENVIAR OFERTA FINAL';

  @override
  String get neg_btn_reject => 'RECHAZAR Y CERRAR';

  @override
  String neg_impact_single(String miles) {
    return 'Esta orden representa un viaje total de $miles millas.';
  }

  @override
  String neg_impact_multi(String miles) {
    return 'Sumar esta orden añade $miles millas extra a tu ruta.';
  }

  @override
  String get create_order_title => 'CREAR LA ORDEN';

  @override
  String get create_order_service_label => 'Tipo de servicio disponible';

  @override
  String get create_order_pickup_hint => 'Origen (Dirección exacta)';

  @override
  String get create_order_dropoff_hint => 'Destino (Dirección exacta)';

  @override
  String get create_order_details_hint => 'Detalles del paquete';

  @override
  String get create_order_pickup_label => '4. PUNTO DE RECOGIDA';

  @override
  String get create_order_dropoff_label => '5. PUNTO DE ENTREGA';

  @override
  String get create_order_description_label => '3. DESCRIPCIÓN DEL PAQUETE';

  @override
  String get create_order_btn_send => 'ENVIAR ORDEN';

  @override
  String get create_order_success => '✅ ORDEM ENVIADA';

  @override
  String get create_order_error_address => 'Dirección no válida.';

  @override
  String create_order_error_radius(String radius) {
    return 'El destino está fuera del radio permitido ($radius mi).';
  }

  @override
  String get create_order_error_session => 'Sesión expirada.';

  @override
  String get create_order_required => 'Campo obligatorio';

  @override
  String create_order_geofence_error(String radius) {
    return '⚠️ FUERA DE COBERTURA: Este Driver opera en un radio de $radius mi. La recogida y entrega deben estar en su zona.';
  }

  @override
  String get create_order_sent_toast => '🚀 SOLICITUD ENVIADA';

  @override
  String get create_order_client_default => 'Cliente';

  @override
  String get neg_client_details_title => 'DETALLES DE LA OFERTA';

  @override
  String get neg_client_closing => 'Cerrando negociación...';

  @override
  String get neg_client_waiting => 'Esperando oferta...';

  @override
  String get neg_client_driver_assigned => 'DRIVER ASIGNADO';

  @override
  String get neg_client_order_details => 'DETALLES DE LA ORDEN';

  @override
  String get neg_client_price_proposal => 'PROPUESTA DE PRECIO';

  @override
  String get neg_client_price_final => 'OFERTA FINAL DEL DRIVER';

  @override
  String get neg_client_btn_accept => 'ACEPTAR Y PEDIR AHORA';

  @override
  String get neg_client_btn_accept_final => 'ACEPTAR ÚLTIMA OFERTA';

  @override
  String get neg_client_btn_counter => 'HACER CONTRAOFERTA';

  @override
  String get neg_client_btn_reject_cancel => 'RECHAZAR Y CANCELAR';

  @override
  String get neg_client_dialog_title => 'TU CONTRAOFERTA';

  @override
  String get neg_client_dialog_body => 'Propón un nuevo precio al driver:';

  @override
  String get neg_client_dialog_label => 'Nuevo precio';

  @override
  String get neg_client_dialog_btn_cancel => 'RECHAZAR';

  @override
  String get neg_client_dialog_btn_send => 'ENVIAR';

  @override
  String get auth_sync_security => 'Sincronización de seguridad...';

  @override
  String get auth_sync_timeout =>
      'Si tarda demasiado, pulsa el botón de abajo.';

  @override
  String get auth_cancel_retry => 'Cancelar y reintentar';

  @override
  String get auth_login_welcome => '¡Bienvenido de vuelta, soldado!';

  @override
  String get auth_login_email => 'Email';

  @override
  String get auth_login_password => 'Contraseña';

  @override
  String get auth_login_btn => 'Iniciar Sesión';

  @override
  String get auth_login_not_member => '¿No eres miembro?';

  @override
  String get auth_login_register_now => 'Regístrate ahora';

  @override
  String get auth_register_title => '¡Crea una cuenta para comenzar!';

  @override
  String get auth_register_name => 'Nombre completo';

  @override
  String get auth_register_confirm_pass => 'Confirmar contraseña';

  @override
  String get auth_register_btn => 'REGISTRARSE';

  @override
  String get auth_register_already_member => '¿Ya eres miembro?';

  @override
  String get auth_register_login_now => 'Inicia sesión ahora';

  @override
  String get auth_error_fields => 'Por favor rellene todos los campos.';

  @override
  String get auth_error_pass_match => 'Las contraseñas no coinciden';

  @override
  String get auth_error_name => 'Introduce tu nombre completo';

  @override
  String get auth_error_session => 'Sesión expirada o no válida.';

  @override
  String get auth_role_title => '¡Bienvenido a LAD!';

  @override
  String get auth_role_subtitle => 'Elige cómo quieres usar la plataforma:';

  @override
  String get auth_role_client => 'SOY CLIENTE';

  @override
  String get auth_role_messenger => 'SOY MENSAJERO';

  @override
  String get auth_role_preparing => 'Preparando tu cuenta...';

  @override
  String get service_location_disabled =>
      'Los servicios de ubicación están desactivados.';

  @override
  String get service_location_denied =>
      'Los permisos de ubicación han sido denegados.';

  @override
  String get service_location_denied_forever =>
      'Los permisos de ubicación están permanentemente denegados.';

  @override
  String get service_invitation_error_user =>
      'Error: El usuario no pudo ser identificado.';

  @override
  String service_invitation_share_msg(String link) {
    return '¡Hola! 👋 Te invito a unirte a mi red personal en LAD Courier. Es la forma más rápida y segura de gestionar tus envíos conmigo. Regístrate aquí: $link';
  }

  @override
  String get service_invitation_subject =>
      '🚚 ¡Únete a mi red de mensajeros en LAD!';

  @override
  String service_recommend_share_msg(String name, String link) {
    return '🚀 ¡Hola! Te recomiendo a $name para tus entregas. Es mi mensajero de confianza en LAD COURIER. Puedes contactarlo descargando la app aquí: $link';
  }

  @override
  String get service_recommend_subject =>
      'Te recomiendo a mi mensajero en LAD Courier';

  @override
  String auth_error_role_save(String error) {
    return 'Error al guardar el rol: $error';
  }

  @override
  String get order_error_deleted => 'La orden ha sido eliminada.';

  @override
  String get order_status_active_msg => 'ORDEN ACTIVA';

  @override
  String get order_status_timeout_msg => 'Tiempo agotado (30 min).';

  @override
  String get order_status_timeout_full_msg =>
      'Debido a la gran cantidad de órdenes, el driver no pudo atenderla a tiempo. Por favor, envíela a otro driver disponible. ¡Gracias!';

  @override
  String auth_error_generic(String message) {
    return 'Error de seguridad: $message';
  }

  @override
  String get deliver_label => 'ENTREGAR';

  @override
  String get pickup_label => 'RECOGER';

  @override
  String get notification_new_order_title => '🚀 ¡NUEVA MISIÓN DETECTADA!';

  @override
  String get notification_new_order_body =>
      'Tienes una nueva solicitud en el radar.';

  @override
  String get driver_work_zone_title => 'MAPA DE OPERACIONES';

  @override
  String get driver_work_zone_pending_requests => 'SOLICITUDES PENDIENTES';

  @override
  String get driver_work_zone_waiting => 'Esperando nuevas misiones...';

  @override
  String get dashboard_btn_create_order => 'Crear Orden';

  @override
  String get client_label => 'Cliente';

  @override
  String get counter_offer_label => 'CONTRAOFERTA';

  @override
  String get new_order_label => 'NUEVA ORDEN';

  @override
  String get create_order_requirements => 'REQUISITOS';

  @override
  String get create_order_section_messenger => '6. SELECCIONA TU DRIVER';

  @override
  String get create_order_search_available => 'Cualquier Driver';

  @override
  String get create_order_add_photo => '2. FOTO O RECIBO';

  @override
  String get create_order_service_type => '1. ELEGIR SERVICIO';

  @override
  String get create_order_btn_search_drivers => 'Buscar drivers disponibles';

  @override
  String get order_details_product_photo => 'FOTO PRODUCTO';

  @override
  String get order_details_save_photo => 'GUARDAR REFERENCIA';

  @override
  String get order_details_photo_saved => 'Foto guardada en la galería';

  @override
  String get order_details_photo_error => 'Error al guardar la foto';

  @override
  String get create_order_shopping_nav_btn => 'SHOPPING NAVIGATOR (TIENDA)';

  @override
  String get create_order_shopping_nav_success =>
      '✅ TIENDA CAPTURADA CON ÉXITO';

  @override
  String get shopping_nav_capture => 'CAPTURAR';

  @override
  String get shopping_nav_title => 'SHOPPING NAVIGATOR';

  @override
  String get catalog_title => 'SHOPPING NAVIGATOR';

  @override
  String get catalog_no_stores =>
      'SIN TIENDAS CERCANAS EN EL RADIO DEL MENSAJERO';

  @override
  String get shopping_nav_capturing => 'Subiendo evidencias...';

  @override
  String get shopping_nav_error_photo =>
      '⚠️ Foto del recibo obligatoria para continuar';

  @override
  String get shopping_nav_success_full =>
      '✅ Tienda y recibo capturados con éxito';

  @override
  String get sub_plan_lite_title => 'ZONA LITE';

  @override
  String get sub_plan_lite_desc => 'Ideal para entregas locales rápidas.';

  @override
  String get sub_plan_standart_title => 'ZONA STANDARD';

  @override
  String get sub_plan_standart_desc => 'Cubre toda tu ciudad y alrededores.';

  @override
  String get sub_plan_pro_title => 'ZONA PRO';

  @override
  String get sub_plan_pro_desc => 'Máximo alcance para fletes largos.';

  @override
  String sub_price_per_month(String price) {
    return '$price / mes';
  }

  @override
  String get catalog_cat_all => 'TODO';

  @override
  String get catalog_cat_food => 'GASTRO';

  @override
  String get catalog_cat_fashion => 'MODA';

  @override
  String get catalog_cat_auto => 'MOTOR';

  @override
  String get catalog_cat_health => 'SALUD';

  @override
  String get catalog_cat_grocery => 'MERCADOS';

  @override
  String get catalog_cat_home => 'HOGAR';

  @override
  String get catalog_cat_tech => 'TECH';

  @override
  String get catalog_radius => 'Radio de Búsqueda';

  @override
  String get catalog_select_cat => 'Seleccione una categoría';

  @override
  String get catalog_no_results => 'Sin resultados en esta categoría';

  @override
  String get catalog_no_results_area => 'SIN RESULTADOS EN ESTA ÁREA';

  @override
  String get shopping_nav_instruction_title => 'Instrucciones de Compra';

  @override
  String get shopping_nav_instruction_body =>
      'Navega, realiza tu compra y cuando veas el recibo final, pulsa CAPTURAR.';

  @override
  String get catalog_no_results_detail =>
      'Intenta cambiar de categoría o verifica si el Driver tiene radio de acción.';

  @override
  String get catalog_default_name => 'Tienda';

  @override
  String get driver_service_courier => 'Mensajería y Paquetes';

  @override
  String get driver_service_logistics => 'Logística Especializada';

  @override
  String get driver_service_shopping => 'Compras y Recados';

  @override
  String get driver_service_smartshopper => 'SmartShopper';

  @override
  String get shopping_nav_instruction_title_alt => '💡 PLAN DE RESPALDO';

  @override
  String get shopping_nav_instruction_body_alt =>
      'Si el local te obliga a usar su App oficial, haz tu pedido allí, toma un screenshot del recibo y súbelo aquí.';

  @override
  String get client_dash_order_here => 'ORDENE AQUÍ';

  @override
  String get prof_btn_business_card => 'MI TARJETA DE NEGOCIOS';

  @override
  String get business_card_title => 'TARJETA DE NEGOCIOS LAD COURIER';

  @override
  String get business_card_scan_msg =>
      'Escanea para descargar LAD y vincularte a mi red';

  @override
  String get common_delete_account => 'ELIMINAR MI CUENTA';

  @override
  String get delete_account_confirm_title =>
      '¿ELIMINAR CUENTA DEFINITIVAMENTE?';

  @override
  String get delete_account_confirm_body =>
      'Esta acción borrará todos tus datos, historial y conexiones. No se puede deshacer.';

  @override
  String get delete_account_btn_confirm => 'SÍ, ELIMINAR TODO';

  @override
  String get delete_account_reauth_required =>
      'Por seguridad, debes iniciar sesión de nuevo antes de borrar tu cuenta.';

  @override
  String get driver_agreement_title => 'ACUERDO DE LICENCIA SaaS';

  @override
  String get driver_agreement_body =>
      'LAD DIGITAL SYSTEMS LLC le otorga una licencia de uso de software limitada, no exclusiva y revocable. Usted reconoce que LAD no es su empleador. Las reclamaciones se gestionan durante una ventana de seguridad de 10 días. Los pagos se procesan semanalmente con un retraso de 7 días. Las órdenes no pueden ser canceladas por el cliente una vez que el conductor ha iniciado el proceso de recogida, ya que los fondos se reservan en ese momento. El Service Fee (\$0.70) y los términos pueden cambiar con previo aviso digital.';

  @override
  String get client_cancel_blocked_pickup =>
      'No se puede cancelar la orden. El conductor ya está en camino a recoger su paquete y los fondos han sido reservados.';

  @override
  String get common_payment_required_title => 'VINCULACIÓN DE PAGO';

  @override
  String get common_payment_required_msg =>
      'Para garantizar la seguridad de tus pedidos, debes vincular un método de pago en tu perfil.';

  @override
  String get driver_inactivity_title => 'MODO DESCANSO';

  @override
  String get driver_inactivity_msg =>
      'Tu disponibilidad se ha cerrado automáticamente por llevar más de 4 horas sin actividad. Si estás listo para trabajar, vuelve a ponerte online.';

  @override
  String get common_logout => 'CERRAR SESIÓN';

  @override
  String get common_logout_confirm =>
      '¿Estás seguro de que quieres salir? Tendrás que poner tu email y contraseña de nuevo para refrescar la seguridad.';

  @override
  String get common_exit => 'SALIR';

  @override
  String get common_continue => 'CONTINUAR';

  @override
  String get auth_verification_required_title => '🛡️ VERIFICACIÓN OBLIGATORIA';

  @override
  String get auth_verification_required_body =>
      'Por seguridad, debes validar tu identidad con una selfie y tu huella dactilar para comenzar a trabajar.';

  @override
  String get client_dash_negotiations_title => 'NEGOCIACIONES';

  @override
  String get client_dash_no_negotiations => 'Sin negociaciones pendientes';

  @override
  String get client_dash_no_active_missions => 'Sin misiones activas';

  @override
  String get client_dash_order_active => 'ORDEN ACTIVA';

  @override
  String client_dash_driver_resting_body(String name) {
    return 'EL DRIVER $name NO ESTÁ RECIBIENDO ÓRDENES EN ESTE MOMENTO. ¿DESEAS BUSCAR OTRO DRIVER DISPONIBLE?';
  }

  @override
  String get client_dash_invite_code_label =>
      'INGRESE EL CÓDIGO DE VINCULACIÓN DEL DRIVER:';

  @override
  String get order_status_timeout_client =>
      'EXPIRADA POR INACTIVIDAD DEL CLIENTE';

  @override
  String get order_details_arrived_pickup => 'LLEGUÉ / RECOGIDO';

  @override
  String get order_details_en_route_pickup => '🚀 Iniciando ruta de recogida.';

  @override
  String get order_details_en_route_delivery => '🚚 Iniciando ruta de entrega.';

  @override
  String get order_details_geofence_lock =>
      'LLEGUE AL DESTINO PARA ACTIVAR CÁMARA';

  @override
  String get order_details_bypass_title => '⚠️ ERROR DE COBRO';

  @override
  String order_details_bypass_body(String error) {
    return 'Stripe dice: $error\n\n¿Quieres FORZAR la finalización de la orden de todos modos? (Solo para pruebas)';
  }

  @override
  String get order_details_bypass_btn => 'FORZAR FINALIZACIÓN';

  @override
  String get order_details_receipt_btn => 'ABRIR RECIBO ORIGINAL';

  @override
  String get liveness_prompt => 'COLOCA TU ROSTRO FRENTE A LA CÁMARA';

  @override
  String get liveness_eyes_closed => '¡ABRE LOS OJOS O PARPADEA!';

  @override
  String get liveness_face_detected => '✅ ROSTRO DETECTADO. MANTENTE FIRME.';

  @override
  String get liveness_searching => 'BUSCANDO ROSTRO HUMANO...';

  @override
  String get verif_title => 'CENTRAL DE VERIFICACIÓN';

  @override
  String get verif_header => 'TU SEGURIDAD ES TU MEJOR INVERSIÓN';

  @override
  String get verif_body =>
      'SISTEMA LAD: Completa los pasos para activar tu cuenta de driver. Si ya terminaste un paso en Stripe, jala hacia abajo para refrescar.';

  @override
  String get verif_step1_title => 'Vinculación Bancaria';

  @override
  String get verif_step1_desc =>
      'Configura tu cuenta para recibir pagos directos.';

  @override
  String get verif_step1_btn_active => 'CUENTA ACTIVA';

  @override
  String get verif_step1_btn_retry => 'REINTENTAR / CONTINUAR';

  @override
  String get verif_step1_btn_config => 'CONFIGURAR PAGOS';

  @override
  String get verif_step1_sync_btn => 'YA TERMINÉ EN STRIPE (VERIFICAR AHORA)';

  @override
  String get verif_step1_success => '✅ ¡Cuenta activada con éxito!';

  @override
  String get verif_step1_pending => 'ℹ️ Stripe aún está procesando tus datos.';

  @override
  String get verif_step2_title => 'Verificar Identidad';

  @override
  String get verif_step2_desc => 'Escanea tu ID y tómate una selfie.';

  @override
  String get verif_step2_btn_verified => 'IDENTIDAD VERIFICADA';

  @override
  String get verif_step2_btn_start => 'INICIAR ESCANEO ID';

  @override
  String get verif_step3_title => 'Llave de Seguridad (2FA)';

  @override
  String get verif_step3_desc => 'Blindaje de acceso con Google Authenticator.';

  @override
  String get verif_step4_title => 'Foto de Perfil Profesional';

  @override
  String get verif_step4_desc =>
      'Sube una foto clara para que tus clientes te reconozcan.';

  @override
  String get verif_footer =>
      'Tus datos están encriptados y son procesados directamente por Stripe bajo estándares bancarios.';

  @override
  String get order_status_driver_busy => 'DRIVER OCUPADO';

  @override
  String get order_status_route_problems => 'PROBLEMAS EN LA RUTA';

  @override
  String get order_status_driver_timeout =>
      'EL DRIVER NO LLEGÓ A TIEMPO. ASIGNE OTRO.';

  @override
  String get order_cancel_dialog_title => '¿CANCELAR ORDEN?';

  @override
  String get order_cancel_dialog_body =>
      'Esta acción cancelará la solicitud definitivamente.';

  @override
  String get order_cancel_btn_confirm => 'SÍ, CANCELAR';

  @override
  String get ss_dialog_title => '¿QUÉ BUSCAMOS HOY?';

  @override
  String get ss_dialog_hint => 'Ej: Pizza, Farmacia, Best Buy...';

  @override
  String get ss_btn_search => 'BUSCAR';

  @override
  String get ss_notif_title => '¡BINGO! CAPTURA';

  @override
  String get ss_notif_body =>
      'Detectamos que tomaste una captura del ticket. ¿Deseas procesarla ahora para crear tu orden?';

  @override
  String get ss_ocr_error_title => 'TICKET NO DETECTADO';

  @override
  String get ss_ocr_error_body =>
      'No pudimos extraer una dirección clara de la imagen. Por favor, asegúrate de que el ticket sea legible o ingresa la dirección manualmente.';

  @override
  String get order_status_delivery_delayed => 'ENTREGA RETRASADA';

  @override
  String get order_status_delivery_delayed_msg =>
      'ESTA ENTREGA LLEVA MÁS DE 2 HORAS. HEMOS NOTIFICADO AL DRIVER.';

  @override
  String get driver_quarantine_title => 'MODO CUARENTENA ACTIVO';

  @override
  String get driver_quarantine_body =>
      'Llevas más de 2 horas con una entrega pendiente. No podrás recibir nuevas misiones hasta completar tus entregas activas.';

  @override
  String get prof_btn_rate_app => 'CALIFICAR LA APP';

  @override
  String get prof_rate_app_subtitle => 'Ayúdanos a mejorar en la tienda';

  @override
  String get prof_support_title => 'RECLAMACIONES Y SUGERENCIAS';

  @override
  String get client_dash_already_linked =>
      'Este driver ya está en tu red de confianza.';

  @override
  String get client_dash_no_new_invitations =>
      'No se encontraron nuevas invitaciones en el enlace.';

  @override
  String get common_access_denied => 'ACCESO DENEGADO';

  @override
  String get logout_online_error =>
      'Aún apareces como ONLINE en el sistema de Drivers. Por favor, ve a tu panel de Driver y ponte fuera de línea antes de cerrar sesión.';

  @override
  String get common_understood => 'ENTENDIDO';

  @override
  String get bingo_magic_title => 'MAGIA BINGO';

  @override
  String get bingo_magic_subtitle => 'Pide en un toque con tu ticket';

  @override
  String get bingo_upload_screenshot => 'BINGO: SUBIR SCREENSHOT';

  @override
  String get support_center_title => 'CENTRO DE SOPORTE LAD';

  @override
  String get support_subject_label => 'Asunto / Motivo';

  @override
  String get support_message_label => 'Escribe tu mensaje...';

  @override
  String get common_send => 'ENVIAR';

  @override
  String get support_success_msg => '✅ Mensaje enviado al búnker.';

  @override
  String get driver_dash_invite_title => 'VINCULAR NUEVO CLIENTE';

  @override
  String get driver_dash_invite_body =>
      'Muestra este código o comparte el link para que tus clientes te envíen pedidos directamente.';

  @override
  String get driver_dash_btn_share_invite => 'COMPARTIR INVITACIÓN';

  @override
  String get driver_dash_share_invite_sub => 'WhatsApp, Mensajes, etc.';

  @override
  String get common_close => 'CERRAR';

  @override
  String get common_qr_error => 'Error al generar QR';

  @override
  String get bingo_dialog_title => 'AÑADIR TICKET O FOTO';

  @override
  String get bingo_dialog_body =>
      'Selecciona el origen de la imagen para el auto-llenado BINGO.';

  @override
  String get common_camera => 'CÁMARA';

  @override
  String get common_gallery => 'GALERÍA';

  @override
  String get ocr_dialog_exact_title => 'UBICACIÓN EXACTA';

  @override
  String get ocr_dialog_auto_title => 'DETECCIÓN AUTOMÁTICA';

  @override
  String get ocr_label_store => 'ESTABLECIMIENTO:';

  @override
  String get ocr_label_address => 'DIRECCIÓN SUGERIDA:';

  @override
  String get ocr_label_order => 'NÚMERO DE ORDEN:';

  @override
  String get ocr_btn_autofill => 'AUTO-LLENAR';

  @override
  String get create_order_pickup_origin => 'PUNTO DE ORIGEN';

  @override
  String get create_order_dropoff_dest => 'PUNTO DE DESTINO';

  @override
  String get create_order_details_label => 'DETALLES';

  @override
  String get create_order_gps_tooltip => 'USAR MI UBICACIÓN ACTUAL';

  @override
  String get create_order_verified_msg =>
      '✓ UBICACIÓN EXACTA VERIFICADA (SISTEMA LAD)';

  @override
  String get create_order_unverified_msg =>
      '⚠ LA DIRECCIÓN NO ES TAN PRECISA, EL DRIVER HARÁ LO POSIBLE POR ENCONTRARLA.';

  @override
  String get order_status_rejected => 'MISIÓN RECHAZADA';

  @override
  String get client_dash_rejected_requests_title => 'SOLICITUDES RECHAZADAS';

  @override
  String get alert_rejected_title => '⚠️ MISIÓN RECHAZADA';

  @override
  String alert_rejected_body(String name) {
    return 'El driver $name ha declinado tu solicitud.';
  }

  @override
  String get alert_new_offer_title => '💰 NUEVA OFERTA';

  @override
  String alert_new_offer_body(String name) {
    return 'El driver $name ha enviado una propuesta.';
  }

  @override
  String get common_reassign => 'REASIGNAR';

  @override
  String get common_sync => 'SINCRONIZAR';

  @override
  String neg_error_min_price(String price) {
    return 'PRECIO NO VÁLIDO: El mínimo es \$$price.';
  }
}
