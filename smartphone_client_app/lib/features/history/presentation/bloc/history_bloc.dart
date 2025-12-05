import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';
import '../../data/models/access_log.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  static const String baseUrl = 'https://aditus-api.mxv.pt/api';
  static const int pageSize = 20;

  final SecureStorageService _storage;
  final http.Client _httpClient;

  int _currentOffset = 0;

  HistoryBloc({
    SecureStorageService? storage,
    http.Client? httpClient,
  })  : _storage = storage ?? SecureStorageService(),
        _httpClient = httpClient ?? http.Client(),
        super(const HistoryInitial()) {
    on<LoadHistoryRequested>(_onLoadHistory);
    on<RefreshHistoryRequested>(_onRefreshHistory);
    on<LoadMoreHistoryRequested>(_onLoadMoreHistory);
  }

  Future<void> _onLoadHistory(
    LoadHistoryRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());

    try {
      _currentOffset = 0;
      final result = await _fetchLogs(limit: pageSize, offset: _currentOffset);

      if (result['logs'].isEmpty) {
        emit(const HistoryEmpty());
      } else {
        emit(HistoryLoaded(
          logs: result['logs'],
          total: result['total'],
          hasMore: result['logs'].length < result['total'],
        ));
      }
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<void> _onRefreshHistory(
    RefreshHistoryRequested event,
    Emitter<HistoryState> emit,
  ) async {
    // Keep current state while refreshing
    try {
      _currentOffset = 0;
      final result = await _fetchLogs(limit: pageSize, offset: _currentOffset);

      if (result['logs'].isEmpty) {
        emit(const HistoryEmpty());
      } else {
        emit(HistoryLoaded(
          logs: result['logs'],
          total: result['total'],
          hasMore: result['logs'].length < result['total'],
        ));
      }
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<void> _onLoadMoreHistory(
    LoadMoreHistoryRequested event,
    Emitter<HistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HistoryLoaded || !currentState.hasMore || currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      _currentOffset += pageSize;
      final result = await _fetchLogs(limit: pageSize, offset: _currentOffset);

      final updatedLogs = List<AccessLog>.from(currentState.logs)..addAll(result['logs']);

      emit(HistoryLoaded(
        logs: updatedLogs,
        total: result['total'],
        hasMore: updatedLogs.length < result['total'],
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
      emit(HistoryError(e.toString()));
    }
  }

  Future<Map<String, dynamic>> _fetchLogs({required int limit, required int offset}) async {
    final token = await _storage.getAccessToken();

    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$baseUrl/access-logs/my-logs?limit=$limit&offset=$offset');

    final response = await _httpClient.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final logs = (data['logs'] as List)
          .map((json) => AccessLog.fromJson(json))
          .toList();

      return {
        'logs': logs,
        'total': data['total'],
      };
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    } else {
      throw Exception('Failed to load access logs: ${response.statusCode}');
    }
  }

  @override
  Future<void> close() {
    _httpClient.close();
    return super.close();
  }
}
