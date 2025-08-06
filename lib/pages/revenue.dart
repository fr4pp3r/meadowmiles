import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meadowmiles/models/booking_model.dart';
import 'package:meadowmiles/states/authstate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class RevenuePage extends StatefulWidget {
  const RevenuePage({super.key});

  @override
  State<RevenuePage> createState() => _RevenuePageState();
}

class _RevenuePageState extends State<RevenuePage> {
  TimePeriod _selectedPeriod = TimePeriod.monthly;
  bool _isLoading = true;
  List<Booking> _returnedBookings = [];
  Map<String, double> _revenueData = {};
  double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    setState(() => _isLoading = true);

    try {
      final authState = Provider.of<AuthState>(context, listen: false);
      final userId = authState.currentUser?.uid;

      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get all returned bookings for this owner
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('ownerId', isEqualTo: userId)
          .get();

      final bookings = querySnapshot.docs
          .map((doc) {
            try {
              return Booking.fromMap(doc.data(), id: doc.id);
            } catch (e) {
              print('Error parsing booking ${doc.id}: $e');
              return null;
            }
          })
          .where(
            (booking) =>
                booking != null && booking.status == BookingStatus.returned,
          )
          .cast<Booking>()
          .toList();

      if (mounted) {
        setState(() {
          _returnedBookings = bookings;
          _calculateRevenue();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading revenue data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading revenue data: $e')),
        );
      }
    }
  }

  void _calculateRevenue() {
    _revenueData.clear();
    _totalRevenue = 0.0;

    if (_returnedBookings.isEmpty) return;

    final now = DateTime.now();
    final dateFormat = _getDateFormat();

    for (final booking in _returnedBookings) {
      try {
        final bookingDate = booking.rentDate;
        final revenue = booking.totalPrice;

        // Skip bookings with invalid data
        if (revenue <= 0) continue;

        // Check if booking falls within selected time period
        if (_isWithinSelectedPeriod(bookingDate, now)) {
          final key = dateFormat.format(bookingDate);
          _revenueData[key] = (_revenueData[key] ?? 0) + revenue;
          _totalRevenue += revenue;
        }
      } catch (e) {
        print('Error processing booking revenue: $e');
        continue;
      }
    }

    // Sort revenue data by date
    final sortedEntries = _revenueData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    _revenueData = Map.fromEntries(sortedEntries);
  }

  DateFormat _getDateFormat() {
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        return DateFormat('MM/dd');
      case TimePeriod.weekly:
        return DateFormat('MM/dd');
      case TimePeriod.monthly:
        return DateFormat('MMM yyyy');
      case TimePeriod.annual:
        return DateFormat('yyyy');
    }
  }

  bool _isWithinSelectedPeriod(DateTime bookingDate, DateTime now) {
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        return bookingDate.isAfter(now.subtract(const Duration(days: 30))) ||
            bookingDate.isAtSameMomentAs(
              now.subtract(const Duration(days: 30)),
            );
      case TimePeriod.weekly:
        return bookingDate.isAfter(
              now.subtract(const Duration(days: 12 * 7)),
            ) ||
            bookingDate.isAtSameMomentAs(
              now.subtract(const Duration(days: 12 * 7)),
            );
      case TimePeriod.monthly:
        final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
        return bookingDate.isAfter(oneYearAgo) ||
            bookingDate.isAtSameMomentAs(oneYearAgo);
      case TimePeriod.annual:
        final fiveYearsAgo = DateTime(now.year - 5, now.month, now.day);
        return bookingDate.isAfter(fiveYearsAgo) ||
            bookingDate.isAtSameMomentAs(fiveYearsAgo);
    }
  }

  String _getPeriodTitle() {
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        return 'Daily Revenue (Last 30 Days)';
      case TimePeriod.weekly:
        return 'Weekly Revenue (Last 12 Weeks)';
      case TimePeriod.monthly:
        return 'Monthly Revenue (Last 12 Months)';
      case TimePeriod.annual:
        return 'Annual Revenue (Last 5 Years)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Period',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: TimePeriod.values.map((period) {
                              final isSelected = _selectedPeriod == period;
                              return FilterChip(
                                label: Text(_getPeriodLabel(period)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedPeriod = period;
                                      _calculateRevenue();
                                    });
                                  }
                                },
                                selectedColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                                checkmarkColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total Revenue Summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.attach_money,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Revenue',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                Text(
                                  '₱ ${_totalRevenue.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                ),
                                Text(
                                  '${_returnedBookings.length} completed bookings',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Revenue Breakdown
                  SizedBox(
                    height: 400, // Fixed height instead of Expanded
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPeriodTitle(),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _revenueData.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.bar_chart,
                                            size: 64,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No revenue data available',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          Text(
                                            'Complete some bookings to see revenue',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _revenueData.length,
                                      itemBuilder: (context, index) {
                                        final entry = _revenueData.entries
                                            .toList()[index];
                                        final percentage = _totalRevenue > 0
                                            ? (entry.value / _totalRevenue)
                                            : 0.0;

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    entry.key,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                  Text(
                                                    '₱${entry.value.toStringAsFixed(2)}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.green,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              LinearProgressIndicator(
                                                value: percentage,
                                                backgroundColor:
                                                    Colors.grey.shade300,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${(percentage * 100).toStringAsFixed(1)}% of total',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.daily:
        return 'Daily';
      case TimePeriod.weekly:
        return 'Weekly';
      case TimePeriod.monthly:
        return 'Monthly';
      case TimePeriod.annual:
        return 'Annual';
    }
  }
}

enum TimePeriod { daily, weekly, monthly, annual }
