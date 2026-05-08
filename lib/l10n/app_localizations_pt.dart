// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get earnings_title => 'ZONAS DE TRABALHO';

  @override
  String get earnings_period_today => 'Hoje';

  @override
  String get earnings_period_week => 'Esta Semana';

  @override
  String get earnings_period_month => 'Mês Atual';

  @override
  String get earnings_period_year => 'Ano Fiscal';

  @override
  String get earnings_stat_gross => 'RECEITA BRUTA';

  @override
  String get earnings_stat_miles => 'MILHAS FISCAIS';

  @override
  String get earnings_stat_missions => 'MISSÕES';

  @override
  String get earnings_stat_efficiency => 'EFETIVIDADE';

  @override
  String get earnings_history_title => 'HISTÓRICO DE MISSÕES';

  @override
  String get earnings_empty_history => 'Sem missões neste período.';

  @override
  String get earnings_network_title => 'MEU RAIO DE AÇÃO';

  @override
  String get earnings_linked_users => 'USUÁRIOS VINCULADOS';

  @override
  String get earnings_referrals_count => 'Indicações';

  @override
  String get earnings_plan_label => 'ZONA SELECIONADA';

  @override
  String get earnings_refund_title => 'ESTADO DA ZONA';

  @override
  String get earnings_refund_covered => 'ATIVA';

  @override
  String get earnings_refund_saving => 'GRÁTIS';

  @override
  String get earnings_refund_status_free_current => 'ZONA SEM CUSTO';

  @override
  String get earnings_refund_status_free_next => 'ALTERAÇÃO DISPONÍVEL';

  @override
  String get earnings_refund_goal_msg =>
      'Configure seu raio de alcance livremente.';

  @override
  String get earnings_refund_success_msg => 'Zona configurada corretamente.';

  @override
  String get earnings_refund_pending_msg => 'Configuração em andamento...';

  @override
  String get earnings_refund_anti_fraud_rule =>
      'A mudança de zona é instantânea e sem custo.';

  @override
  String get earnings_refund_disclaimer =>
      'LAD Courier não cobra mensalidade. Apenas uma taxa de serviço de \$ 0,50 por pedido bem-sucedido, independentemente do preço acordado.';

  @override
  String get driver_dash_title => 'CENTRO DE COMANDO DRIVER';

  @override
  String get driver_status_online => 'DRIVER ONLINE';

  @override
  String get driver_status_offline => 'FORA DE SERVIÇO';

  @override
  String get driver_btn_work_zone => 'MAPA OPERACIONAL';

  @override
  String get driver_menu_services => 'SERVIÇOS';

  @override
  String get driver_menu_profile => 'MEU PERFIL';

  @override
  String get driver_menu_earnings => 'ZONAS';

  @override
  String get driver_menu_invite => 'CONVIDAR';

  @override
  String get driver_dialog_services_title => 'SERVIÇOS ATIVOS';

  @override
  String get driver_btn_confirm => 'CONFIRMAR';

  @override
  String get driver_error_no_photo => 'FALTA FOTO DE PERFIL';

  @override
  String get driver_error_no_photo_msg =>
      'Você deve enviar uma foto profissional para que seus clientes possam identificá-lo.';

  @override
  String get driver_error_incomplete_data => 'DADOS INCOMPLETOS';

  @override
  String get driver_error_incomplete_data_msg =>
      'Seu nome e telefone são obrigatórios para la segurança do serviço.';

  @override
  String get driver_error_no_vehicle => 'DETALHES DO VEÍCULO';

  @override
  String get driver_error_no_vehicle_msg =>
      'Descreva seu meio de transporte na seção Meu Perfil.';

  @override
  String get driver_error_no_membership => 'ZONA NÃO SELECIONADA';

  @override
  String get driver_error_no_membership_msg =>
      'Você deve selecionar uma \'Zona de Trabalho\' (Lite, Standard ou Pro) para receber pedidos.';

  @override
  String get driver_error_no_stripe => 'STRIPE NÃO VINCULADO';

  @override
  String get driver_error_no_stripe_msg =>
      'Para ficar online, você deve configurar sua conta Stripe Connect em \'Meu Perfil\'.';

  @override
  String get driver_error_no_verification => 'VERIFICAÇÃO PENDENTE';

  @override
  String get driver_error_no_verification_msg =>
      'Você deve completar sua verificação de identidade e background check para ficar online.';

  @override
  String get driver_error_no_services => 'SEM SERVIÇOS ATIVOS';

  @override
  String get driver_error_no_services_msg =>
      'Selecione pelo menos um serviço antes de ficar online.';

  @override
  String get driver_active_missions_alert =>
      '⚠️ VOCÊ TEM MISSÕES ATIVAS. Termine-as primeiro.';

  @override
  String get driver_btn_understand => 'ENTENDIDO';

  @override
  String get driver_selection_title => 'Escolher Motorista';

  @override
  String get driver_card_plan => 'Zona';

  @override
  String get driver_card_coverage => 'Cobertura';

  @override
  String get driver_selection_no_drivers_title => 'Sinto muito';

  @override
  String get driver_selection_no_drivers_body =>
      'Não há motoristas disponíveis cujo raio de trabalho cubra esses endereços. Tente um trajeto mais curto.';

  @override
  String get notification_order_sent_success => 'Missão enviada ao motorista';

  @override
  String get prof_title => 'MEU PERFIL OPERACIONAL';

  @override
  String get prof_radar_title => 'MEU RADAR DE RECRUTAMENTO';

  @override
  String get prof_radar_body =>
      'Seus clientes escaneiam este QR para vincular-se à sua rede pessoal.';

  @override
  String get prof_section_id => 'DADOS DE IDENTIFICAÇÃO';

  @override
  String get prof_label_name => 'Nome Completo';

  @override
  String get prof_label_phone => 'Telefone de Contato';

  @override
  String get prof_label_vehicle => 'Descrição do Veículo';

  @override
  String get prof_section_mem => 'ZONAS DE TRABALHO';

  @override
  String get prof_section_pay => 'FERRAMENTAS DE PAGAMENTO (STRIPE)';

  @override
  String get prof_pay_stripe => 'Vincular Stripe Connect';

  @override
  String get prof_pay_stripe_sub =>
      'Para receber seus pagamentos instantaneamente';

  @override
  String get prof_pay_paypal => 'PayPal (Opcional)';

  @override
  String get prof_pay_paypal_sub => 'Apenas para cobranças manuais';

  @override
  String get prof_btn_save => 'SALVAR ALTERAÇÕES';

  @override
  String get prof_btn_switch => 'MUDAR PARA MODO CLIENTE';

  @override
  String get work_title => 'MAPA DE OPERAÇÕES';

  @override
  String get work_panel_title => 'SOLICITAÇÕES PENDENTES';

  @override
  String get work_waiting => 'Aguardando novas missões...';

  @override
  String get work_alert_title => '🚀 NOVA MISSÃO DETECTADA!';

  @override
  String get work_alert_body => 'Você tem uma nova solicitação no radar.';

  @override
  String get work_notif_channel_name => 'Alertas de Pedidos Urgentes';

  @override
  String get work_notif_channel_desc =>
      'Canal para notificações de novas missões';

  @override
  String get sub_title => 'ZONAS DE TRABALHO';

  @override
  String get sub_promo => 'ELABORE SUA PRÓPRIA ROTA LIVREMENTE';

  @override
  String get sub_free => 'GRÁTIS';

  @override
  String sub_radius(String radius) {
    return 'Alcance: $radius';
  }

  @override
  String sub_bonus(String bonus) {
    return 'Custo: $bonus';
  }

  @override
  String get sub_btn_activate => 'ATIVAR ZONA';

  @override
  String get welcome_title => 'Bem-vindo a Bordo!';

  @override
  String get welcome_body =>
      'Para finalizar seu registro, por favor, escolha seu papel em nossa comunidade.';

  @override
  String get welcome_btn_client => 'Sou Cliente';

  @override
  String get welcome_btn_driver => 'Sou Mensageiro';

  @override
  String get client_dash_title => 'CENTRO DE COMANDO CLIENTE';

  @override
  String get client_dash_welcome => 'SISTEMA LAD COURIER';

  @override
  String get client_dash_requested_services => 'SERVIÇOS SOLICITADOS';

  @override
  String get client_dash_no_requests => 'Sem solicitações pendentes.';

  @override
  String get client_dash_new_request => 'NOVA SOLICITAÇÃO';

  @override
  String get client_dash_first_offer => 'PRIMEIRA OFERTA RECIBIDA';

  @override
  String get client_dash_counter_offer => 'CONTRAOFERTA RECIBIDA';

  @override
  String client_dash_driver_label(String name) {
    return 'Driver: $name';
  }

  @override
  String get client_dash_active_missions => 'MISSÕES EM CURSO';

  @override
  String client_dash_price_label(String price) {
    return 'PREÇO: $price';
  }

  @override
  String client_dash_status_label(String status) {
    return 'Status: $status';
  }

  @override
  String get client_dash_linked_drivers => 'LISTA DE DRIVERS';

  @override
  String get client_dash_no_linked_drivers =>
      'Você não tem drivers vinculados.';

  @override
  String get client_dash_driver_available => 'DISPONÍVEL';

  @override
  String get client_dash_driver_resting => 'EM DESCANSO';

  @override
  String client_dash_services_label(String services) {
    return 'SERVIÇOS: $services';
  }

  @override
  String client_dash_plan_label(String plan) {
    return 'ZONA: $plan';
  }

  @override
  String client_dash_radius_label(String radius) {
    return 'RAIO: $radius';
  }

  @override
  String get client_dash_no_phone => 'Sem Tel';

  @override
  String get client_dash_unlink_title => 'DESVINCULAR DRIVER';

  @override
  String client_dash_unlink_confirm(String name) {
    return 'Tem certeza que deseja remover $name da sua lista de confiança?';
  }

  @override
  String get client_dash_unlink_button => 'DESVINCULAR';

  @override
  String get client_dash_unlink_success => 'Driver desvinculado com sucesso';

  @override
  String get client_dash_invite_title => 'VINCULAR DRIVER';

  @override
  String get client_dash_invite_hint => 'Código ou ID do Driver';

  @override
  String get common_confirm => 'CONFIRMAR';

  @override
  String get common_cancel => 'CANCELAR';

  @override
  String get client_prof_title => 'MEU PERFIL CLIENTE';

  @override
  String get client_prof_contact_details => 'DADOS DE CONTATO';

  @override
  String get client_prof_name_label => 'Nome Completo';

  @override
  String get client_prof_phone_label => 'Telefone';

  @override
  String get client_prof_address_label => 'Endereço Principal';

  @override
  String get client_prof_payment_methods => 'MÉTODOS DE PAGAMENTO';

  @override
  String get client_prof_stripe_title => 'Stripe';

  @override
  String get client_prof_stripe_subtitle => 'Cartão de Crédito/Débito';

  @override
  String get client_prof_paypal_title => 'PayPal';

  @override
  String get client_prof_paypal_subtitle => 'Conta Digital';

  @override
  String get client_prof_cta_title => '¡GANHE DINHEIRO COMO DRIVER!';

  @override
  String get client_prof_cta_body =>
      'Junte-se à nossa rede de mensageiros e gere renda no seu tempo livre.';

  @override
  String get client_prof_cta_button => 'VER ZONAS DRIVER';

  @override
  String get client_prof_save_button => 'SALVAR ALTERAÇÕES';

  @override
  String get client_prof_switch_button => 'MUDAR PARA MODO DRIVER';

  @override
  String get client_prof_update_success => 'Perfil atualizado';

  @override
  String client_prof_update_error(String error) {
    return 'Erro ao atualizar: $error';
  }

  @override
  String get client_prof_completed_orders => 'PEDIDOS CONCLUÍDOS';

  @override
  String get client_dash_history_title => 'HISTÓRICO DE MISSÕES (36H)';

  @override
  String order_details_title(String type, int index) {
    return 'ORDEM $type #$index';
  }

  @override
  String order_details_id(String id) {
    return 'ID Ordem: $id';
  }

  @override
  String get order_details_pickup => 'PONTO DE COLETA';

  @override
  String get order_details_delivery => 'PONTO DE ENTREGA';

  @override
  String get order_details_instructions => 'INSTRUÇÕES DA MISSÃO';

  @override
  String get order_details_no_instructions =>
      'Sem instruções específicas do cliente.';

  @override
  String get order_details_proximity_on => 'VOCÊ ESTÁ NO LOCAL!';

  @override
  String get order_details_proximity_off => 'DISTÂNCIA AO PONTO';

  @override
  String order_details_meters(String meters) {
    return '$meters metros';
  }

  @override
  String get order_details_btn_go_pickup => 'IR PARA COLETA';

  @override
  String get order_details_btn_arrived => 'CHEGUEI / COLETADO';

  @override
  String get order_details_btn_go_delivery => 'IR PARA ENTREGA';

  @override
  String get order_details_btn_photo => 'TIRAR FOTO COMPROVANTE';

  @override
  String get order_details_btn_finish => 'FINALIZAR MISSÃO';

  @override
  String get order_details_photo_success => 'Foto capturada';

  @override
  String get order_details_evidence_msg =>
      'Evidência salva com coordenadas GPS';

  @override
  String get order_details_btn_view_proof => 'VER COMPROVANTE DE ENTREGA';

  @override
  String order_details_multiple_warning(int count) {
    return 'VOCÊ TEM $count ORDENS A MAIS AQUI';
  }

  @override
  String get neg_title => 'NEGOCIAÇÃO';

  @override
  String get neg_client_initial => 'SOLICITAÇÃO INICIAL (SEM PREÇO)';

  @override
  String get neg_client_counter => 'CONTRAOFERTA DO CLIENTE';

  @override
  String get neg_driver_last => 'SUA ÚLTIMA OFERTA';

  @override
  String get neg_input_label => 'SUA PROPOSTA (\$)';

  @override
  String get neg_btn_accept => 'ACEITAR';

  @override
  String get neg_btn_first => 'PRIMEIRA OFERTA';

  @override
  String get neg_btn_counter => 'NOVA CONTRAOFERTA';

  @override
  String get neg_btn_final => 'ENVIAR OFERTA FINAL';

  @override
  String get neg_btn_reject => 'REJEITAR E FECHAR';

  @override
  String neg_impact_single(String miles) {
    return 'Esta ordem representa uma viagem total de $miles milhas.';
  }

  @override
  String neg_impact_multi(String miles) {
    return 'Somar esta ordem adiciona $miles milhas extras à sua rota.';
  }

  @override
  String get create_order_title => 'CRIAR A ORDEM';

  @override
  String get create_order_service_label => 'Tipo de serviço disponível';

  @override
  String get create_order_pickup_hint => 'Origem (Endereço exato)';

  @override
  String get create_order_dropoff_hint => 'Destino (Endereço exato)';

  @override
  String get create_order_details_hint => 'Detalhes do pacote';

  @override
  String get create_order_pickup_label => '4. PONTO DE RECOLHA';

  @override
  String get create_order_dropoff_label => '5. PONTO DE ENTREGA';

  @override
  String get create_order_description_label => '3. DESCRIÇÃO DO PACOTE';

  @override
  String get create_order_btn_send => 'ENVIAR ORDEM';

  @override
  String get create_order_success => '✅ ORDEM ENVIADA';

  @override
  String get create_order_error_address => 'Endereço inválido.';

  @override
  String create_order_error_radius(String radius) {
    return 'O destino está fora do raio permitido ($radius mi).';
  }

  @override
  String get create_order_error_session => 'Sessão expirada.';

  @override
  String get create_order_required => 'Campo obrigatório';

  @override
  String create_order_geofence_error(String radius) {
    return '⚠️ FORA DE COBERTURA: Este Driver opera em um raio de $radius mi. A coleta e a entrega devem estar na sua zona.';
  }

  @override
  String get create_order_sent_toast => '🚀 SOLICITAÇÃO ENVIADA';

  @override
  String get create_order_client_default => 'Cliente';

  @override
  String get neg_client_details_title => 'DETALHES DA OFERTA';

  @override
  String get neg_client_closing => 'Fechando negociação...';

  @override
  String get neg_client_waiting => 'Aguardando oferta...';

  @override
  String get neg_client_driver_assigned => 'DRIVER ASIGNADO';

  @override
  String get neg_client_order_details => 'DETALHES DA ORDEM';

  @override
  String get neg_client_price_proposal => 'PROPOSTA DE PREÇO';

  @override
  String get neg_client_price_final => 'OFERTA FINAL DO DRIVER';

  @override
  String get neg_client_btn_accept => 'ACEITAR E PEDIR AGORA';

  @override
  String get neg_client_btn_accept_final => 'ACEITAR ÚLTIMA OFERTA';

  @override
  String get neg_client_btn_counter => 'FAZER CONTRAOFERTA';

  @override
  String get neg_client_btn_reject_cancel => 'REJEITAR E CANCELAR';

  @override
  String get neg_client_dialog_title => 'SUA CONTRAOFERTA';

  @override
  String get neg_client_dialog_body => 'Proponha um novo preço ao driver:';

  @override
  String get neg_client_dialog_label => 'Novo preço';

  @override
  String get neg_client_dialog_btn_cancel => 'REJEITAR';

  @override
  String get neg_client_dialog_btn_send => 'ENVIAR';

  @override
  String get auth_sync_security => 'Sincronização de segurança...';

  @override
  String get auth_sync_timeout => 'Se demorar muito, pressione o botão abaixo.';

  @override
  String get auth_cancel_retry => 'Cancelar e tentar novamente';

  @override
  String get auth_login_welcome => 'Bem-vindo de volta, soldado!';

  @override
  String get auth_login_email => 'Email';

  @override
  String get auth_login_password => 'Senha';

  @override
  String get auth_login_btn => 'Iniciar Sessão';

  @override
  String get auth_login_not_member => 'Não é membro?';

  @override
  String get auth_login_register_now => 'Registre-se agora';

  @override
  String get auth_register_title => 'Crie uma conta para começar!';

  @override
  String get auth_register_name => 'Nome completo';

  @override
  String get auth_register_confirm_pass => 'Confirmar senha';

  @override
  String get auth_register_btn => 'REGISTRAR-SE';

  @override
  String get auth_register_already_member => 'Já é membro?';

  @override
  String get auth_register_login_now => 'Inicie sessão agora';

  @override
  String get auth_error_fields => 'Por favor, preencha todos os campos.';

  @override
  String get auth_error_pass_match => 'As senhas não coincidem';

  @override
  String get auth_error_name => 'Insira seu nome completo';

  @override
  String get auth_role_title => 'Bem-vindo à LAD!';

  @override
  String get auth_role_subtitle => 'Escolha como você quer usar la plataforma:';

  @override
  String get auth_role_client => 'SOU CLIENTE';

  @override
  String get auth_role_messenger => 'SOU MENSAGEIRO';

  @override
  String get auth_role_preparing => 'Preparando sua conta...';

  @override
  String get service_location_disabled =>
      'Os serviços de localização estão desativados.';

  @override
  String get service_location_denied =>
      'As permissões de localização foram negadas.';

  @override
  String get service_location_denied_forever =>
      'As permissões de localização estão permanentemente negadas.';

  @override
  String get service_invitation_error_user =>
      'Erro: O usuário não pôde ser identificado.';

  @override
  String service_invitation_share_msg(String link) {
    return 'Olá! 👋 Convido você a se juntar à minha rede pessoal na LAD Courier. É a forma mais rápida e segura de gerenciar seus envios comigo. Registre-se aqui: $link';
  }

  @override
  String get service_invitation_subject =>
      '🚚 Junte-se à minha rede de mensageiros na LAD!';

  @override
  String service_recommend_share_msg(String name, String link) {
    return '🚀 Olá! Recomendo o $name para suas entregas. É meu mensageiro de confiança na LAD COURIER. Você pode contatá-lo baixando o app aqui: $link';
  }

  @override
  String get service_recommend_subject =>
      'Recomendo meu mensageiro na LAD Courier';

  @override
  String auth_error_role_save(String error) {
    return 'Erro ao salvar o papel: $error';
  }

  @override
  String get order_error_deleted => 'A ordem foi eliminada.';

  @override
  String get order_status_active_msg => 'ORDEM ATIVA';

  @override
  String get order_status_timeout_msg => 'Tempo esgotado (30 min).';

  @override
  String get order_status_timeout_full_msg =>
      'Devido à grande quantidade de ordens, o driver não pôde atendê-la a tempo. Por favor, envie-a a outro driver disponível. Obrigado!';

  @override
  String auth_error_generic(String message) {
    return 'Erro de segurança: $message';
  }

  @override
  String get deliver_label => 'ENTREGAR';

  @override
  String get pickup_label => 'RECOLHER';

  @override
  String get notification_new_order_title => '🚀 ¡NUEVA MISIÓN DETECTADA!';

  @override
  String get notification_new_order_body =>
      'Você tem uma nova solicitação no radar.';

  @override
  String get driver_work_zone_title => 'MAPA DE OPERAÇÕES';

  @override
  String get driver_work_zone_pending_requests => 'SOLICITAÇÕES PENDENTES';

  @override
  String get driver_work_zone_waiting => 'Aguardando novas missões...';

  @override
  String get dashboard_btn_create_order => 'Criar Ordem';

  @override
  String get client_label => 'Cliente';

  @override
  String get counter_offer_label => 'CONTRAOFERTA';

  @override
  String get new_order_label => 'NOVA ORDEM';

  @override
  String get create_order_requirements => 'REQUISITOS';

  @override
  String get create_order_section_messenger => '6. SELECIONE SEU DRIVER';

  @override
  String get create_order_search_available => 'Qualquer Driver';

  @override
  String get create_order_add_photo => '2. FOTO OU RECIBO';

  @override
  String get create_order_service_type => '1. ESCOLHER SERVIÇO';

  @override
  String get create_order_btn_search_drivers => 'Buscar drivers disponíveis';

  @override
  String get order_details_product_photo => 'FOTO PRODUTO';

  @override
  String get order_details_save_photo => 'GUARDAR REFERÊNCIA';

  @override
  String get order_details_photo_saved => 'Foto salva na galeria';

  @override
  String get order_details_photo_error => 'Erro ao salvar a foto';

  @override
  String get create_order_shopping_nav_btn => 'SHOPPING NAVIGATOR (LOJA)';

  @override
  String get create_order_shopping_nav_success =>
      '✅ LOJA CAPTURADA COM SUCESSO';

  @override
  String get shopping_nav_capture => 'CAPTURAR';

  @override
  String get shopping_nav_title => 'SHOPPING NAVIGATOR';

  @override
  String get catalog_title => 'SHOPPING NAVIGATOR';

  @override
  String get catalog_no_stores => 'SEM LOJAS PRÓXIMAS NO RAIO DO MENSAGEIRO';

  @override
  String get shopping_nav_capturing => 'Subindo evidências...';

  @override
  String get shopping_nav_error_photo =>
      '⚠️ Foto do recibo obrigatória para continuar';

  @override
  String get shopping_nav_success_full =>
      '✅ Loja e recibo capturados com sucesso';

  @override
  String get sub_plan_lite_title => 'ZONA LITE';

  @override
  String get sub_plan_lite_desc => 'Ideal para entregas locais rápidas.';

  @override
  String get sub_plan_standart_title => 'ZONA STANDARD';

  @override
  String get sub_plan_standart_desc => 'Cobre toda a sua cidade e arredores.';

  @override
  String get sub_plan_pro_title => 'ZONA PRO';

  @override
  String get sub_plan_pro_desc => 'Alcance máximo para fretes longos.';

  @override
  String sub_price_per_month(String price) {
    return '$price / mês';
  }

  @override
  String get catalog_cat_all => 'TUDO';

  @override
  String get catalog_cat_food => 'GASTRO';

  @override
  String get catalog_cat_fashion => 'MODA';

  @override
  String get catalog_cat_auto => 'MOTOR';

  @override
  String get catalog_cat_health => 'SAÚDE';

  @override
  String get catalog_cat_grocery => 'MERCADOS';

  @override
  String get catalog_cat_home => 'HOGAR';

  @override
  String get catalog_cat_tech => 'TECH';

  @override
  String get catalog_radius => 'Raio de Busca';

  @override
  String get catalog_select_cat => 'Selecione uma categoria';

  @override
  String get catalog_no_results => 'Sem resultados nesta categoria';

  @override
  String get catalog_no_results_area => 'SEM RESULTADOS NESTA ÁREA';

  @override
  String get shopping_nav_instruction_title => 'Instruções de Compra';

  @override
  String get shopping_nav_instruction_body =>
      'Navegue, realize sua compra e quando vir o recibo final, clique em CAPTURAR.';

  @override
  String get catalog_no_results_detail =>
      'Tente mudar de categoria ou verifique se o Driver tem raio de ação.';

  @override
  String get catalog_default_name => 'Loja';

  @override
  String get driver_service_courier => 'Mensageria e Pacotes';

  @override
  String get driver_service_logistics => 'Logística Especializada';

  @override
  String get driver_service_shopping => 'Compras e Recados';

  @override
  String get shopping_nav_instruction_title_alt => '💡 PLANO DE RESERVA';

  @override
  String get shopping_nav_instruction_body_alt =>
      'Se o local te obrigar a usar o App oficial dele, faça seu pedido lá, tire um screenshot do recibo e suba-o aqui.';

  @override
  String get client_dash_order_here => 'ORDENE AQUI';

  @override
  String get prof_btn_business_card => 'MEU CARTÃO DE NEGÓCIOS';

  @override
  String get business_card_title => 'CARTÃO DE NEGÓCIOS LAD COURIER';

  @override
  String get business_card_scan_msg =>
      'Escaneie para descarregar o LAD e vincular-se à minha rede';

  @override
  String get common_delete_account => 'ELIMINAR MINHA CONTA';

  @override
  String get delete_account_confirm_title => '¿ELIMINAR CONTA DEFINITIVAMENTE?';

  @override
  String get delete_account_confirm_body =>
      'Esta ação apagará todos os seus dados, histórico e conexões. Não pode ser desfeita.';

  @override
  String get delete_account_btn_confirm => 'SIM, ELIMINAR TUDO';

  @override
  String get delete_account_reauth_required =>
      'Por segurança, você deve iniciar sessão de novo antes de apagar sua conta.';

  @override
  String get common_payment_required_title => 'PAGAMENTO NECESSÁRIO';

  @override
  String get common_payment_required_msg =>
      'Para garantir a segurança dos seus pedidos, você deve vincular um método de pagamento no seu perfil.';

  @override
  String get driver_inactivity_title => 'MODO DESCANSO';

  @override
  String get driver_inactivity_msg =>
      'Sua disponibilidade foi fechada automaticamente porque você está inativo há mais de 4 horas. Se estiver pronto para trabalhar, fique online novamente.';

  @override
  String get common_logout => 'SAIR';

  @override
  String get common_logout_confirm =>
      'Tem certeza que deseja sair? Você precisará digitar seu e-mail e senha novamente para atualizar a segurança.';

  @override
  String get common_exit => 'SAIR';

  @override
  String get common_continue => 'CONTINUAR';

  @override
  String get auth_verification_required_title => '🛡️ VERIFICAÇÃO OBRIGATÓRIA';

  @override
  String get auth_verification_required_body =>
      'Por segurança, você deve validar sua identidade con uma selfie e sua impressão digital para começar a trabalhar.';

  @override
  String get client_dash_negotiations_title => 'NEGOCIAÇÕES';

  @override
  String get client_dash_no_negotiations => 'Sem negociações pendentes';

  @override
  String get client_dash_no_active_missions => 'Sem missões ativas';

  @override
  String get client_dash_order_active => 'ORDEM ATIVA';

  @override
  String client_dash_driver_resting_body(String name) {
    return 'O MOTORISTA $name NÃO ESTÁ RECEBENDO PEDIDOS NO MOMENTO. DESEJA PROCURAR OUTRO MOTORISTA DISPONÍVEL?';
  }

  @override
  String get client_dash_invite_code_label =>
      'INSIRA O CÓDIGO DE VINCULAÇÃO DO MOTORISTA:';
}
