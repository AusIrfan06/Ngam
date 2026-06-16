import 'dart:async';
import 'package:flutter/material.dart';
import '../models/gig_model.dart';
import '../services/gig_service.dart';

// ============================================================
// Ngam App — Gig Provider
// Manages gig state, filtering, and real-time subscriptions
// ============================================================

class GigProvider extends ChangeNotifier {
  List<GigModel> _openGigs = [];
  List<GigModel> _myGigs = [];
  GigModel? _activeJob;
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _gigsSubscription;

  List<GigModel> get openGigs => _openGigs;
  List<GigModel> get myGigs => _myGigs;
  GigModel? get activeJob => _activeJob;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Filtered gigs based on selected category
  List<GigModel> get filteredGigs {
    if (_selectedCategory == 'All') return _openGigs;
    return _openGigs
        .where((g) => g.category == _selectedCategory)
        .toList();
  }

  // ─── Category Filter ──────────────────────────────────────

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // ─── Fetch Operations ─────────────────────────────────────

  /// Load all open gigs (runner feed)
  Future<void> loadOpenGigs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _openGigs = await GigService.fetchOpenGigs();
      _error = null;
    } catch (e) {
      _error = 'Failed to load gigs';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load customer's posted tasks
  Future<void> loadCustomerGigs(String customerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _myGigs = await GigService.fetchCustomerGigs(customerId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load your tasks';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load runner's accepted jobs
  Future<void> loadRunnerGigs(String runnerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _myGigs = await GigService.fetchRunnerGigs(runnerId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load your jobs';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load runner's current active job
  Future<void> loadActiveJob(String runnerId) async {
    try {
      _activeJob = await GigService.fetchActiveJob(runnerId);
      notifyListeners();
    } catch (e) {
      _activeJob = null;
    }
  }

  // ─── Task Actions ─────────────────────────────────────────

  /// Customer creates a new task
  Future<GigModel?> createGig({
    required String customerId,
    required String title,
    required String description,
    required String category,
    required double bountyAmount,
    required String location,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final gig = await GigService.createGig(
        customerId: customerId,
        title: title,
        description: description,
        category: category,
        bountyAmount: bountyAmount,
        location: location,
      );
      _isLoading = false;
      notifyListeners();
      return gig;
    } catch (e) {
      _error = 'Failed to create task';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Runner accepts a gig (Task-State Locker)
  Future<bool> acceptGig(String gigId, String runnerId) async {
    try {
      await GigService.acceptGig(gigId, runnerId);
      // Update local state
      _openGigs.removeWhere((g) => g.id == gigId);
      _activeJob = await GigService.fetchGigById(gigId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to accept gig. It may already be taken.';
      notifyListeners();
      return false;
    }
  }

  /// Runner marks gig as complete
  Future<bool> completeGig(String gigId) async {
    try {
      await GigService.completeGig(gigId);
      _activeJob = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to complete gig';
      notifyListeners();
      return false;
    }
  }

  // ─── Real-Time Subscriptions ──────────────────────────────

  /// Subscribe to real-time open gigs feed
  void subscribeToOpenGigs() {
    _gigsSubscription?.cancel();
    _gigsSubscription = GigService.subscribeToOpenGigs().listen(
      (gigs) {
        _openGigs = gigs;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Real-time connection lost';
        notifyListeners();
      },
    );
  }

  /// Unsubscribe from real-time feed
  void unsubscribe() {
    _gigsSubscription?.cancel();
    _gigsSubscription = null;
  }

  // ─── Cleanup ──────────────────────────────────────────────

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
