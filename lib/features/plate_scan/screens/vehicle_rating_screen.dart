import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/vehicle_journey_service.dart';

class CompletedVehicleJourneysScreen extends StatefulWidget {
  const CompletedVehicleJourneysScreen({super.key, required this.plate});
  final String plate;
  @override
  State<CompletedVehicleJourneysScreen> createState() =>
      _CompletedVehicleJourneysScreenState();
}

class _CompletedVehicleJourneysScreenState
    extends State<CompletedVehicleJourneysScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _journeys =
      FirebaseFirestore.instance
          .collection('journeys')
          .where('userId',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
          .snapshots();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Completed vehicle rides')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _journeys,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                    child:
                        Text('Could not load your rides. Please reconnect.'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final rides = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                return data['status'] == 'safe' &&
                    data['metadata'] is Map &&
                    data['metadata']['vehiclePlate'] == widget.plate;
              }).toList();
              if (rides.isEmpty) {
                return const Center(
                    child: Text('No completed rides for this vehicle yet.'));
              }
              return ListView(
                  children: rides.map((doc) {
                final destination = doc.data()['destination'];
                return ListTile(
                  title: Text(destination is Map
                      ? '${destination['name'] ?? widget.plate}'
                      : widget.plate),
                  subtitle: Text(widget.plate),
                  trailing: const Icon(Icons.star_outline),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => VehicleRatingScreen(
                              journeyId: doc.id, plate: widget.plate))),
                );
              }).toList());
            }),
      );
}

class VehicleRatingScreen extends StatefulWidget {
  const VehicleRatingScreen(
      {super.key, required this.journeyId, required this.plate});
  final String journeyId;
  final String plate;
  @override
  State<VehicleRatingScreen> createState() => _VehicleRatingScreenState();
}

class _VehicleRatingScreenState extends State<VehicleRatingScreen> {
  int _stars = 0;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await const VehicleJourneyService()
          .submitRating(widget.journeyId, widget.plate, _stars);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Rating submitted')));
        Navigator.pop(context);
      }
    } on VehicleRatingException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save your rating. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rate your journey')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          Text(widget.plate, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('How was your experience traveling in this vehicle?'),
          Wrap(
              children: List.generate(
                  5,
                  (index) => IconButton(
                        tooltip: '${index + 1} stars',
                        onPressed: _saving
                            ? null
                            : () => setState(() => _stars = index + 1),
                        icon: Icon(
                            index < _stars ? Icons.star : Icons.star_border,
                            color: Colors.amber),
                      ))),
          if (_error != null) Text(_error!),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: _saving || _stars == 0 ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Submit rating')),
          TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Skip')),
        ]),
      );
}
