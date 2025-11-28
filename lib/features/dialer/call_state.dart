import 'package:equatable/equatable.dart';

enum CallStatus { initial, dialing, ringing, active, disconnected }

class CallState extends Equatable {
  final CallStatus status;
  final String number;

  const CallState({
    this.status = CallStatus.initial,
    this.number = '',
  });

  CallState copyWith({
    CallStatus? status,
    String? number,
  }) {
    return CallState(
      status: status ?? this.status,
      number: number ?? this.number,
    );
  }

  @override
  List<Object> get props => [status, number];
}
