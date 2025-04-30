class ScoreService {
  /// Calculates score based on correctness and time.
  /// 
  /// [isCorrect] - whether the answer is correct.
  /// [remainingTime] - how much time was left when the answer was given.
  /// [maxTime] - the total time allowed for the question.
  /// 
  /// Returns a score between 0 and 100.
  static int calculateScore({
    required bool isCorrect,
    required int remainingTime,
    required int maxTime,
  }) {
    if (!isCorrect || maxTime <= 0 || remainingTime <= 0) {
      return 0;
    }

    // Score is proportional to the time remaining.
    double timeRatio = remainingTime / maxTime;
    int score = (timeRatio * 100).round();

    return score.clamp(0, 100); // Ensure score is between 0 and 100
  }

  
}


