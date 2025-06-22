import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user.dart';
import '../../data/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    print('DEBUG: UserProvider.loadUserData() called');
    _isLoading = true;
    notifyListeners();

    try {
      await StorageService.init();
      User loadedUser = await StorageService.loadUser();
      
      // Load saved avatar from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? savedAvatar = prefs.getString('selected_avatar');
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        loadedUser = loadedUser.copyWith(avatar: savedAvatar);
        print('DEBUG: UserProvider.loadUserData() - loaded saved avatar: $savedAvatar');
      }
      
      _user = loadedUser;
      _cachedLastLogin = loadedUser.lastLogin;
      _hasSetBudget = loadedUser.budget != AppConstants.defaultBudget;
      _isLoading = false;
      
      print('DEBUG: UserProvider.loadUserData() - loaded user: ${_user?.name}, budget: ${_user?.budget}, avatar: ${_user?.avatar}');
      print('DEBUG: UserProvider.loadUserData() - hasSetBudget: $_hasSetBudget');
      
    } catch (e) {
      print('DEBUG: UserProvider.loadUserData() - error loading user: $e');
      // Create default user if loading fails
      _user = _createDefaultUser();
      _hasSetBudget = false; // Default user hasn't set budget
      _isLoading = false;
      print('DEBUG: UserProvider.loadUserData() - created default user with budget: ${_user?.budget}');
    }
    
    notifyListeners();
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
    print('DEBUG: UserProvider.updateUser() called with budget: ${updatedUser.budget}');
    print('DEBUG: UserProvider.updateUser() - current _user budget: ${_user?.budget}');
    print('DEBUG: UserProvider.updateUser() - _user == updatedUser: ${_user == updatedUser}');
    
    // Check if users are identical to avoid unnecessary updates
    if (_user == updatedUser) {
      print('DEBUG: UserProvider.updateUser() - users are identical, returning early');
      return;
    }
    
    _user = updatedUser;
    _cachedLastLogin = updatedUser.lastLogin;
    _hasSetBudget = updatedUser.budget != AppConstants.defaultBudget;
    
    print('DEBUG: UserProvider.updateUser() - _user updated, new budget: ${_user?.budget}');
    
    // Save to storage
    await StorageService.saveUser(updatedUser);
    print('DEBUG: UserProvider.updateUser() - user saved to storage, budget: ${_user?.budget}');
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
    print('DEBUG: UserProvider.updateUserField() called with budget: $budget');
    print('DEBUG: UserProvider.updateUserField() - _user is null: ${_user == null}');
    
    // Ensure user exists
    if (_user == null) {
      print('DEBUG: UserProvider.updateUserField() - _user is null, loading user data first');
      await loadUserData();
      
      if (_user == null) {
        print('DEBUG: UserProvider.updateUserField() - still null after loading, creating default user');
        _user = _createDefaultUser();
      }
    }

    User updatedUser = _user!.copyWith(
      name: name ?? _user!.name,
      email: email ?? _user!.email,
      height: height ?? _user!.height,
      weight: weight ?? _user!.weight,
      age: age ?? _user!.age,
      gender: gender ?? _user!.gender,
      activityLevel: activityLevel ?? _user!.activityLevel,
      goal: goal ?? _user!.goal,
      avatar: avatar ?? _user!.avatar,
      loginCount: loginCount ?? _user!.loginCount,
      lastLogin: lastLogin ?? _user!.lastLogin,
      completedGoals: completedGoals ?? _user!.completedGoals,
      budget: budget ?? _user!.budget,
      notificationCount: notificationCount ?? _user!.notificationCount,
    );

    print('DEBUG: UserProvider.updateUserField() - created updatedUser with budget: ${updatedUser.budget}');
    await updateUser(updatedUser);
  }

  /// Update avatar
  Future<void> setAvatar(String newAvatar) async {
    print('DEBUG: UserProvider.setAvatar() called with: $newAvatar');
    print('DEBUG: UserProvider.setAvatar() - current avatar: ${_user?.avatar}');
    
    // Save to SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_avatar', newAvatar);
    print('DEBUG: UserProvider.setAvatar() - saved to SharedPreferences: $newAvatar');
    
    // Update user data
    await updateUserField(avatar: newAvatar);
    print('DEBUG: UserProvider.setAvatar() - updated user avatar to: ${_user?.avatar}');
    
    // Force notify listeners
    notifyListeners();
    print('DEBUG: UserProvider.setAvatar() - notified listeners');
  }

  /// Update name
  Future<void> setName(String newName) => updateUserField(name: newName);

  /// Update budget
  Future<void> setBudget(double newBudget) async {
    print('DEBUG: UserProvider.setBudget called with: $newBudget');
    print('DEBUG: Current budget before update: ${_user?.budget ?? 'null'}');
    
    _hasSetBudget = true;
    await updateUserField(budget: newBudget);
    
    print('DEBUG: Budget after update: ${_user?.budget ?? 'null'}');
    print('DEBUG: UserProvider.notifyListeners() called');
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
