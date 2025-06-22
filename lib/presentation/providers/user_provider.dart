import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user.dart';
import '../../data/services/storage_service.dart';

/// Provider for managing user state and data
class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _cachedLastLogin;
  bool _hasSetBudget = false; // Track if user has explicitly set a budget

  /// Current user data
  User? get user => _user;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Check if user has explicitly set a budget
  bool get hasSetBudget => _hasSetBudget;

  /// User getters with defaults
  String get name => _user?.name ?? AppConstants.defaultName;
  String get email => _user?.email ?? AppConstants.defaultEmail;
  double get height => _user?.height ?? AppConstants.defaultHeight;
  double get weight => _user?.weight ?? AppConstants.defaultWeight;
  int get age => _user?.age ?? AppConstants.defaultAge;
  String get gender => _user?.gender ?? AppConstants.defaultGender;
  String get activityLevel =>
      _user?.activityLevel ?? AppConstants.defaultActivityLevel;
  String get goal => _user?.goal ?? AppConstants.defaultGoal;
  String get avatar => _user?.avatar ?? AppConstants.defaultAvatar;
  int get loginCount => _user?.loginCount ?? AppConstants.defaultLoginCount;
  String get lastLogin =>
      _cachedLastLogin ??= _user?.lastLogin ?? DateTime.now().toString();
  int get completedGoals => _user?.completedGoals ?? 0;
  double get budget => _user?.budget ?? AppConstants.defaultBudget;
  int get notificationCount =>
      _user?.notificationCount ?? AppConstants.defaultNotificationCount;

  /// Initialize user data from storage
  Future<void> loadUserData() async {
    if (_isLoading) return;

    print('🔧 UserProvider.loadUserData() called');
    _isLoading = true;
    notifyListeners();

    try {
      await StorageService.init();
      _user = await StorageService.loadUser();
      _cachedLastLogin = _user?.lastLogin;
      
      // Check if user has explicitly set a budget (not just default value)
      _hasSetBudget = _user?.budget != null && _user!.budget != AppConstants.defaultBudget;
      
      print('🔧 UserProvider.loadUserData() - loaded user: ${_user?.name}, budget: ${_user?.budget}');
      print('🔧 UserProvider.loadUserData() - hasSetBudget: $_hasSetBudget');
    } catch (e) {
      print('🔧 UserProvider.loadUserData() - error loading user: $e');
      // If loading fails, create default user
      _user = _createDefaultUser();
      _hasSetBudget = false; // Default user hasn't set budget
      print('🔧 UserProvider.loadUserData() - created default user with budget: ${_user?.budget}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  User _createDefaultUser() => User(
        name: AppConstants.defaultName,
        email: AppConstants.defaultEmail,
        height: AppConstants.defaultHeight,
        weight: AppConstants.defaultWeight,
        age: AppConstants.defaultAge,
        gender: AppConstants.defaultGender,
        activityLevel: AppConstants.defaultActivityLevel,
        goal: AppConstants.defaultGoal,
        avatar: AppConstants.defaultAvatar,
        loginCount: AppConstants.defaultLoginCount,
        lastLogin: DateTime.now().toString(),
        completedGoals: 0,
        budget: AppConstants.defaultBudget,
        notificationCount: AppConstants.defaultNotificationCount,
      );

  /// Update user data
  Future<void> updateUser(User updatedUser) async {
    print('🔧 UserProvider.updateUser() called with budget: ${updatedUser.budget}');
    print('🔧 UserProvider.updateUser() - current _user budget: ${_user?.budget}');
    print('🔧 UserProvider.updateUser() - _user == updatedUser: ${_user == updatedUser}');
    
    if (_user == updatedUser) {
      print('🔧 UserProvider.updateUser() - users are identical, returning early');
      return;
    }

    _user = updatedUser;
    _cachedLastLogin = updatedUser.lastLogin;
    print('🔧 UserProvider.updateUser() - _user updated, new budget: ${_user?.budget}');
    
    await StorageService.saveUser(updatedUser);
    print('🔧 UserProvider.updateUser() - user saved to storage, budget: ${_user?.budget}');
    notifyListeners();
  }

  /// Update specific user field
  Future<void> updateUserField({
    String? name,
    String? email,
    double? height,
    double? weight,
    int? age,
    String? gender,
    String? activityLevel,
    String? goal,
    String? avatar,
    int? loginCount,
    String? lastLogin,
    int? completedGoals,
    double? budget,
    int? notificationCount,
  }) async {
    print('🔧 UserProvider.updateUserField() called with budget: $budget');
    print('🔧 UserProvider.updateUserField() - _user is null: ${_user == null}');
    
    if (_user == null) {
      print('🔧 UserProvider.updateUserField() - _user is null, loading user data first');
      await loadUserData();
      if (_user == null) {
        print('🔧 UserProvider.updateUserField() - still null after loading, creating default user');
        _user = _createDefaultUser();
      }
    }

    final updatedUser = _user!.copyWith(
      name: name,
      email: email,
      height: height,
      weight: weight,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      goal: goal,
      avatar: avatar,
      loginCount: loginCount,
      lastLogin: lastLogin,
      completedGoals: completedGoals,
      budget: budget,
      notificationCount: notificationCount,
    );

    print('🔧 UserProvider.updateUserField() - created updatedUser with budget: ${updatedUser.budget}');
    await updateUser(updatedUser);
  }

  /// Update avatar
  Future<void> setAvatar(String newAvatar) =>
      updateUserField(avatar: newAvatar);

  /// Update name
  Future<void> setName(String newName) => updateUserField(name: newName);

  /// Update budget
  Future<void> setBudget(double newBudget) async {
    print('🔧 UserProvider.setBudget called with: $newBudget');
    print('🔧 Current budget before update: ${_user?.budget ?? 'null'}');
    
    _hasSetBudget = true; // Mark that user has explicitly set a budget
    await updateUserField(budget: newBudget);
    
    print('🔧 Budget after update: ${_user?.budget ?? 'null'}');
    print('🔧 UserProvider.notifyListeners() called');
  }

  /// Increment login count
  Future<void> incrementLoginCount() =>
      updateUserField(loginCount: loginCount + 1);

  /// Update last login time
  Future<void> updateLastLogin(String dateTime) =>
      updateUserField(lastLogin: dateTime);

  /// Increment completed goals
  Future<void> incrementCompletedGoals() =>
      updateUserField(completedGoals: completedGoals + 1);

  /// Clear all user data
  Future<void> clearUserData() async {
    await StorageService.clearAll();
    _user = null;
    _cachedLastLogin = null;
    notifyListeners();
  }
}
