import 'package:dio/dio.dart';
import '../../data/models/auth_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';
import 'base_provider.dart';

class AuthProvider extends BaseProvider {
  final ApiService _apiService;

  AuthProvider(this._apiService);

  AuthModel? _authModel;
  AuthModel? get authModel => _authModel;

  Future<bool> login({
    required String phone,
    String countryCode = '+91',
  }) async {
    setLoading();
    try {
      final formData = FormData.fromMap({
        'country_code': countryCode,
        'phone': phone,
      });

      final response = await _apiService.postFormData('otp_verified', formData);
      final data = response.data;

      if (data['status'] == true) {
        _authModel = AuthModel.fromJson(data);
        await StorageService.saveToken(_authModel!.accessToken);
        await StorageService.setLoggedIn(true);
        setIdle();
        return true;
      } else {
        setError(data['message'] ?? 'Login failed. Please try again.');
        return false;
      }
    } on Exception catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

}
