import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/event/hosted_event_card.dart';
import 'create_hosted_event_screen.dart';
import 'hosted_event_details_screen.dart';

class HostedEventsScreen extends StatelessWidget {
  const HostedEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Ticketed Events')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('hosted_events')
            .stream(primaryKey: ['id'])
            .order('datetime', ascending: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final events = snapshot.data!;

          if (events.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SwoopEmptyState(
                headline: 'No events yet',
                subheadline: 'Host a ticketed experience and find people to go with.',
                primaryLabel: 'Host an Event',
                onPrimary: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateHostedEventScreen()),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final title = event['title'] ?? 'Untitled';
              final location = event['location'] ?? '';
              final price = (event['price'] as num?)?.toDouble() ?? 0.0;
              final hostName = event['host_name'] ?? 'Organizer';
              final imgUrl = event['img_url'] as String?;
              String dateTime = '';
              if (event['datetime'] != null) {
                final dt = DateTime.parse(event['datetime']);
                dateTime =
                    '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return HostedEventCard(
                title: title,
                hostName: hostName,
                location: location,
                dateTime: dateTime,
                price: price,
                imageUrl: imgUrl,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HostedEventDetailsScreen(event: event),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'hosted_events_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateHostedEventScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
