import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/call_repository.dart';
import 'call_state.dart';

class CallBloc extends Cubit<CallState> {
  final CallRepository _callRepository;
  StreamSubscription? _callSubscription;

  CallBloc(this._callRepository) : super(const CallState()) {
    _monitorCallState();
  }

  void _monitorCallState() {
    _callSubscription = _callRepository.callStateStream.listen((data) {
      final int nativeState = data['state'];
      final String number = data['number'];
      
      CallStatus status = CallStatus.initial;
      // Mapping based on CallService constants
      // STATE_DIALING = 1, STATE_RINGING = 2, STATE_ACTIVE = 4, STATE_DISCONNECTED = 7, STATE_CONNECTING = 9
      switch (nativeState) {
        case 1: // DIALING
        case 9: // CONNECTING
          status = CallStatus.dialing;
          break;
        case 2: // RINGING
          status = CallStatus.ringing;
          break;
        case 4: // ACTIVE
          status = CallStatus.active;
          break;
        case 7: // DISCONNECTED
          status = CallStatus.disconnected;
          break;
        default:
          status = CallStatus.initial;
      }
      
      emit(state.copyWith(status: status, number: number));
    });
  }

  Future<void> makeCall(String number) async {
    await _callRepository.makeCall(number);
  }

  Future<void> requestDefaultDialer() async {
    await _callRepository.setDefaultDialer();
  }

  @override
  Future<void> close() {
    _callSubscription?.cancel();
    return super.close();
  }
}
