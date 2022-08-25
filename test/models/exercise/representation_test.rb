require 'test_helper'

class Exercise::RepresentationTest < ActiveSupport::TestCase
  include MarkdownFieldMatchers

  test "has markdown fields for feedback" do
    assert_markdown_field(:exercise_representation, :feedback)
  end

  test "has_feedback?" do
    user = create :user
    refute create(:exercise_representation, feedback_markdown: "foo", feedback_author: nil).has_feedback?
    refute create(:exercise_representation, feedback_markdown: nil, feedback_author: user).has_feedback?
    refute create(:exercise_representation, feedback_markdown: "foo", feedback_author: user).has_feedback?
    assert create(:exercise_representation, feedback_markdown: "foo", feedback_author: user,
      feedback_type: :non_actionable).has_feedback?
  end

  test "has_essential_feedback?" do
    refute create(:exercise_representation, feedback_type: :essential).has_essential_feedback?
    refute create(:exercise_representation, :with_feedback, feedback_type: :actionable).has_essential_feedback?
    assert create(:exercise_representation, :with_feedback, feedback_type: :essential).has_essential_feedback?
  end

  test "has_actionable_feedback?" do
    refute create(:exercise_representation, feedback_type: :actionable).has_actionable_feedback?
    refute create(:exercise_representation, :with_feedback, feedback_type: :essential).has_actionable_feedback?
    assert create(:exercise_representation, :with_feedback, feedback_type: :actionable).has_actionable_feedback?
  end

  test "has_non_actionable_feedback?" do
    refute create(:exercise_representation, feedback_type: :non_actionable).has_non_actionable_feedback?
    refute create(:exercise_representation, :with_feedback, feedback_type: :actionable).has_non_actionable_feedback?
    assert create(:exercise_representation, :with_feedback, feedback_type: :non_actionable).has_non_actionable_feedback?
  end

  test "num_times_used" do
    exercise = create :concept_exercise
    solution = create :concept_solution, exercise: exercise
    submission = create :submission, solution: solution

    ast = SecureRandom.uuid
    ast_digest = Submission::Representation.digest_ast(ast)
    exercise_representation = create(:exercise_representation,
      exercise:,
      ast:,
      ast_digest:)
    assert_equal 0, exercise_representation.num_times_used

    create :submission_representation, submission: submission
    assert_equal 0, exercise_representation.num_times_used

    create :submission_representation, ast_digest: ast_digest, submission: submission
    assert_equal 1, exercise_representation.num_times_used

    create :submission_representation, ast_digest: ast_digest, submission: submission
    assert_equal 2, exercise_representation.num_times_used
  end

  test "submission_representation" do
    exercise = create :concept_exercise
    ast = "My AST"
    ast_digest = Submission::Representation.digest_ast(ast)

    representation = create :exercise_representation,
      exercise: exercise,
      ast_digest: ast_digest

    assert_empty representation.reload.submission_representations

    # Different ast_digest
    create :submission_representation,
      submission: create(:submission, exercise:),
      ast_digest: "something"

    assert_empty representation.reload.submission_representations

    # One matching ast_digest
    submission_representation = create :submission_representation,
      submission: create(:submission, exercise:),
      ast_digest: ast_digest

    assert_equal [submission_representation], representation.reload.submission_representations

    # Multiple matching ast_digests
    submission_representation_2 = create :submission_representation,
      submission: create(:submission, exercise:),
      ast_digest: ast_digest

    assert_equal [submission_representation, submission_representation_2], representation.reload.submission_representations.order(:id)
  end

  test "scope: without_feedback" do
    representation_1 = create :exercise_representation, feedback_type: nil
    representation_2 = create :exercise_representation, feedback_type: nil
    create :exercise_representation, feedback_type: :non_actionable
    create :exercise_representation, feedback_type: :essential
    create :exercise_representation, feedback_type: :actionable

    assert_equal [representation_1, representation_2], Exercise::Representation.without_feedback.order(:id)
  end

  test "scope: with_feedback" do
    representation_1 = create :exercise_representation, feedback_type: :non_actionable
    representation_2 = create :exercise_representation, feedback_type: :essential
    representation_3 = create :exercise_representation, feedback_type: :actionable
    create :exercise_representation, feedback_type: nil
    create :exercise_representation, feedback_type: nil

    assert_equal [representation_1, representation_2, representation_3], Exercise::Representation.with_feedback.order(:id)
  end

  test "scope: edited_by" do
    user_1 = create :user
    user_2 = create :user
    user_3 = create :user

    representation_1 = create :exercise_representation, feedback_author: user_1
    representation_2 = create :exercise_representation, feedback_author: user_2
    representation_3 = create :exercise_representation, feedback_editor: user_1

    assert_equal [representation_1, representation_3], Exercise::Representation.edited_by(user_1).order(:id)
    assert_equal [representation_2], Exercise::Representation.edited_by(user_2)
    assert_empty Exercise::Representation.edited_by(user_3)
  end

  test "scope: mentored_by" do
    track_1 = create :track, :random_slug
    track_2 = create :track, :random_slug
    user_1 = create :user
    user_2 = create :user
    user_3 = create :user
    create :user_track_mentorship, user: user_1, track: track_1
    create :user_track_mentorship, user: user_1, track: track_2
    create :user_track_mentorship, user: user_2, track: track_2
    exercise_1 = create :practice_exercise, track: track_1
    exercise_2 = create :practice_exercise, track: track_2
    exercise_3 = create :practice_exercise, track: track_2
    solution_1 = create :practice_solution, exercise: exercise_1, track: track_1
    solution_2 = create :practice_solution, exercise: exercise_2, track: track_2
    solution_3 = create :practice_solution, exercise: exercise_3, track: track_2
    submission_1 = create :submission, solution: solution_1
    submission_2 = create :submission, solution: solution_2
    submission_3 = create :submission, solution: solution_3
    representation_1 = create :exercise_representation, source_submission: submission_1, exercise: exercise_1
    representation_2 = create :exercise_representation, source_submission: submission_2, exercise: exercise_2
    representation_3 = create :exercise_representation, source_submission: submission_3, exercise: exercise_3
    create :submission_representation, submission: submission_1, ast_digest: representation_1.ast_digest, mentor: user_1
    create :submission_representation, submission: submission_2, ast_digest: representation_2.ast_digest, mentor: user_2
    create :submission_representation, submission: submission_3, ast_digest: representation_3.ast_digest, mentor: user_1

    assert_equal [representation_1, representation_3],
      Exercise::Representation.mentored_by(user_1.reload).order(:id)
    assert_equal [representation_2], Exercise::Representation.mentored_by(user_2.reload)
    assert_empty Exercise::Representation.mentored_by(user_3.reload)
  end

  test "scope: track_mentored_by" do
    track_1 = create :track, :random_slug
    track_2 = create :track, :random_slug

    user_1 = create :user
    user_2 = create :user
    user_3 = create :user

    create :user_track_mentorship, user: user_1, track: track_1
    create :user_track_mentorship, user: user_1, track: track_2
    create :user_track_mentorship, user: user_2, track: track_2

    representation_1 = create :exercise_representation, exercise: create(:practice_exercise, track: track_1)
    representation_2 = create :exercise_representation, exercise: create(:practice_exercise, track: track_2)
    representation_3 = create :exercise_representation, exercise: create(:practice_exercise, track: track_2)

    assert_equal [representation_1, representation_2, representation_3],
      Exercise::Representation.track_mentored_by(user_1.reload).order(:id)
    assert_equal [representation_2, representation_3], Exercise::Representation.track_mentored_by(user_2.reload)
    assert_empty Exercise::Representation.track_mentored_by(user_3.reload)
  end

  test "scope: for_track" do
    track_1 = create :track, :random_slug
    track_2 = create :track, :random_slug
    exercise_1 = create :practice_exercise, track: track_1
    exercise_2 = create :practice_exercise, track: track_1
    exercise_3 = create :practice_exercise, track: track_2

    representation_1 = create :exercise_representation, exercise: exercise_1
    representation_2 = create :exercise_representation, exercise: exercise_2
    representation_3 = create :exercise_representation, exercise: exercise_3

    assert_equal [representation_1, representation_2], Exercise::Representation.for_track(track_1).order(:id)
    assert_equal [representation_3], Exercise::Representation.for_track(track_2)
  end

  test "track" do
    track = create :track
    exercise = create :concept_exercise, track: track

    representation = create :exercise_representation, exercise: exercise

    assert_equal track, representation.track
  end

  test "appears_frequently?" do
    representation = create :exercise_representation, num_submissions: 0

    refute representation.appears_frequently?

    representation.update(num_submissions: 4)
    refute representation.appears_frequently?

    representation.update(num_submissions: 5)
    assert representation.appears_frequently?

    representation.update(num_submissions: 29)
    assert representation.appears_frequently?
  end
end
