class Validators {
  static String? validateSecretWord(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a secret word';
    }

    if (value.trim().length < 3) {
      return 'Secret word must be at least 3 characters';
    }

    if (value.trim().length > 30) {
      return 'Secret word must be less than 30 characters';
    }

    return null;
  }

  static String? validateRoomId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a room ID';
    }

    if (value.trim().length < 4) {
      return 'Room ID must be at least 4 characters';
    }

    return null;
  }

  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a message';
    }

    if (value.trim().length > 1000) {
      return 'Message is too long (max 1000 characters)';
    }

    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username';
    }

    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (value.trim().length > 20) {
      return 'Username must be less than 20 characters';
    }

    return null;
  }
}
