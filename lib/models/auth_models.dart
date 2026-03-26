// lib/models/auth_models.dart

class LoginRequest {
  final String plate;

  LoginRequest({required this.plate});

  Map<String, dynamic> toJson() {
    return {'plate': plate};
  }
}

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final int driverId; // String yerine int yaptık
  final int vehicleId; // String yerine int yaptık
  final String plate;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.driverId,
    required this.vehicleId,
    required this.plate,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'],
      tokenType: json['tokenType'],
      driverId: json['driverId'],
      vehicleId: json['vehicleId'],
      plate: json['plate'],
    );
  }
}

class MeResponse {
  final String driverId;
  final String fullName;
  final String vehicleId;
  final String plate;
  final String wasteType;

  MeResponse({
    required this.driverId,
    required this.fullName,
    required this.vehicleId,
    required this.plate,
    required this.wasteType,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      driverId: json['driverId'] ?? '',
      fullName: json['fullName'] ?? '',
      vehicleId: json['vehicleId'] ?? '',
      plate: json['plate'] ?? '',
      wasteType: json['wasteType'] ?? '',
    );
  }
}
