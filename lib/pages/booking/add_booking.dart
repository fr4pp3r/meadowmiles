import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meadowmiles/models/booking_model.dart';
import 'package:meadowmiles/models/vehicle_model.dart';
import 'package:provider/provider.dart';
import 'package:meadowmiles/states/authstate.dart';

class AddBookingPage extends StatefulWidget {
  final Vehicle vehicle;
  const AddBookingPage({super.key, required this.vehicle});

  @override
  State<AddBookingPage> createState() => _AddBookingPageState();
}

class _AddBookingPageState extends State<AddBookingPage> {
  int _currentStep = 0;
  DateTime? _rentDate;
  DateTime? _returnDate;
  bool _isLoading = false;
  String? _ownerName;

  @override
  void initState() {
    super.initState();
    _fetchOwnerName();
  }

  Future<void> _fetchOwnerName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.vehicle.ownerId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _ownerName = doc.data()?['name'] ?? widget.vehicle.ownerId;
        });
      }
    } catch (e) {
      setState(() {
        _ownerName = widget.vehicle.ownerId;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _selectDate(BuildContext context, bool isRent) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isRent
          ? (_rentDate ?? now)
          : (_returnDate ?? now.add(const Duration(days: 1))),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isRent) {
          _rentDate = picked;
          if (_returnDate != null && _returnDate!.isBefore(_rentDate!)) {
            _returnDate = null;
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _submitBooking() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final renterId = authState.currentUser?.uid;
    if (renterId == null || _rentDate == null || _returnDate == null) return;
    setState(() => _isLoading = true);
    final booking = Booking(
      id: Booking.generateBookingId(),
      renterId: renterId,
      vehicleId: widget.vehicle.id,
      ownerId: widget.vehicle.ownerId,
      transactionId: '',
      rentDate: _rentDate!,
      returnDate: _returnDate!,
      status: BookingStatus.pending,
      ratingRef: '',
      address: '', // Address left empty for owner to fill
    );
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .set(booking.toMap());
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Created'),
            content: const Text('Your booking has been submitted!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                  Navigator.of(context).popUntil(
                    (route) => route.settings.name == '/renter_dashboard',
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to create booking: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double? get _totalAmount {
    if (_rentDate == null || _returnDate == null) return null;
    final days = _returnDate!.difference(_rentDate!).inDays;
    if (days <= 0) return null;
    return days * widget.vehicle.pricePerDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Booking')),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && (_rentDate == null || _returnDate == null)) {
            return;
          }
          if (_currentStep < 1) {
            _nextStep();
          } else {
            _submitBooking();
          }
        },
        onStepCancel: _prevStep,
        controlsBuilder: (context, details) {
          return Row(
            children: [
              if (_currentStep > 0)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: details.onStepContinue,
                child: _currentStep < 1
                    ? const Text('Next')
                    : (_isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit')),
              ),
            ],
          );
        },
        steps: [
          Step(
            title: const Text('Dates'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    _rentDate == null || _returnDate == null
                        ? 'Select Date Range'
                        : 'From: ${_rentDate!.toLocal().toString().split(' ')[0]}  To: ${_returnDate!.toLocal().toString().split(' ')[0]}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                      initialDateRange: _rentDate != null && _returnDate != null
                          ? DateTimeRange(start: _rentDate!, end: _returnDate!)
                          : null,
                    );
                    if (picked != null) {
                      // Check for booking overlaps
                      final bookingsSnapshot = await FirebaseFirestore.instance
                          .collection('bookings')
                          .where('vehicleId', isEqualTo: widget.vehicle.id)
                          .where(
                            'status',
                            whereIn: ['pending', 'onProcess', 'active'],
                          )
                          .get();
                      bool hasOverlap = false;
                      for (final doc in bookingsSnapshot.docs) {
                        final data = doc.data();
                        final bookingStart = (data['rentDate'] as Timestamp)
                            .toDate();
                        final bookingEnd = (data['returnDate'] as Timestamp)
                            .toDate();
                        if (!(picked.end.isBefore(bookingStart) ||
                            picked.start.isAfter(bookingEnd))) {
                          hasOverlap = true;
                          break;
                        }
                      }
                      if (hasOverlap) {
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Date Unavailable'),
                              content: const Text(
                                'The selected date range overlaps with an existing booking. Please select a new date or change vehicles.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      } else {
                        setState(() {
                          _rentDate = picked.start;
                          _returnDate = picked.end;
                        });
                      }
                    }
                  },
                ),
                if (_rentDate != null &&
                    _returnDate != null &&
                    _returnDate!.isBefore(_rentDate!))
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Return date must be after rent date',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Confirm'),
            isActive: _currentStep >= 1,
            state: StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vehicle: ${widget.vehicle.make} ${widget.vehicle.model}'),
                Text('Owner: ${_ownerName ?? "..."}'),
                Text(
                  'Rent Date: ${_rentDate != null ? _rentDate!.toLocal().toString().split(' ')[0] : ''}',
                ),
                Text(
                  'Return Date: ${_returnDate != null ? _returnDate!.toLocal().toString().split(' ')[0] : ''}',
                ),
                if (_totalAmount != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Total Amount: ₱${_totalAmount!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
