// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get earnings_title => 'WORK ZONES';

  @override
  String get earnings_period_today => 'Today';

  @override
  String get earnings_period_week => 'This Week';

  @override
  String get earnings_period_month => 'Current Month';

  @override
  String get earnings_period_year => 'Fiscal Year';

  @override
  String get earnings_stat_gross => 'GROSS INCOME';

  @override
  String get earnings_stat_miles => 'FISCAL MILES';

  @override
  String get earnings_stat_missions => 'MISSIONS';

  @override
  String get earnings_stat_efficiency => 'EFFICIENCY';

  @override
  String get earnings_history_title => 'MISSION HISTORY';

  @override
  String get earnings_empty_history => 'No missions in this period.';

  @override
  String get earnings_network_title => 'MY ACTION RADIUS';

  @override
  String get earnings_linked_users => 'LINKED USERS';

  @override
  String get earnings_referrals_count => 'Referrals';

  @override
  String get earnings_plan_label => 'SELECTED ZONE';

  @override
  String get earnings_refund_title => 'ZONE STATUS';

  @override
  String get earnings_refund_covered => 'ACTIVE';

  @override
  String get earnings_refund_saving => 'FREE';

  @override
  String get earnings_refund_status_free_current => 'ZONE NO CHARGE';

  @override
  String get earnings_refund_status_free_next => 'CHANGE AVAILABLE';

  @override
  String get earnings_refund_goal_msg => 'Configure your action radius freely.';

  @override
  String get earnings_refund_success_msg => 'Zone configured correctly.';

  @override
  String get earnings_refund_pending_msg => 'Configuration in progress...';

  @override
  String get earnings_refund_anti_fraud_rule =>
      'Zone change is instant and at no cost.';

  @override
  String get earnings_refund_disclaimer =>
      'LAD Courier does not charge a monthly fee. Only a \$0.50 service fee per successful order, regardless of the agreed price.';

  @override
  String get driver_dash_title => 'DRIVER COMMAND CENTER';

  @override
  String get driver_status_online => 'DRIVER ONLINE';

  @override
  String get driver_status_offline => 'OFF DUTY';

  @override
  String get driver_btn_work_zone => 'OPERATIONAL MAP';

  @override
  String get driver_menu_services => 'SERVICES';

  @override
  String get driver_menu_profile => 'MY PROFILE';

  @override
  String get driver_menu_earnings => 'ZONES';

  @override
  String get driver_menu_invite => 'INVITE';

  @override
  String get driver_dialog_services_title => 'ACTIVE SERVICES';

  @override
  String get driver_btn_confirm => 'CONFIRM';

  @override
  String get driver_error_no_photo => 'MISSING PROFILE PHOTO';

  @override
  String get driver_error_no_photo_msg =>
      'You must upload a professional photo so customers can identify you.';

  @override
  String get driver_error_incomplete_data => 'INCOMPLETE DATA';

  @override
  String get driver_error_incomplete_data_msg =>
      'Your name and phone are mandatory for service security.';

  @override
  String get driver_error_no_vehicle => 'VEHICLE DETAILS';

  @override
  String get driver_error_no_vehicle_msg =>
      'Describe your transport in the My Profile section.';

  @override
  String get driver_error_no_membership => 'ZONE NOT SELECTED';

  @override
  String get driver_error_no_membership_msg =>
      'You must select a \'Work Zone\' (Lite, Standard or Pro) to receive orders.';

  @override
  String get driver_error_no_stripe => 'STRIPE NOT LINKED';

  @override
  String get driver_error_no_stripe_msg =>
      'To get online, you must configure your Stripe Connect account in \'My Profile\'.';

  @override
  String get driver_error_no_verification => 'VERIFICATION PENDING';

  @override
  String get driver_error_no_verification_msg =>
      'You must complete your identity verification and background check to go online.';

  @override
  String get driver_error_no_services => 'NO ACTIVE SERVICES';

  @override
  String get driver_error_no_services_msg =>
      'Select at least one service before going online.';

  @override
  String get driver_active_missions_alert =>
      '⚠️ YOU HAVE ACTIVE MISSIONS. Finish them first.';

  @override
  String get driver_btn_understand => 'UNDERSTOOD';

  @override
  String get driver_selection_title => 'Choose Driver';

  @override
  String get driver_card_plan => 'Zone';

  @override
  String get driver_card_coverage => 'Coverage';

  @override
  String get driver_selection_no_drivers_title => 'We\'re sorry';

  @override
  String get driver_selection_no_drivers_body =>
      'No available drivers cover these locations within their work zone. Try a shorter distance.';

  @override
  String get notification_order_sent_success => 'Mission sent to driver';

  @override
  String get prof_title => 'MY OPERATIONAL PROFILE';

  @override
  String get prof_radar_title => 'MY RECRUITMENT RADAR';

  @override
  String get prof_radar_body =>
      'Your customers scan this QR to link to your network.';

  @override
  String get prof_section_id => 'IDENTIFICATION DATA';

  @override
  String get prof_label_name => 'Full Name';

  @override
  String get prof_label_phone => 'Contact Phone';

  @override
  String get prof_label_vehicle => 'Vehicle Description';

  @override
  String get prof_section_mem => 'WORK ZONES';

  @override
  String get prof_section_pay => 'PAYMENT TOOLS (STRIPE)';

  @override
  String get prof_pay_stripe => 'Link Stripe Connect';

  @override
  String get prof_pay_stripe_sub => 'To receive your payments instantly';

  @override
  String get prof_pay_paypal => 'PayPal (Optional)';

  @override
  String get prof_pay_paypal_sub => 'Only for manual collections';

  @override
  String get prof_btn_save => 'SAVE CHANGES';

  @override
  String get prof_btn_switch => 'SWITCH TO CUSTOMER MODE';

  @override
  String get work_title => 'OPERATIONS MAP';

  @override
  String get work_panel_title => 'PENDING REQUESTS';

  @override
  String get work_waiting => 'Waiting for new missions...';

  @override
  String get work_alert_title => '🚀 NEW MISSION DETECTED!';

  @override
  String get work_alert_body => 'You have a new request on the radar.';

  @override
  String get work_notif_channel_name => 'Urgent Order Alerts';

  @override
  String get work_notif_channel_desc => 'Channel for new mission notifications';

  @override
  String get sub_title => 'WORK ZONES';

  @override
  String get sub_promo => 'ELABORATE YOUR OWN ROUTE FREELY';

  @override
  String get sub_free => 'FREE';

  @override
  String sub_radius(String radius) {
    return 'Radius: $radius';
  }

  @override
  String sub_bonus(String bonus) {
    return 'Cost: $bonus';
  }

  @override
  String get sub_btn_activate => 'ACTIVATE ZONE';

  @override
  String get welcome_title => 'Welcome Aboard!';

  @override
  String get welcome_body =>
      'To finalize your registration, please choose your role in our community.';

  @override
  String get welcome_btn_client => 'I am a Customer';

  @override
  String get welcome_btn_driver => 'I am a Courier';

  @override
  String get client_dash_title => 'CUSTOMER COMMAND CENTER';

  @override
  String get client_dash_welcome => 'LAD COURIER SYSTEM';

  @override
  String get client_dash_requested_services => 'REQUESTED SERVICES';

  @override
  String get client_dash_no_requests => 'No pending requests.';

  @override
  String get client_dash_new_request => 'NEW REQUEST';

  @override
  String get client_dash_first_offer => 'FIRST OFFER RECEIVED';

  @override
  String get client_dash_counter_offer => 'COUNTER-OFFER RECEIVED';

  @override
  String client_dash_driver_label(String name) {
    return 'Driver: $name';
  }

  @override
  String get client_dash_active_missions => 'ONGOING MISSIONS';

  @override
  String client_dash_price_label(String price) {
    return 'PRICE: $price';
  }

  @override
  String client_dash_status_label(String status) {
    return 'Status: $status';
  }

  @override
  String get client_dash_linked_drivers => 'DRIVERS LIST';

  @override
  String get client_dash_no_linked_drivers => 'You have no linked drivers.';

  @override
  String get client_dash_driver_available => 'AVAILABLE';

  @override
  String get client_dash_driver_resting => 'RESTING';

  @override
  String client_dash_services_label(String services) {
    return 'SERVICES: $services';
  }

  @override
  String client_dash_plan_label(String plan) {
    return 'ZONE: $plan';
  }

  @override
  String client_dash_radius_label(String radius) {
    return 'RADIUS: $radius';
  }

  @override
  String get client_dash_no_phone => 'No Phone';

  @override
  String get client_dash_unlink_title => 'UNLINK DRIVER';

  @override
  String client_dash_unlink_confirm(String name) {
    return 'Are you sure you want to remove $name from your trusted list?';
  }

  @override
  String get client_dash_unlink_button => 'UNLINK';

  @override
  String get client_dash_unlink_success => 'Driver successfully unlinked';

  @override
  String get client_dash_invite_title => 'LINK DRIVER';

  @override
  String get client_dash_invite_hint => 'Driver Code or ID';

  @override
  String get common_confirm => 'CONFIRM';

  @override
  String get common_cancel => 'CANCEL';

  @override
  String get client_prof_title => 'MY CUSTOMER PROFILE';

  @override
  String get client_prof_contact_details => 'CONTACT DETAILS';

  @override
  String get client_prof_name_label => 'Full Name';

  @override
  String get client_prof_phone_label => 'Phone';

  @override
  String get client_prof_address_label => 'Main Address';

  @override
  String get client_prof_payment_methods => 'PAYMENT METHODS';

  @override
  String get client_prof_stripe_title => 'Stripe';

  @override
  String get client_prof_stripe_subtitle => 'Credit/Debit Card';

  @override
  String get client_prof_paypal_title => 'PayPal';

  @override
  String get client_prof_paypal_subtitle => 'Digital Account';

  @override
  String get client_prof_cta_title => 'EARN MONEY AS A DRIVER!';

  @override
  String get client_prof_cta_body =>
      'Join our network of couriers and generate income in your free time.';

  @override
  String get client_prof_cta_button => 'VIEW DRIVER ZONES';

  @override
  String get client_prof_save_button => 'SAVE CHANGES';

  @override
  String get client_prof_switch_button => 'SWITCH TO DRIVER MODE';

  @override
  String get client_prof_update_success => 'Profile updated';

  @override
  String client_prof_update_error(String error) {
    return 'Update error: $error';
  }

  @override
  String get client_prof_completed_orders => 'COMPLETED ORDERS';

  @override
  String get client_dash_history_title => 'MISSION HISTORY (36H)';

  @override
  String order_details_title(String type, int index) {
    return '$type ORDER #$index';
  }

  @override
  String order_details_id(String id) {
    return 'Order ID: $id';
  }

  @override
  String get order_details_pickup => 'PICKUP POINT';

  @override
  String get order_details_delivery => 'DELIVERY POINT';

  @override
  String get order_details_instructions => 'MISSION INSTRUCTIONS';

  @override
  String get order_details_no_instructions =>
      'No specific instructions from the customer.';

  @override
  String get order_details_proximity_on => 'YOU ARE AT THE LOCATION!';

  @override
  String get order_details_proximity_off => 'DISTANCE TO POINT';

  @override
  String order_details_meters(String meters) {
    return '$meters meters';
  }

  @override
  String get order_details_btn_go_pickup => 'GO TO PICKUP';

  @override
  String get order_details_btn_arrived => 'ARRIVED / PICKED UP';

  @override
  String get order_details_btn_go_delivery => 'GO TO DELIVERY';

  @override
  String get order_details_btn_photo => 'TAKE PROOF PHOTO';

  @override
  String get order_details_btn_finish => 'FINISH MISSION';

  @override
  String get order_details_photo_success => 'Photo captured';

  @override
  String get order_details_evidence_msg =>
      'Evidence saved with GPS coordinates';

  @override
  String get order_details_btn_view_proof => 'VIEW PROOF OF DELIVERY';

  @override
  String order_details_multiple_warning(int count) {
    return 'YOU HAVE $count MORE ORDERS AT THIS LOCATION';
  }

  @override
  String get neg_title => 'NEGOTIATION';

  @override
  String get neg_client_initial => 'INITIAL REQUEST (NO PRICE)';

  @override
  String get neg_client_counter => 'CUSTOMER COUNTER-OFFER';

  @override
  String get neg_driver_last => 'YOUR LAST OFFER';

  @override
  String get neg_input_label => 'YOUR PROPOSAL (\$)';

  @override
  String get neg_btn_accept => 'ACCEPT';

  @override
  String get neg_btn_first => 'FIRST OFFER';

  @override
  String get neg_btn_counter => 'NEW COUNTER-OFFER';

  @override
  String get neg_btn_final => 'SEND FINAL OFFER';

  @override
  String get neg_btn_reject => 'REJECT AND CLOSE';

  @override
  String neg_impact_single(String miles) {
    return 'This order represents a total trip of $miles miles.';
  }

  @override
  String neg_impact_multi(String miles) {
    return 'Adding this order adds $miles extra miles to your current route.';
  }

  @override
  String get create_order_title => 'CREATE ORDER';

  @override
  String get create_order_service_label => 'Available Service Type';

  @override
  String get create_order_pickup_hint => 'Origin (Exact address)';

  @override
  String get create_order_dropoff_hint => 'Destination (Exact address)';

  @override
  String get create_order_details_hint => 'Package details';

  @override
  String get create_order_pickup_label => '4. PICKUP ADDRESS';

  @override
  String get create_order_dropoff_label => '5. DELIVERY ADDRESS';

  @override
  String get create_order_description_label => '3. PACKAGE DESCRIPTION';

  @override
  String get create_order_btn_send => 'SEND ORDER';

  @override
  String get create_order_success => '✅ ORDER SENT';

  @override
  String get create_order_error_address => 'Invalid address.';

  @override
  String create_order_error_radius(String radius) {
    return 'Destination is outside the permitted radius ($radius mi).';
  }

  @override
  String get create_order_error_session => 'Session expired.';

  @override
  String get create_order_required => 'Required field';

  @override
  String create_order_geofence_error(String radius) {
    return '⚠️ OUT OF COVERAGE: This Driver operates in a $radius mi radius. Both pickup and delivery must be within their work zone.';
  }

  @override
  String get create_order_sent_toast => '🚀 REQUEST SENT';

  @override
  String get create_order_client_default => 'Customer';

  @override
  String get neg_client_details_title => 'OFFER DETAILS';

  @override
  String get neg_client_closing => 'Closing negotiation...';

  @override
  String get neg_client_waiting => 'Waiting for offer...';

  @override
  String get neg_client_driver_assigned => 'DRIVER ASSIGNED';

  @override
  String get neg_client_order_details => 'ORDER DETAILS';

  @override
  String get neg_client_price_proposal => 'PRICE PROPOSAL';

  @override
  String get neg_client_price_final => 'DRIVER FINAL OFFER';

  @override
  String get neg_client_btn_accept => 'ACCEPT AND ORDER NOW';

  @override
  String get neg_client_btn_accept_final => 'ACCEPT LAST OFFER';

  @override
  String get neg_client_btn_counter => 'MAKE COUNTER-OFFER';

  @override
  String get neg_client_btn_reject_cancel => 'REJECT AND CANCEL';

  @override
  String get neg_client_dialog_title => 'YOUR COUNTER-OFFER';

  @override
  String get neg_client_dialog_body => 'Propose a new price to the driver:';

  @override
  String get neg_client_dialog_label => 'New Price';

  @override
  String get neg_client_dialog_btn_cancel => 'REJECT';

  @override
  String get neg_client_dialog_btn_send => 'SEND';

  @override
  String get auth_sync_security => 'Syncing security...';

  @override
  String get auth_sync_timeout =>
      'If it takes too long, press the button below.';

  @override
  String get auth_cancel_retry => 'Cancel and retry';

  @override
  String get auth_login_welcome => 'Welcome back, soldier!';

  @override
  String get auth_login_email => 'Email';

  @override
  String get auth_login_password => 'Password';

  @override
  String get auth_login_btn => 'Log In';

  @override
  String get auth_login_not_member => 'Not a member?';

  @override
  String get auth_login_register_now => 'Register now';

  @override
  String get auth_register_title => 'Create an account to start!';

  @override
  String get auth_register_name => 'Full Name';

  @override
  String get auth_register_confirm_pass => 'Confirm Password';

  @override
  String get auth_register_btn => 'REGISTER';

  @override
  String get auth_register_already_member => 'Already a member?';

  @override
  String get auth_register_login_now => 'Log in now';

  @override
  String get auth_error_fields => 'Please fill in all fields.';

  @override
  String get auth_error_pass_match => 'Passwords do not match';

  @override
  String get auth_error_name => 'Enter your full name';

  @override
  String get auth_role_title => 'Welcome to LAD!';

  @override
  String get auth_role_subtitle => 'Choose how you want to use the platform:';

  @override
  String get auth_role_client => 'I AM A CUSTOMER';

  @override
  String get auth_role_messenger => 'I AM A COURIER';

  @override
  String get auth_role_preparing => 'Preparing your account...';

  @override
  String get service_location_disabled => 'Location services are disabled.';

  @override
  String get service_location_denied => 'Location permissions are denied.';

  @override
  String get service_location_denied_forever =>
      'Location permissions are permanently denied.';

  @override
  String get service_invitation_error_user =>
      'Error: User could not be identified.';

  @override
  String service_invitation_share_msg(String link) {
    return 'Hi! 👋 I invite you to join my personal network on LAD Courier. It\'s the fastest and safest way to manage your shipments with me. Register here: $link';
  }

  @override
  String get service_invitation_subject => '🚚 Join my courier network on LAD!';

  @override
  String service_recommend_share_msg(String name, String link) {
    return '🚀 Hi! I recommend $name for your deliveries. He is my trusted courier on LAD COURIER. You can contact him by downloading the app here: $link';
  }

  @override
  String get service_recommend_subject =>
      'I recommend my courier on LAD Courier';

  @override
  String auth_error_role_save(String error) {
    return 'Error saving role: $error';
  }

  @override
  String get order_error_deleted => 'The order has been deleted.';

  @override
  String get order_status_active_msg => 'ACTIVE ORDER';

  @override
  String get order_status_timeout_msg => 'Timeout (30 min).';

  @override
  String get order_status_timeout_full_msg =>
      'Due to the large number of orders, the driver could not attend to it in time. Please send it to another available driver. Thank you!';

  @override
  String auth_error_generic(String message) {
    return 'Security error: $message';
  }

  @override
  String get deliver_label => 'DELIVER';

  @override
  String get pickup_label => 'PICKUP';

  @override
  String get notification_new_order_title => '🚀 NEW MISSION DETECTED!';

  @override
  String get notification_new_order_body =>
      'You have a new request on the radar.';

  @override
  String get driver_work_zone_title => 'OPERATIONS MAP';

  @override
  String get driver_work_zone_pending_requests => 'PENDING REQUESTS';

  @override
  String get driver_work_zone_waiting => 'Waiting for new missions...';

  @override
  String get dashboard_btn_create_order => 'Create Order';

  @override
  String get client_label => 'Customer';

  @override
  String get counter_offer_label => 'COUNTER-OFFER';

  @override
  String get new_order_label => 'NEW ORDER';

  @override
  String get create_order_requirements => 'REQUIREMENTS';

  @override
  String get create_order_section_messenger => '6. SELECT YOUR DRIVER';

  @override
  String get create_order_search_available => 'Any Driver';

  @override
  String get create_order_add_photo => '2. PHOTO OR RECEIPT';

  @override
  String get create_order_service_type => '1. CHOOSE SERVICE';

  @override
  String get create_order_btn_search_drivers => 'Search available drivers';

  @override
  String get order_details_product_photo => 'PRODUCT PHOTO';

  @override
  String get order_details_save_photo => 'SAVE REFERENCE';

  @override
  String get order_details_photo_saved => 'Photo saved to gallery';

  @override
  String get order_details_photo_error => 'Error saving photo';

  @override
  String get create_order_shopping_nav_btn => 'SHOPPING NAVIGATOR (STORE)';

  @override
  String get create_order_shopping_nav_success =>
      '✅ STORE CAPTURED SUCCESSFULLY';

  @override
  String get shopping_nav_capture => 'CAPTURE';

  @override
  String get shopping_nav_title => 'SHOPPING NAVIGATOR';

  @override
  String get catalog_title => 'SHOPPING NAVIGATOR';

  @override
  String get catalog_no_stores => 'NO NEARBY STORES WITHIN COURIER RADIUS';

  @override
  String get shopping_nav_capturing => 'Uploading evidence...';

  @override
  String get shopping_nav_error_photo =>
      '⚠️ Receipt photo mandatory to continue';

  @override
  String get shopping_nav_success_full =>
      '✅ Store and receipt captured successfully';

  @override
  String get sub_plan_lite_title => 'LITE ZONE';

  @override
  String get sub_plan_lite_desc => 'Ideal for fast local deliveries.';

  @override
  String get sub_plan_standart_title => 'STANDARD ZONE';

  @override
  String get sub_plan_standart_desc =>
      'Covers your entire city and surroundings.';

  @override
  String get sub_plan_pro_title => 'PRO ZONE';

  @override
  String get sub_plan_pro_desc => 'Maximum reach for long freights.';

  @override
  String sub_price_per_month(String price) {
    return '$price / month';
  }

  @override
  String get catalog_cat_all => 'ALL';

  @override
  String get catalog_cat_food => 'GASTRO';

  @override
  String get catalog_cat_fashion => 'FASHION';

  @override
  String get catalog_cat_auto => 'MOTOR';

  @override
  String get catalog_cat_health => 'HEALTH';

  @override
  String get catalog_cat_grocery => 'MARKETS';

  @override
  String get catalog_cat_home => 'HOME';

  @override
  String get catalog_cat_tech => 'TECH';

  @override
  String get catalog_radius => 'Search Radius';

  @override
  String get catalog_select_cat => 'Please select a category';

  @override
  String get catalog_no_results => 'No results found for this category';

  @override
  String get catalog_no_results_area => 'NO RESULTS IN THIS AREA';

  @override
  String get shopping_nav_instruction_title => 'Shopping Instructions';

  @override
  String get shopping_nav_instruction_body =>
      'Navigate, complete your purchase, and once you see the final receipt, press CAPTURE.';

  @override
  String get catalog_no_results_detail =>
      'Try changing category or check if Driver has action radius.';

  @override
  String get catalog_default_name => 'Store';

  @override
  String get driver_service_courier => 'Messaging and Packages';

  @override
  String get driver_service_logistics => 'Specialized Logistics';

  @override
  String get driver_service_shopping => 'Shopping and Errands';

  @override
  String get shopping_nav_instruction_title_alt => '💡 BACKUP PLAN';

  @override
  String get shopping_nav_instruction_body_alt =>
      'If the store forces you to use its official App, place the order there, take a screenshot of the receipt and upload it here.';

  @override
  String get client_dash_order_here => 'ORDER HERE';

  @override
  String get prof_btn_business_card => 'MY BUSINESS CARD';

  @override
  String get business_card_title => 'LAD COURIER BUSINESS CARD';

  @override
  String get business_card_scan_msg =>
      'Scan to download LAD and link to my network';

  @override
  String get common_delete_account => 'DELETE MY ACCOUNT';

  @override
  String get delete_account_confirm_title => 'DELETE ACCOUNT PERMANENTLY?';

  @override
  String get delete_account_confirm_body =>
      'This action will delete all your data, history, and connections. It cannot be undone.';

  @override
  String get delete_account_btn_confirm => 'YES, DELETE EVERYTHING';

  @override
  String get delete_account_reauth_required =>
      'For security, you must log in again before deleting your account.';

  @override
  String get driver_agreement_title => 'SaaS LICENSE AGREEMENT';

  @override
  String get driver_agreement_body =>
      'LAD DIGITAL SYSTEMS LLC grants you a limited, non-exclusive and revocable software use license. You acknowledge that LAD is not your employer. This license can be canceled at any time and for any circumstance at LAD\'s discretion. The Service Fee (\$0.50) and terms may change with prior digital notice.';

  @override
  String get common_payment_required_title => 'PAYMENT LINK REQUIRED';

  @override
  String get common_payment_required_msg =>
      'To ensure the security of your orders, you must link a payment method in your profile.';

  @override
  String get driver_inactivity_title => 'REST MODE';

  @override
  String get driver_inactivity_msg =>
      'Your availability has been automatically closed because you have been inactive for more than 4 hours. If you are ready to work, please go online again.';

  @override
  String get common_logout => 'LOG OUT';

  @override
  String get common_logout_confirm =>
      'Are you sure you want to log out? You will need to enter your email and password again to refresh security.';

  @override
  String get common_exit => 'EXIT';

  @override
  String get common_continue => 'CONTINUE';

  @override
  String get auth_verification_required_title => '🛡️ MANDATORY VERIFICATION';

  @override
  String get auth_verification_required_body =>
      'For security, you must validate your identity with a selfie and your fingerprint to start working.';

  @override
  String get client_dash_negotiations_title => 'NEGOTIATIONS';

  @override
  String get client_dash_no_negotiations => 'No pending negotiations';

  @override
  String get client_dash_no_active_missions => 'No active missions';

  @override
  String get client_dash_order_active => 'ACTIVE ORDER';

  @override
  String client_dash_driver_resting_body(String name) {
    return 'DRIVER $name IS NOT RECEIVING ORDERS AT THIS TIME. WOULD YOU LIKE TO SEARCH FOR ANOTHER AVAILABLE DRIVER?';
  }

  @override
  String get client_dash_invite_code_label => 'ENTER DRIVER LINKING CODE:';
}
