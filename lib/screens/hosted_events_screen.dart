import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'create_hosted_event_screen.dart';
import 'hosted_event_details_screen.dart';
import '../main.dart';

class HostedEventsScreen extends StatelessWidget {
  const HostedEventsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Events')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('hosted_events').stream(primaryKey: ['id']).order('datetime', ascending: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          final events = snapshot.data!;

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.celebration_outlined, size: 72, color: AppColors.subtle.withValues(alpha: 0.5)),
                  const SizedBox(height: 20),
                  Text('No events yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Text('Create a ticketed event!', style: TextStyle(color: AppColors.subtle)),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateHostedEventScreen())),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Host an Event'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final title = event['title'] ?? 'Untitled';
              final location = event['location'] ?? '';
              final price = event['price'] ?? 0.0;
              final hostName = event['host_name'] ?? 'Organizer';
              DateTime? datetime;
              if (event['datetime'] != null) datetime = DateTime.parse(event['datetime']);

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HostedEventDetailsScreen(event: event))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(hostName, style: TextStyle(color: AppColors.subtle, fontWeight: FontWeight.w600, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              price == 0 ? 'FREE' : '\$${price.toStringAsFixed(2)}',
                              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      if (location.isNotEmpty) _info(Icons.location_on_outlined, location),
                      if (datetime != null) Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _info(Icons.access_time_outlined, '${datetime.day}/${datetime.month}/${datetime.year} at ${datetime.hour}:${datetime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateHostedEventScreen())),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _info(IconData icon, String text) => Row(children: [
    Icon(icon, size: 16, color: AppColors.subtle),
    const SizedBox(width: 6),
    Text(text, style: TextStyle(color: AppColors.subtle, fontSize: 13)),
  ]);
}
