import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _isProcessing = false;
  String _selectedPlan = 'pro';
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserReferrals();
  }

  Future<void> _loadUserReferrals() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _currentUser = UserModel.fromFirestore(doc);
          if (_currentUser?.subscriptionType != null) {
            _selectedPlan = _currentUser!.subscriptionType!;
          }
        });
      }
    }
  }

  Future<void> _handleSubscription() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      // DEFINICIÓN DE RADIOS POR ZONA (LAD STRATEGY)
      double radius = 5.0;
      double dropoffRadius = 5.0;

      if (_selectedPlan == 'standart') {
        radius = 25.0;
        dropoffRadius = 25.0;
      } else if (_selectedPlan == 'pro') {
        radius = 25.0;
        dropoffRadius = 120.0;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'subscriptionType': _selectedPlan,
          'subscriptionStatus': 'active',
          'maxRadiusMiles': radius,
          'maxDropoffRadiusMiles': dropoffRadius,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Zona de Trabajo actualizada con éxito"), backgroundColor: Colors.green)
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Text(l10n.sub_title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Info de Zonas: Ahora son gratis
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 2)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.sub_promo,
                        style: TextStyle(
                          fontWeight: FontWeight.w900, 
                          fontSize: 13, 
                          color: Colors.blue[900], // Azul Marino para máximo contraste
                          letterSpacing: 0.5
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              _buildPlanCard(
                  l10n: l10n,
                  id: 'lite',
                  title: l10n.sub_plan_lite_title,
                  subtitle: l10n.sub_plan_lite_desc,
                  radiusText: "5 mi",
                  color: Colors.blue,
                  icon: Icons.pedal_bike
              ),
              const SizedBox(height: 12),

              _buildPlanCard(
                  l10n: l10n,
                  id: 'standart',
                  title: l10n.sub_plan_standart_title,
                  subtitle: l10n.sub_plan_standart_desc,
                  radiusText: "25 mi",
                  color: Colors.orange[800]!,
                  icon: Icons.local_shipping
              ),
              const SizedBox(height: 12),

              _buildPlanCard(
                  l10n: l10n,
                  id: 'pro',
                  title: l10n.sub_plan_pro_title,
                  subtitle: l10n.sub_plan_pro_desc,
                  radiusText: "25 mi / 120 mi",
                  color: Colors.deepPurple,
                  icon: Icons.rocket_launch
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _isProcessing ? null : _handleSubscription,
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.greenAccent)
                        : Text(l10n.sub_btn_activate, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.greenAccent))
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.earnings_refund_disclaimer,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w900), // w900 para que se vea bien
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required AppLocalizations l10n,
    required String id,
    required String title,
    required String subtitle,
    required String radiusText,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedPlan == id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: isSelected ? color : Colors.black12,
              width: isSelected ? 3 : 1
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black87)),
                  Text(l10n.sub_radius(radiusText), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10)
              ),
              child: Text(
                l10n.sub_free,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.greenAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
