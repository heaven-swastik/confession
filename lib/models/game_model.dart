enum GameCategory {
  party,
  trivia,
  creative,
  teamwork,
}

class GameModel {
  final String gameId;
  final String name;
  final String description;
  final int minPlayers;
  final int maxPlayers;
  final GameCategory category;
  final String instructions;
  final List<String> rules;
  final String emoji;

  GameModel({
    required this.gameId,
    required this.name,
    required this.description,
    required this.minPlayers,
    required this.maxPlayers,
    required this.category,
    required this.instructions,
    required this.rules,
    required this.emoji,
  });
}

class PredefinedGames {
  // 2 PLAYER GAMES
  static final GameModel truthOrDare = GameModel(
    gameId: 'truth_dare',
    name: 'Truth or Dare',
    description: 'Classic game of truth or dare',
    minPlayers: 2,
    maxPlayers: 4,
    category: GameCategory.party,
    emoji: '🤫',
    instructions: 'Take turns asking Truth or Dare. Be honest and brave!',
    rules: [
      'Player 1 asks: Truth or Dare?',
      'Player 2 chooses and answers',
      'Switch turns',
      'No skipping!',
    ],
  );

  static final GameModel wouldYouRather = GameModel(
    gameId: 'would_you_rather',
    name: 'Would You Rather',
    description: 'Choose between two impossible scenarios',
    minPlayers: 2,
    maxPlayers: 4,
    category: GameCategory.party,
    emoji: '🤔',
    instructions: 'One player asks "Would you rather A or B?", others vote and explain why!',
    rules: [
      'Create funny scenarios',
      'Everyone must choose',
      'Explain your choice',
      'Most creative question wins!',
    ],
  );

  // 3 PLAYER GAMES
  static final GameModel storyChain = GameModel(
    gameId: 'story_chain',
    name: 'Story Chain',
    description: 'Build a story together, one sentence at a time',
    minPlayers: 2,
    maxPlayers: 4,
    category: GameCategory.creative,
    emoji: '📖',
    instructions: 'Each player adds one sentence to create a crazy story!',
    rules: [
      'Player 1 starts the story',
      'Each player adds ONE sentence',
      'Keep it funny and creative',
      'Try to surprise others!',
    ],
  );

  static final GameModel emojiStory = GameModel(
    gameId: 'emoji_story',
    name: 'Emoji Story',
    description: 'Tell a story using ONLY emojis',
    minPlayers: 2,
    maxPlayers: 4,
    category: GameCategory.creative,
    emoji: '😂',
    instructions: 'Continue the story with 3-5 emojis per turn. Others guess what happens!',
    rules: [
      'Use only emojis',
      'Add 3-5 emojis per turn',
      'Others guess the meaning',
      'Keep it creative!',
    ],
  );

  static final GameModel neverHaveIEver = GameModel(
    gameId: 'never_have_i',
    name: 'Never Have I Ever',
    description: 'Share things you\'ve never done',
    minPlayers: 2,
    maxPlayers: 4,
    category: GameCategory.party,
    emoji: '🙈',
    instructions: 'Say "Never have I ever [done something]". Others who HAVE done it must confess!',
    rules: [
      'Start with "Never have I ever..."',
      'If you HAVE done it, confess',
      'Share funny details',
      'No judging!',
    ],
  );

  // 4 PLAYER GAMES
  static final GameModel teamChaos = GameModel(
    gameId: 'team_chaos',
    name: 'Team Chaos',
    description: 'Split into teams and compete in fun challenges',
    minPlayers: 4,
    maxPlayers: 4,
    category: GameCategory.teamwork,
    emoji: '⚡',
    instructions: 'Split into 2 teams. Complete challenges to earn points!',
    rules: [
      'Teams: 2 vs 2',
      'Challenges: Speed, Creativity, Wit',
      'First team to 5 points wins',
      'No cheating!',
    ],
  );

  static final GameModel wordAssociation = GameModel(
    gameId: 'word_association',
    name: 'Word Association',
    description: 'Say words related to the previous word',
    minPlayers: 2,
    maxPlayers: 4,
    category: GameCategory.party,
    emoji: '💭',
    instructions: 'Start with a word. Each player says a related word. Don\'t repeat or hesitate!',
    rules: [
      'Start with any word',
      'Next word must relate',
      'No repeating words',
      'Hesitate = you lose that round!',
    ],
  );

  static final GameModel twoTruthsLie = GameModel(
    gameId: 'two_truths_lie',
    name: 'Two Truths & A Lie',
    description: 'Guess which statement is fake',
    minPlayers: 2,
    maxPlayers: 4,
    category: GameCategory.party,
    emoji: '🎭',
    instructions: 'Share 2 truths and 1 lie about yourself. Others guess the lie!',
    rules: [
      'Share 3 statements',
      '2 must be TRUE',
      '1 must be FALSE',
      'Make them believable!',
    ],
  );

  static final GameModel rapBattle = GameModel(
    gameId: 'rap_battle',
    name: 'Rap Battle',
    description: 'Create funny rhymes and roast each other',
    minPlayers: 2,
    maxPlayers: 4,
    category: GameCategory.creative,
    emoji: '🎤',
    instructions: 'Take turns creating rhymes! Keep it funny and friendly!',
    rules: [
      'Each player gets 2 lines',
      'Must rhyme',
      'Keep it friendly',
      'Most creative wins!',
    ],
  );

  static final GameModel drawingChain = GameModel(
    gameId: 'drawing_chain',
    name: 'Drawing Chain',
    description: 'Describe with words what the previous person drew',
    minPlayers: 3,
    maxPlayers: 4,
    category: GameCategory.creative,
    emoji: '🎨',
    instructions: 'Player 1 describes something. Player 2 draws it (with words). Continue the chain!',
    rules: [
      'Describe with text only',
      'Next player interprets',
      'Keep the chain going',
      'See how different the end is!',
    ],
  );

  // ALL GAMES LIST
  static final List<GameModel> allGames = [
    truthOrDare,
    wouldYouRather,
    neverHaveIEver,
    storyChain,
    emojiStory,
    twoTruthsLie,
    wordAssociation,
    rapBattle,
    drawingChain,
    teamChaos,
  ];

  // Get games by player count
  static List<GameModel> getGamesByPlayerCount(int playerCount) {
    return allGames
        .where((game) =>
            playerCount >= game.minPlayers && playerCount <= game.maxPlayers)
        .toList();
  }

  // Get game by ID
  static GameModel? getGameById(String gameId) {
    try {
      return allGames.firstWhere((game) => game.gameId == gameId);
    } catch (e) {
      return null;
    }
  }
}

// Game session state
class GameSession {
  final String gameId;
  final String gameName;
  final List<String> players;
  final int currentPlayerIndex;
  final int currentRound;
  final Map<String, int> scores;
  final List<GameTurn> history;
  final DateTime startedAt;

  GameSession({
    required this.gameId,
    required this.gameName,
    required this.players,
    this.currentPlayerIndex = 0,
    this.currentRound = 1,
    Map<String, int>? scores,
    List<GameTurn>? history,
    DateTime? startedAt,
  })  : scores = scores ?? {},
        history = history ?? [],
        startedAt = startedAt ?? DateTime.now();

  String get currentPlayer => players[currentPlayerIndex];

  GameSession copyWith({
    int? currentPlayerIndex,
    int? currentRound,
    Map<String, int>? scores,
    List<GameTurn>? history,
  }) {
    return GameSession(
      gameId: gameId,
      gameName: gameName,
      players: players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentRound: currentRound ?? this.currentRound,
      scores: scores ?? this.scores,
      history: history ?? this.history,
      startedAt: startedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'gameName': gameName,
      'players': players,
      'currentPlayerIndex': currentPlayerIndex,
      'currentRound': currentRound,
      'scores': scores,
      'history': history.map((h) => h.toJson()).toList(),
      'startedAt': startedAt.toIso8601String(),
    };
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      gameId: json['gameId'],
      gameName: json['gameName'],
      players: List<String>.from(json['players']),
      currentPlayerIndex: json['currentPlayerIndex'] ?? 0,
      currentRound: json['currentRound'] ?? 1,
      scores: Map<String, int>.from(json['scores'] ?? {}),
      history: (json['history'] as List?)
              ?.map((h) => GameTurn.fromJson(h))
              .toList() ??
          [],
      startedAt: DateTime.parse(json['startedAt']),
    );
  }
}

// Individual game turn
class GameTurn {
  final String playerId;
  final String playerName;
  final String content;
  final int round;
  final DateTime timestamp;

  GameTurn({
    required this.playerId,
    required this.playerName,
    required this.content,
    required this.round,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'content': content,
      'round': round,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GameTurn.fromJson(Map<String, dynamic> json) {
    return GameTurn(
      playerId: json['playerId'],
      playerName: json['playerName'],
      content: json['content'],
      round: json['round'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}