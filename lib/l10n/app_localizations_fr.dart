// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get earnings_title => 'ZONES DE TRAVAIL';

  @override
  String get earnings_period_today => 'Aujourd\'hui';

  @override
  String get earnings_period_week => 'Cette semaine';

  @override
  String get earnings_period_month => 'Mois actuel';

  @override
  String get earnings_period_year => 'Année fiscale';

  @override
  String get earnings_stat_gross => 'REVENUS BRUTS';

  @override
  String get earnings_stat_miles => 'MILLES FISCAUX';

  @override
  String get earnings_stat_missions => 'MISSIONS';

  @override
  String get earnings_stat_efficiency => 'EFFICACITÉ';

  @override
  String get earnings_history_title => 'HISTORIQUE DES MISSIONS';

  @override
  String get earnings_empty_history => 'Aucune mission sur cette période.';

  @override
  String get earnings_network_title => 'MON RAYON D\'ACTION';

  @override
  String get earnings_linked_users => 'UTILISATEURS LIÉS';

  @override
  String get earnings_referrals_count => 'Parrainages';

  @override
  String get earnings_plan_label => 'ZONE SÉLECTIONNÉE';

  @override
  String get earnings_refund_title => 'ÉTAT DE LA ZONE';

  @override
  String get earnings_refund_covered => 'ACTIVE';

  @override
  String get earnings_refund_saving => 'GRATUIT';

  @override
  String get earnings_refund_status_free_current => 'ZONE SANS FRAIS';

  @override
  String get earnings_refund_status_free_next => 'CHANGEMENT DISPONIBLE';

  @override
  String get earnings_refund_goal_msg =>
      'Configurez votre rayon d\'action librement.';

  @override
  String get earnings_refund_success_msg => 'Zone configurée correctement.';

  @override
  String get earnings_refund_pending_msg => 'Configuration en cours...';

  @override
  String get earnings_refund_anti_fraud_rule =>
      'Le changement de zone est instantané et gratuit.';

  @override
  String get earnings_refund_disclaimer =>
      'LAD Courier ne facture pas de frais mensuels. Uniquement des frais de service de 0,50 \$ par commande réussie, quel que soit le prix convenu.';

  @override
  String get driver_dash_title => 'CENTRE DE COMMANDE DRIVER';

  @override
  String get driver_status_online => 'DRIVER EN Ligne';

  @override
  String get driver_status_offline => 'HORS SERVICE';

  @override
  String get driver_btn_work_zone => 'CARTE OPÉRATIONNELLE';

  @override
  String get driver_menu_services => 'SERVICES';

  @override
  String get driver_menu_profile => 'MON PROFIL';

  @override
  String get driver_menu_earnings => 'ZONES';

  @override
  String get driver_menu_invite => 'INVITER';

  @override
  String get driver_dialog_services_title => 'SERVICES ACTIFS';

  @override
  String get driver_btn_confirm => 'CONFIRMER';

  @override
  String get driver_error_no_photo => 'PHOTO DE PROFIL MANQUANTE';

  @override
  String get driver_error_no_photo_msg =>
      'Vous devez télécharger une photo professionnelle pour que vos clients puissent vous identifier.';

  @override
  String get driver_error_incomplete_data => 'DONNÉES INCOMPLÈTES';

  @override
  String get driver_error_incomplete_data_msg =>
      'Votre nom et votre téléphone sont obligatoires pour la sécurité du service.';

  @override
  String get driver_error_no_vehicle => 'DÉTAILS DU VÉHICULE';

  @override
  String get driver_error_no_vehicle_msg =>
      'Décrivez votre moyen de transport dans la section Mon Profil.';

  @override
  String get driver_error_no_membership => 'ZONE NON SÉLECTIONNÉE';

  @override
  String get driver_error_no_membership_msg =>
      'Vous devez sélectionner une \'Zone de Travail\' (Lite, Standard ou Pro) pour recevoir des commandes.';

  @override
  String get driver_error_no_stripe => 'STRIPE NON LIÉ';

  @override
  String get driver_error_no_stripe_msg =>
      'Pour vous mettre en ligne, vous devez configurer votre compte Stripe Connect dans \'Mon Profil\'.';

  @override
  String get driver_error_no_verification => 'VÉRIFICATION EN ATTENTE';

  @override
  String get driver_error_no_verification_msg =>
      'Vous devez terminer votre vérification d\'identité et votre vérification d\'antécédents pour vous mettre en ligne.';

  @override
  String get driver_error_no_services => 'AUCUN SERVICE ACTIF';

  @override
  String get driver_error_no_services_msg =>
      'Sélectionnez au moins un service avant de vous mettre en ligne.';

  @override
  String get driver_active_missions_alert =>
      '⚠️ VOUS AVEZ DES MISSIONS ACTIVES. Terminez-les d\'abord.';

  @override
  String get driver_btn_understand => 'COMPRIS';

  @override
  String get driver_selection_title => 'Choisir un coursier';

  @override
  String get driver_card_plan => 'Zone';

  @override
  String get driver_card_coverage => 'Couverture';

  @override
  String get driver_selection_no_drivers_title => 'Nous sommes désolés';

  @override
  String get driver_selection_no_drivers_body =>
      'Aucun coursier n\'est disponible pour couvrir ces adresses dans sa zone de travail. Essayez une distance plus courte.';

  @override
  String get notification_order_sent_success => 'Mission envoyée au coursier';

  @override
  String get prof_title => 'MON PROFIL OPÉRATIONNEL';

  @override
  String get prof_radar_title => 'MON RADAR DE RECRUTEMENT';

  @override
  String get prof_radar_body =>
      'Vos clients scannent ce QR pour se lier à votre réseau.';

  @override
  String get prof_section_id => 'DONNÉES D\'IDENTIFICATION';

  @override
  String get prof_label_name => 'Nom complet';

  @override
  String get prof_label_phone => 'Téléphone de contact';

  @override
  String get prof_label_vehicle => 'Description du véhicule';

  @override
  String get prof_section_mem => 'ZONES DE TRAVAIL';

  @override
  String get prof_section_pay => 'OUTILS DE PAIEMENT (STRIPE)';

  @override
  String get prof_pay_stripe => 'Lier Stripe Connect';

  @override
  String get prof_pay_stripe_sub =>
      'Pour recevoir vos paiements instantanément';

  @override
  String get prof_pay_paypal => 'Lier PayPal (Optionnel)';

  @override
  String get prof_pay_paypal_sub => 'Uniquement pour les encaissements manuels';

  @override
  String get prof_btn_save => 'ENREGISTRER LES MODIFICATIONS';

  @override
  String get prof_btn_switch => 'PASSER EN MODE CLIENT';

  @override
  String get work_title => 'CARTE DES OPÉRATIONS';

  @override
  String get work_panel_title => 'DEMANDES EN ATTENTE';

  @override
  String get work_waiting => 'En attente de nouvelles missions...';

  @override
  String get work_alert_title => '🚀 NOUVELLE MISSION DÉTECTÉE !';

  @override
  String get work_alert_body => 'Vous avez une nouvelle demande sur le radar.';

  @override
  String get work_notif_channel_name => 'Alertas de Commandes Urgentes';

  @override
  String get work_notif_channel_desc =>
      'Canal pour les notifications de nouvelles missions';

  @override
  String get sub_title => 'ZONES DE TRAVAIL';

  @override
  String get sub_promo => 'ÉLABOREZ VOTRE PROPRE ITINÉRAIRE LIBREMENT';

  @override
  String get sub_free => 'GRATUIT';

  @override
  String sub_radius(String radius) {
    return 'Portée : $radius';
  }

  @override
  String sub_bonus(String bonus) {
    return 'Coût : $bonus';
  }

  @override
  String get sub_btn_activate => 'ACTIVER LA ZONE';

  @override
  String get welcome_title => 'Bienvenue à bord !';

  @override
  String get welcome_body =>
      'Pour finaliser votre inscription, veuillez choisir votre rôle dans notre communauté.';

  @override
  String get welcome_btn_client => 'Je suis Client';

  @override
  String get welcome_btn_driver => 'Je suis Coursier';

  @override
  String get client_dash_title => 'CENTRE DE COMMANDEMENT CLIENT';

  @override
  String get client_dash_welcome => 'SYSTÈME LAD COURIER';

  @override
  String get client_dash_requested_services => 'SERVICES DEMANDÉS';

  @override
  String get client_dash_no_requests => 'Aucune demande en attente.';

  @override
  String get client_dash_new_request => 'NOUVELLE DEMANDE';

  @override
  String get client_dash_first_offer => 'PREMIÈRE OFFRE REÇUE';

  @override
  String get client_dash_counter_offer => 'CONTRE-OFFRE REÇUE';

  @override
  String client_dash_driver_label(String name) {
    return 'Driver : $name';
  }

  @override
  String get client_dash_active_missions => 'MISSIONS EN COURS';

  @override
  String client_dash_price_label(String price) {
    return 'PRIX : $price';
  }

  @override
  String client_dash_status_label(String status) {
    return 'Statut : $status';
  }

  @override
  String get client_dash_linked_drivers => 'LISTE DES DRIVERS';

  @override
  String get client_dash_no_linked_drivers =>
      'Vous n\'avez pas de drivers liés.';

  @override
  String get client_dash_driver_available => 'DISPONIBLE';

  @override
  String get client_dash_driver_resting => 'AU REPOS';

  @override
  String client_dash_services_label(String services) {
    return 'SERVICES : $services';
  }

  @override
  String client_dash_plan_label(String plan) {
    return 'ZONE : $plan';
  }

  @override
  String client_dash_radius_label(String radius) {
    return 'RAYON : $radius';
  }

  @override
  String get client_dash_no_phone => 'Sans Tél';

  @override
  String get client_dash_unlink_title => 'DÉLIER LE DRIVER';

  @override
  String client_dash_unlink_confirm(String name) {
    return 'Êtes-vous sûr de vouloir supprimer $name de votre liste de confiance ?';
  }

  @override
  String get client_dash_unlink_button => 'DÉLIER';

  @override
  String get client_dash_unlink_success => 'Driver délié avec succès';

  @override
  String get client_dash_invite_title => 'LIER UN DRIVER';

  @override
  String get client_dash_invite_hint => 'Code ou ID du Driver';

  @override
  String get common_confirm => 'CONFIRMER';

  @override
  String get common_cancel => 'ANNULER';

  @override
  String get client_prof_title => 'MON PROFIL CLIENT';

  @override
  String get client_prof_contact_details => 'COORDONNÉES';

  @override
  String get client_prof_name_label => 'Nom complet';

  @override
  String get client_prof_phone_label => 'Téléphone';

  @override
  String get client_prof_address_label => 'Adresse principale';

  @override
  String get client_prof_payment_methods => 'MÉTHODES DE PAIEMENT';

  @override
  String get client_prof_stripe_title => 'Stripe';

  @override
  String get client_prof_stripe_subtitle => 'Carte de Crédit/Débit';

  @override
  String get client_prof_paypal_title => 'PayPal';

  @override
  String get client_prof_paypal_subtitle => 'Compte Numérique';

  @override
  String get client_prof_cta_title => 'GAGNEZ DE L\'ARGENT COMME DRIVER !';

  @override
  String get client_prof_cta_body =>
      'Rejoignez notre réseau de coursiers et générez des revenus pendant votre temps libre.';

  @override
  String get client_prof_cta_button => 'VOIR LES ZONES DRIVER';

  @override
  String get client_prof_save_button => 'ENREGISTRER LES MODIFICATIONS';

  @override
  String get client_prof_switch_button => 'PASSER EN MODE DRIVER';

  @override
  String get client_prof_update_success => 'Profil mis à jour';

  @override
  String client_prof_update_error(String error) {
    return 'Erreur lors de la mise à jour : $error';
  }

  @override
  String get client_prof_completed_orders => 'COMMANDES TERMINÉES';

  @override
  String get client_dash_history_title => 'HISTORIQUE DES MISSIONS (36H)';

  @override
  String order_details_title(String type, int index) {
    return 'ORDRE $type #$index';
  }

  @override
  String order_details_id(String id) {
    return 'ID Commande : $id';
  }

  @override
  String get order_details_pickup => 'POINT DE RAMASSAGE';

  @override
  String get order_details_delivery => 'POINT DE LIVRAISON';

  @override
  String get order_details_instructions => 'INSTRUCTIONS DE LA MISSION';

  @override
  String get order_details_no_instructions =>
      'Aucune instruction spécifique du client.';

  @override
  String get order_details_proximity_on => 'VOUS ÊTES SUR PLACE !';

  @override
  String get order_details_proximity_off => 'DISTANCE AU POINT';

  @override
  String order_details_meters(String meters) {
    return '$meters mètres';
  }

  @override
  String get order_details_btn_go_pickup => 'ALLER AU RAMASSAGE';

  @override
  String get order_details_btn_arrived => 'ARRIVÉ / RÉCUPÉRÉ';

  @override
  String get order_details_btn_go_delivery => 'ALLER À LA LIVRAISON';

  @override
  String get order_details_btn_photo => 'PRENDRE UNE PHOTO PREUVE';

  @override
  String get order_details_btn_finish => 'TERMINER LA MISSION';

  @override
  String get order_details_photo_success => 'Photo capturée';

  @override
  String get order_details_evidence_msg =>
      'Preuve enregistrée avec coordonnées GPS';

  @override
  String get order_details_btn_view_proof => 'VOIR LA PREUVE DE LIVRAISON';

  @override
  String order_details_multiple_warning(int count) {
    return 'VOUS AVEZ $count AUTRES COMMANDES ICI';
  }

  @override
  String get neg_title => 'NÉGOCIATION';

  @override
  String get neg_client_initial => 'DEMANDE INITIALE (SANS PRIX)';

  @override
  String get neg_client_counter => 'CONTRE-OFFRE DU CLIENT';

  @override
  String get neg_driver_last => 'VOTRE DERNIÈRE OFFRE';

  @override
  String get neg_input_label => 'VOTRE PROPOSITION (\$)';

  @override
  String get neg_btn_accept => 'ACCEPTER';

  @override
  String get neg_btn_first => 'PREMIÈRE OFFRE';

  @override
  String get neg_btn_counter => 'NOUVELLE CONTRE-OFFRE';

  @override
  String get neg_btn_final => 'ENVOYER L\'OFFRE FINALE';

  @override
  String get neg_btn_reject => 'REJETER ET FERMER';

  @override
  String neg_impact_single(String miles) {
    return 'Cette commande représente un trajet total de $miles milles.';
  }

  @override
  String neg_impact_multi(String miles) {
    return 'Ajouter cette commande ajoute $miles milles supplémentaires à votre itinéraire.';
  }

  @override
  String get create_order_title => 'CRÉER LA COMMANDE';

  @override
  String get create_order_service_label => 'Type de service disponible';

  @override
  String get create_order_pickup_hint => 'Origine (Adresse exacte)';

  @override
  String get create_order_dropoff_hint => 'Destination (Adresse exacte)';

  @override
  String get create_order_details_hint => 'Détails du colis';

  @override
  String get create_order_pickup_label => '4. POINT DE RAMASSAGE';

  @override
  String get create_order_dropoff_label => '5. POINT DE LIVRAISON';

  @override
  String get create_order_description_label => '3. DESCRIPTION DU COLIS';

  @override
  String get create_order_btn_send => 'ENVOYER LA COMMANDE';

  @override
  String get create_order_success => '✅ COMMANDE ENVOYÉE';

  @override
  String get create_order_error_address => 'Adresse non valide.';

  @override
  String create_order_error_radius(String radius) {
    return 'La destination est hors du rayon autorisé ($radius mi).';
  }

  @override
  String get create_order_error_session => 'Session expirée.';

  @override
  String get create_order_required => 'Champ obligatoire';

  @override
  String create_order_geofence_error(String radius) {
    return '⚠️ HORS COUVERTURE : Ce Driver opère dans un rayon de $radius mi. Le ramassage et la livraison doivent être dans sa zone.';
  }

  @override
  String get create_order_sent_toast => '🚀 DEMANDE ENVOYÉE';

  @override
  String get create_order_client_default => 'Client';

  @override
  String get neg_client_details_title => 'DÉTAILS DE L\'OFFRE';

  @override
  String get neg_client_closing => 'Fermeture de la négociation...';

  @override
  String get neg_client_waiting => 'En attente d\'une offre...';

  @override
  String get neg_client_driver_assigned => 'DRIVER ASSIGNÉ';

  @override
  String get neg_client_order_details => 'DÉTAILS DE LA COMMANDE';

  @override
  String get neg_client_price_proposal => 'PROPOSITION DE PRIX';

  @override
  String get neg_client_price_final => 'OFFRE FINALE DU DRIVER';

  @override
  String get neg_client_btn_accept => 'ACCEPTER ET COMMANDER MAINTENANT';

  @override
  String get neg_client_btn_accept_final => 'ACCEPTER LA DERNIÈRE OFFRE';

  @override
  String get neg_client_btn_counter => 'FAIRE UNE CONTRE-OFFRE';

  @override
  String get neg_client_btn_reject_cancel => 'REJETER ET ANNULER';

  @override
  String get neg_client_dialog_title => 'VOTRE CONTRE-OFFRE';

  @override
  String get neg_client_dialog_body => 'Proposez un nouveau prix au driver :';

  @override
  String get neg_client_dialog_label => 'Nouveau prix';

  @override
  String get neg_client_dialog_btn_cancel => 'REJETER';

  @override
  String get neg_client_dialog_btn_send => 'ENVOYER';

  @override
  String get auth_sync_security => 'Synchronisation de la sécurité...';

  @override
  String get auth_sync_timeout =>
      'Si c\'est trop long, appuyez sur le bouton ci-dessous.';

  @override
  String get auth_cancel_retry => 'Annuler et réessayer';

  @override
  String get auth_login_welcome => 'Bienvenue de retour, soldat !';

  @override
  String get auth_login_email => 'Email';

  @override
  String get auth_login_password => 'Mot de passe';

  @override
  String get auth_login_btn => 'Se connecter';

  @override
  String get auth_login_not_member => 'Pas encore membre ?';

  @override
  String get auth_login_register_now => 'Inscrivez-vous maintenant';

  @override
  String get auth_register_title => 'Créez un compte pour commencer !';

  @override
  String get auth_register_name => 'Nom complet';

  @override
  String get auth_register_confirm_pass => 'Confirmer le mot de passe';

  @override
  String get auth_register_btn => 'S\'INSCRIRE';

  @override
  String get auth_register_already_member => 'Déjà membre ?';

  @override
  String get auth_register_login_now => 'Connectez-vous maintenant';

  @override
  String get auth_error_fields => 'Veuillez remplir tous les champs.';

  @override
  String get auth_error_pass_match => 'Les mots de passe ne correspondent pas';

  @override
  String get auth_error_name => 'Entrez votre nom complet';

  @override
  String get auth_role_title => 'Bienvenue chez LAD !';

  @override
  String get auth_role_subtitle =>
      'Choisissez comment vous souhaitez utiliser la plateforme :';

  @override
  String get auth_role_client => 'JE SUIS CLIENT';

  @override
  String get auth_role_messenger => 'JE SUIS COURSIER';

  @override
  String get auth_role_preparing => 'Préparation de votre compte...';

  @override
  String get service_location_disabled =>
      'Les services de localisation sont désactivés.';

  @override
  String get service_location_denied =>
      'Les autorisations de localisation ont été refusées.';

  @override
  String get service_location_denied_forever =>
      'Les autorisations de localisation sont définitivement refusées.';

  @override
  String get service_invitation_error_user =>
      'Erreur : L\'utilisateur n\'a pas pu être identifié.';

  @override
  String service_invitation_share_msg(String link) {
    return 'Salut ! 👋 Je t\'invite à rejoindre mon réseau personnel sur LAD Courier. C\'est le moyen le plus rapide et le plus sûr de gérer tes envois avec moi. Inscris-toi ici : $link';
  }

  @override
  String get service_invitation_subject =>
      '🚚 Rejoins mon réseau de coursiers sur LAD !';

  @override
  String service_recommend_share_msg(String name, String link) {
    return '🚀 Salut ! Je te recommande $name pour tes livraisons. C\'est mon coursier de confiance sur LAD COURIER. Tu peux le contacter en téléchargeant l\'appli ici : $link';
  }

  @override
  String get service_recommend_subject =>
      'Je te recommande mon coursier sur LAD Courier';

  @override
  String auth_error_role_save(String error) {
    return 'Erreur lors de l\'enregistrement du rôle : $error';
  }

  @override
  String get order_error_deleted => 'La commande a été supprimée.';

  @override
  String get order_status_active_msg => 'COMMANDE ACTIVE';

  @override
  String get order_status_timeout_msg => 'Délai expiré (30 min).';

  @override
  String get order_status_timeout_full_msg =>
      'En raison du grand nombre de commandes, le chauffeur n\'a pas pu s\'en occuper à temps. Veuillez l\'envoyer à un autre chauffeur disponible. Merci !';

  @override
  String auth_error_generic(String message) {
    return 'Erreur de sécurité : $message';
  }

  @override
  String get deliver_label => 'LIVRER';

  @override
  String get pickup_label => 'RAMASSER';

  @override
  String get notification_new_order_title => '🚀 NOUVELLE MISSION DÉTECTÉE !';

  @override
  String get notification_new_order_body =>
      'Vous avez une nouvelle demande sur le radar.';

  @override
  String get driver_work_zone_title => 'CARTE DES OPÉRATIONS';

  @override
  String get driver_work_zone_pending_requests => 'DEMANDES EN ATTENTE';

  @override
  String get driver_work_zone_waiting => 'En attente de nouvelles missions...';

  @override
  String get dashboard_btn_create_order => 'Créer une commande';

  @override
  String get client_label => 'Client';

  @override
  String get counter_offer_label => 'CONTRE-OFFRE';

  @override
  String get new_order_label => 'NOUVELLE COMMANDE';

  @override
  String get create_order_requirements => 'EXIGENCES';

  @override
  String get create_order_section_messenger => '6. SÉLECTIONNEZ VOTRE COURSIER';

  @override
  String get create_order_search_available => 'Tout Driver';

  @override
  String get create_order_add_photo => '2. PHOTO OU REÇU';

  @override
  String get create_order_service_type => '1. CHOISIR LE SERVICE';

  @override
  String get create_order_btn_search_drivers =>
      'Rechercher des drivers disponibles';

  @override
  String get order_details_product_photo => 'PHOTO PRODUIT';

  @override
  String get order_details_save_photo => 'SAUVEGARDER RÉFÉRENCE';

  @override
  String get order_details_photo_saved => 'Photo sauvegardée dans la galerie';

  @override
  String get order_details_photo_error =>
      'Erreur lors de la sauvegarde de la photo';

  @override
  String get create_order_shopping_nav_btn => 'SHOPPING NAVIGATOR (MAGASIN)';

  @override
  String get create_order_shopping_nav_success =>
      '✅ MAGASIN CAPTURÉ AVEC SUCCÈS';

  @override
  String get shopping_nav_capture => 'CAPTURER';

  @override
  String get shopping_nav_title => 'SHOPPING NAVIGATOR';

  @override
  String get catalog_title => 'SHOPPING NAVIGATOR';

  @override
  String get catalog_no_stores =>
      'AUCUN MAGASIN À PROXIMITÉ DANS LE RAYON DU COURSIER';

  @override
  String get shopping_nav_capturing => 'Téléchargement des preuves...';

  @override
  String get shopping_nav_error_photo =>
      '⚠️ Photo du reçu obligatoire pour continuer';

  @override
  String get shopping_nav_success_full =>
      '✅ Magasin et reçu capturés avec succès';

  @override
  String get sub_plan_lite_title => 'ZONE LITE';

  @override
  String get sub_plan_lite_desc => 'Idéal pour les livraisons locales rapides.';

  @override
  String get sub_plan_standart_title => 'ZONE STANDARD';

  @override
  String get sub_plan_standart_desc =>
      'Couvre toute votre ville et ses environs.';

  @override
  String get sub_plan_pro_title => 'ZONE PRO';

  @override
  String get sub_plan_pro_desc => 'Portée maximale pour les longs trajets.';

  @override
  String sub_price_per_month(String price) {
    return '$price / mois';
  }

  @override
  String get catalog_cat_all => 'TOUT';

  @override
  String get catalog_cat_food => 'GASTRO';

  @override
  String get catalog_cat_fashion => 'MODE';

  @override
  String get catalog_cat_auto => 'MOTEUR';

  @override
  String get catalog_cat_health => 'SANTÉ';

  @override
  String get catalog_cat_grocery => 'MARCHÉS';

  @override
  String get catalog_cat_home => 'MAISON';

  @override
  String get catalog_cat_tech => 'TECH';

  @override
  String get catalog_radius => 'Rayon de recherche';

  @override
  String get catalog_select_cat => 'Veuillez sélectionner une catégorie';

  @override
  String get catalog_no_results => 'Aucun résultat pour cette catégorie';

  @override
  String get catalog_no_results_area => 'AUCUN RÉSULTAT DANS CETTE ZONE';

  @override
  String get shopping_nav_instruction_title => 'Instructions d\'achat';

  @override
  String get shopping_nav_instruction_body =>
      'Naviguez, effectuez votre achat, et dès que vous voyez le reçu final, appuyez sur CAPTURER.';

  @override
  String get catalog_no_results_detail =>
      'Essayez de changer de catégorie ou vérifiez que le Driver a un rayon d\'action.';

  @override
  String get catalog_default_name => 'Local';

  @override
  String get driver_service_courier => 'Messagerie et colis';

  @override
  String get driver_service_logistics => 'Logistique spécialisée';

  @override
  String get driver_service_shopping => 'Achats et courses';

  @override
  String get shopping_nav_instruction_title_alt => '💡 PLAN DE SECOURS';

  @override
  String get shopping_nav_instruction_body_alt =>
      'Si l\'établissement vous oblige à utiliser son application officielle, passez votre commande là-bas, prenez une capture d\'écran du reçu et téléchargez-la ici.';

  @override
  String get client_dash_order_here => 'COMMANDEZ ICI';

  @override
  String get prof_btn_business_card => 'MA CARTE DE VISITE';

  @override
  String get business_card_title => 'CARTE DE VISITE LAD COURIER';

  @override
  String get business_card_scan_msg =>
      'Scannez pour télécharger LAD et vous lier à mon réseau';

  @override
  String get common_delete_account => 'SUPPRIMER MON COMPTE';

  @override
  String get delete_account_confirm_title =>
      'SUPPRIMER LE COMPTE DÉFINITIVEMENT ?';

  @override
  String get delete_account_confirm_body =>
      'Cette action supprimera toutes vos données, historique et connexions. Elle ne peut pas être annulée.';

  @override
  String get delete_account_btn_confirm => 'OUI, TOUT SUPPRIMER';

  @override
  String get delete_account_reauth_required =>
      'Par sécurité, vous devez vous reconnecter avant de supprimer votre compte.';

  @override
  String get common_payment_required_title => 'PAIEMENT REQUIS';

  @override
  String get common_payment_required_msg =>
      'Pour garantir la sécurité de vos commandes, vous devez lier un mode de paiement dans votre profil.';

  @override
  String get driver_inactivity_title => 'MODE REPOS';

  @override
  String get driver_inactivity_msg =>
      'Votre disponibilité a été automatiquement fermée car vous avez été inactif pendant plus de 4 heures. Si vous êtes prêt à travailler, veuillez vous remettre en ligne.';

  @override
  String get common_logout => 'DÉCONNEXION';

  @override
  String get common_logout_confirm =>
      'Êtes-vous sûr de vouloir vous déconnecter ? Vous devrez saisir à nouveau votre e-mail et votre mot de passe pour rafraîchir la sécurité.';

  @override
  String get common_exit => 'QUITTER';

  @override
  String get common_continue => 'CONTINUER';

  @override
  String get auth_verification_required_title => '🛡️ VÉRIFICATION OBLIGATOIRE';

  @override
  String get auth_verification_required_body =>
      'Par sécurité, vous devez valider votre identité avec un selfie et votre empreinte digitale pour commencer à travailler.';

  @override
  String get client_dash_negotiations_title => 'NÉGOCIATIONS';

  @override
  String get client_dash_no_negotiations => 'Aucune négociation en cours';

  @override
  String get client_dash_no_active_missions => 'Aucune mission active';

  @override
  String get client_dash_order_active => 'COMMANDE ACTIVE';

  @override
  String client_dash_driver_resting_body(String name) {
    return 'LE DRIVER $name NE REÇOIT PAS DE COMMANDES POUR LE MOMENT. VOULEZ-VOUS CHERCHER UN AUTRE DRIVER DISPONIBLE ?';
  }

  @override
  String get client_dash_invite_code_label =>
      'ENTREZ LE CODE DE LIAISON DU DRIVER :';
}
