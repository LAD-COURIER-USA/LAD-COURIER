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
      const version = "2026-04-26"; 

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'acceptedTerms': true,
        'acceptedTermsDate': now,
        'acceptedTermsIP': ip,
        'acceptedTermsVersion': version,
        'subscriptionStatus': 'trial',
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
                    "TÉRMINOS DE SERVICIO Y ACUERDO DE OPERADOR INDEPENDIENTE (DRIVER)\n"
                    "Última actualización: 26 de abril de 2026\n"
                    "Entidad Propietaria: LAD Digital Systems LLC (Florida, USA)\n\n"
                    "1. Definición del Servicio: Software, No Logística\n"
                    "Usted reconoce y acepta que LAD Courier es exclusivamente una plataforma de Software como Servicio (SaaS). LAD Digital Systems LLC no es una empresa de transporte ni un despachador. Proporcionamos la herramienta tecnológica para que usted gestione su propia empresa de entregas.\n\n"
                    "2. Estatus de Contratista Independiente\n"
                    "Al aceptar estos términos, usted declara que es un dueño de negocio independiente. No existe relación de empleo con LAD Digital Systems LLC. Usted tiene libertad total para aceptar o rechazar solicitudes, fijar sus precios y elegir sus rutas.\n\n"
                    "3. Protocolo de Verificación de Confianza (LAD Trust)\n"
                    "Para proteger la integridad de la red, el Driver acepta:\n"
                    "• Verificación de Identidad: Uso obligatorio de Stripe Identity para vincular su ID oficial. Esta foto será la única visible para los clientes.\n"
                    "• Verificación Biométrica Periódica: El sistema solicitará selfies aleatorias (aproximadamente cada 72 horas) para confirmar que el operador autorizado es quien utiliza la cuenta.\n"
                    "• Récord de Conducción (MVR): Validación de que su licencia está vigente.\n"
                    "• Costo: El Driver asume el costo técnico de estas validaciones iniciales como inversión para su perfil profesional.\n\n"
                    "4. Responsabilidad sobre el Vehículo y Seguros\n"
                    "Es obligación exclusiva del Driver mantener una póliza de Seguro de Automóvil con cobertura comercial requerida por la ley para servicios de entrega. LAD Digital Systems LLC no provee seguro de accidentes ni de carga.\n\n"
                    "5. Cláusula de Indemnización y Blindaje Legal\n"
                    "Usted acepta eximir de toda responsabilidad a LAD Digital Systems LLC frente a cualquier reclamo o daño que surja de accidentes de tránsito, pérdida de mercancía o su conducta frente a terceros durante el uso de la App.\n\n"
                    "6. Política de \"Identidad Real\"\n"
                    "Para prevenir delitos, el Driver acepta que su ubicación en tiempo real, nombre y foto verificada sean compartidos con el cliente vinculado durante el servicio. El uso de perfiles falsos resultará en la terminación inmediata.\n\n"
                    "7. Tarifas de Servicio y Suscripción\n"
                    "El Driver acepta una tarifa fija de \$0.50 USD por cada orden completada con éxito, en concepto de uso de plataforma y mantenimiento de infraestructura.\n"
                    "Adicionalmente, el Driver asume los costos de procesamiento de la pasarela Stripe (2.9% + \$0.30) sobre el monto total cobrado.\n\n"
                    "8. Limitación de Responsabilidad\n"
                    "La responsabilidad total de LAD Digital Systems LLC hacia usted se limita al monto pagado por el uso de la plataforma en los últimos 3 meses.\n\n"
                    "9. Arbitraje y Renuncia a Acciones Colectivas\n"
                    "Cualquier disputa se resolverá mediante arbitraje individual vinculado en el Condado de Miami-Dade, Florida. Usted renuncia expresamente a participar en demandas colectivas.\n\n"
                    "POLÍTICA DE PRIVACIDAD\n"
                    "Solo rastreamos su ubicación cuando está \"Online\" para efectos de operatividad. Sus datos son procesados bajo estándares de encriptación bancaria por Stripe.",
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
