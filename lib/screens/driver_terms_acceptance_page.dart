import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class DriverTermsAcceptancePage extends StatefulWidget {
  const DriverTermsAcceptancePage({super.key});

  @override
  State<DriverTermsAcceptancePage> createState() => _DriverTermsAcceptancePageState();
}

class _DriverTermsAcceptancePageState extends State<DriverTermsAcceptancePage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _acceptedCheckbox = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _getIPAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['ip'];
      }
    } catch (e) {
      developer.log("Error getting IP", error: e);
    }
    return "Unknown";
  }

  Future<void> _acceptTerms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final ip = await _getIPAddress();
      final now = Timestamp.now();
      const version = "2026-05-17"; 

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'acceptedTerms': true,
        'acceptedTermsDate': now,
        'acceptedTermsIP': ip,
        'acceptedTermsVersion': version,
        'subscriptionStatus': 'active',
        'trialEndDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'isEligibleForTrial': false, 
        'verificationStatus': 'ACEPTACIÓN_PENDIENTE',
      });

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("CONTRATO DE OPERADOR", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 16, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: const Text(
                    """ACUERDO DE LICENCIA DE SOFTWARE, TÉRMINOS DE USO Y DESCARGO DE RESPONSABILIDAD (DISCHARGE) – PLATAFORMA LAD COURIER
Operado por: LAD DIGITAL SYSTEMS LLC
Jurisdicción: Florida, USA
Última Actualización: 17 de mayo de 2026

Este documento constituye un contrato legal y vinculante entre LAD DIGITAL SYSTEMS LLC (en adelante, "La Compañía") y el usuario que se registra para operar como conductor (en adelante, "El Driver"). Al completar el registro y presionar "Aceptar", El Driver declara conocer, entender y aceptar la totalidad de las cláusulas aquí expuestas.

ARTÍCULO 1: NATURALEZA DE LA RELACIÓN Y SOBERANÍA COMERCIAL
1.1 Propiedad del Negocio: El Driver reconoce y acepta de forma expresa que es el único dueño, operador y responsable de su propio negocio independiente de transporte y mensajería.
1.2 Ausencia de Relación Laboral: Este acuerdo no crea una relación de empleo, agencia, franquicia, joint venture o sociedad entre La Compañía y El Driver. El Driver no es empleado de LAD DIGITAL SYSTEMS LLC. No tiene horario fijo, no recibe salario, ni exclusividad, y opera bajo su propio riesgo comercial.

ARTÍCULO 2: CONCESIÓN DE LICENCIA DE USO DE SOFTWARE Y DERECHO DE ADMISIÓN
2.1 Licencia Revocable: Al registrarse de forma exitosa, El Driver recibe una licencia de uso limitada, no exclusiva, intransferible y estrictamente revocable para utilizar la aplicación LAD COURIER como herramienta tecnológica de su negocio.
2.2 Retiro Discrecional de Licencia: LAD DIGITAL SYSTEMS LLC se reserva el derecho absoluto de admisión, denegación, suspensión temporal o revocación permanente de dicha licencia de uso en cualquier momento y por cualquier motivo a su sola discreción, sin necesidad de aviso previo ni derecho a compensación alguna, quedando inhabilitado el Driver para ponerse "Online".

ARTÍCULO 3: RESPONSABILIDAD TOTAL Y CUMPLIMIENTO LEGAL DEL DRIVER
El Driver es el único y exclusivo responsable de la operación legal y operativa de su negocio, obligándose a poseer, mantener vigentes y cumplir en todo momento con:
• Documentación Personal y Vehicular: Licencias de conducir vigentes, registros vehiculares, permisos comerciales y coberturas de seguros de auto comerciales o pólizas requeridas por las leyes correspondientes.
• Jurisdicción Local: Cumplir estrictamente con las normativas, ordenanzas y reglas de tránsito, conducta a seguir y directrices de cada municipio, ciudad, condado, estado o país donde decida ejecutar la aplicación.
• Protección del Producto: El Driver asume la responsabilidad total sobre la custodia, integridad, seguridad y correcta entrega de los paquetes, mercancías o productos que acepte mover. LAD DIGITAL SYSTEMS LLC queda totalmente descargada de cualquier reclamo por pérdida, robo o daño o destrucción de dichos bienes.

ARTÍCULO 4: MODELO FINANCIERO Y TARIFA DE SERVICIO (SERVICE FEE)
4.1 Costo por Orden Exitosa: LAD DIGITAL SYSTEMS LLC no cobra mensualidades dinámicas ni comisiones porcentuales sobre el valor total estipulado entre las partes. La Compañía cobrará una tarifa de servicio fija de \$0.50 USD (cincuenta centavos de dólar) por cada orden completada y marcada como exitosa en la plataforma.
4.2 Independencia del Costo del Envío: Esta tarifa se mantendrá fija independientemente del costo total del servicio negociado entre el Cliente y el Driver.
4.3 Modificación Discrecional: LAD DIGITAL SYSTEMS LLC se reserva el derecho explícito de modificar el monto de esta tarifa de servicio en el futuro a su sola discreción, notificando los cambios a través de la aplicación.

ARTÍCULO 5: PROCESAMIENTO DE PAGOS MEDIANTE STRIPE (KYC Y CONECTIVIDAD)
5.1 Pasarela Externa de Pago: El ecosistema financiero de LAD COURIER utiliza la infraestructura de Stripe (mediante sus servicios de procesamiento y conectividad) para canalizar las transacciones. Stripe actúa como el procesador bancario externo tanto para Clientes como para Drivers.
5.2 Cumplimiento Obligatorio (KYC): Para poder cobrar o procesar fondos, el Driver debe completar satisfactoriamente los requisitos de verificación de identidad, fiscales y bancarios exigidos directamente por Stripe (Know Your Customer / KYC). El Driver acepta someterse a las normativas de Stripe y reconoce que LAD DIGITAL SYSTEMS LLC no almacena ni gestiona datos de cuentas bancarias ni tarjetas de crédito en sus servidores Firebase.

ARTÍCULO 6: POLÍTICA DE DATOS, FOTOS Y VENTANA DE SEGURIDAD (36 HORAS)
6.1 Consentimiento de Uso de Datos: Tanto los Drivers como los Clientes consienten explícitamente el uso, captura y visualización de fotografías, datos de contacto, geolocalización e información de los puntos de recogida y entrega estrictamente para los fines operativos del proyecto logístico.
6.2 Ventana de Resguardo por Seguridad (36 Horas): Por motivos de seguridad y resolución de disputas comerciales o técnicas, la información completa de cada orden exitosa (incluyendo imágenes de respaldo y coordenadas) se almacenará en la infraestructura de la plataforma y estará al alcance tanto del Driver como del Cliente por un periodo estricto de 36 horas.
6.3 Eliminación Automatizada: Transcurrido el plazo de 36 horas, dichos datos operativos serán purgados o desvinculados de la interfaz activa para garantizar la privacidad total y optimización del sistema, siendo responsabilidad del Driver exportar o guardar sus reportes contables o respaldos privados en su propio dispositivo antes de cumplirse este tiempo.

ARTÍCULO 7: CLÁUSULA DE INDEMNIZACIÓN Y DESCARGO DE RESPONSABILIDAD (DISCHARGE)
El Driver acepta defender, indemnizar y mantener indemne a LAD DIGITAL SYSTEMS LLC, sus gerentes, propietarios y afiliados, frente a cualquier demanda, reclamación, pérdida, multa gubernamental, gasto legal o responsabilidad civil derivada de accidentes de tránsito, disputas comerciales con los clientes, daños a terceros, o violaciones legales cometidas por el Driver durante el uso de la aplicación.""",
                    textAlign: TextAlign.justify,
                    style: TextStyle(fontSize: 11, height: 1.2, color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: _acceptedCheckbox,
                    onChanged: _hasScrolledToBottom ? (val) => setState(() => _acceptedCheckbox = val!) : null,
                    title: const Text(
                      "He leído y acepto el Acuerdo de Operador Independiente y entiendo que LAD Courier no es mi empleador.",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black, height: 1.1),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.blue[700],
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_hasScrolledToBottom && _acceptedCheckbox && !_isSaving) ? _acceptTerms : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.greenAccent,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.greenAccent)
                          : const Text("ACEPTAR Y CONTINUAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2)),
                    ),
                  ),
                  if (!_hasScrolledToBottom)
                    const Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: Text(
                        "POR FAVOR, DESLICE HASTA EL FINAL PARA HABILITAR",
                        style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
