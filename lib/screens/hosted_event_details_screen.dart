import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';

class HostedEventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  const HostedEventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<HostedEventDetailsScreen> createState() => _HostedEventDetailsScreenState();
}

class _HostedEventDetailsScreenState extends State<HostedEventDetailsScreen> {
  final supabase = Supabase.instance.client;
  bool isPurchasing = false;

  Future<void> _buyTicket() async {
    setState(() => isPurchasing = true);
    await Future.delayed(const Duration(seconds: 2)); // mock payment delay
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final profile = await supabase.from('profiles').select('name').eq('id', user.id).single();
      final ticketId = const Uuid().v4().substring(0, 8).toUpperCase();

      await supabase.from('tickets').insert({
        'event_id': widget.event['id'],
        'user_id': user.id,
        'user_name': profile['name'] ?? 'User',
        'ticket_id': ticketId,
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('You\'re in! 🎉', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 64),
              const SizedBox(height: 16),
              const Text('Your ticket code:', style: TextStyle(color: AppColors.subtle)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(12)),
                child: Text(ticketId, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 3, color: AppColors.primary)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: Text('Done', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700))),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.event['price'] ?? 0.0;
    final hostName = widget.event['host_name'] ?? 'Organizer';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Event Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Host
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                CircleAvatar(radius: 22, backgroundColor: AppColors.accent.withValues(alpha: 0.12), child: Icon(Icons.person, color: AppColors.accent)),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(hostName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text('Organizer', style: TextStyle(color: AppColors.subtle, fontSize: 13)),
                ]),
              ]),
            ),
            const SizedBox(height: 24),

            Text(widget.event['title'] ?? '', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2)),
            if (widget.event['description'] != null && widget.event['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(widget.event['description'], style: TextStyle(fontSize: 15, color: AppColors.subtle, height: 1.5)),
            ],
            const SizedBox(height: 24),

            _row(Icons.location_on_outlined, widget.event['location'] ?? ''),
            if (widget.event['datetime'] != null) ...[
              const SizedBox(height: 12),
              Builder(builder: (_) {
                final dt = DateTime.parse(widget.event['datetime']);
                return _row(Icons.access_time_outlined, '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}');
              }),
            ],

            const SizedBox(height: 32),
            // Price
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Entry Fee', style: TextStyle(fontSize: 16, color: AppColors.subtle)),
                  Text(price == 0 ? 'FREE' : '\$${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.success)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPurchasing ? null : _buyTicket,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 18)),
                child: isPurchasing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Buy Ticket', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(children: [
    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: AppColors.primary)),
    const SizedBox(width: 12),
    Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
  ]);
}
