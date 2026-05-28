from pydantic import BaseModel
from datetime import datetime


class QuestionOut(BaseModel):
    id: str
    content: str
    options: dict
    order: int
    points: int
    model_config = {"from_attributes": True}


class QuestionWithAnswer(QuestionOut):
    correct_answer: str
    explanation: str | None


class QuizOut(BaseModel):
    id: str
    title: str
    description: str | None
    difficulty: str
    question_count: int
    duration_minutes: int
    is_ai_generated: bool
    plays_count: int
    avg_score: float
    matiere_name: str | None = None
    classe_name: str | None = None
    model_config = {"from_attributes": True}


class GenerateQuizRequest(BaseModel):
    matiere_id: int
    classe_id: int | None = None
    difficulty: str = "moyen"
    question_count: int = 10
    topic: str | None = None  # Sujet spécifique, ex: "Équations du second degré"


class StartSessionResponse(BaseModel):
    session_id: str
    quiz: QuizOut
    questions: list[QuestionWithAnswer]


class SubmitAnswerRequest(BaseModel):
    session_id: str
    question_id: str
    answer: str


class SubmitSessionRequest(BaseModel):
    session_id: str
    answers: dict  # {question_id: answer}
    duration_seconds: int = 0


class SessionResultResponse(BaseModel):
    session_id: str
    score: float
    correct_answers: int
    total_questions: int
    duration_seconds: int
    points_earned: int
    questions_with_answers: list[QuestionWithAnswer]


class UserQuizStats(BaseModel):
    total_sessions: int
    avg_score: float
    best_score: float
    current_streak: int
    rank: int | None
    total_points: int


class GenerateFromProfileRequest(BaseModel):
    matiere_id: int | None = None
    difficulty: str = "moyen"
    question_count: int = 10


class HistoryQuestionOut(BaseModel):
    id: str
    content: str
    options: dict
    correct_answer: str
    explanation: str | None
    order: int
    model_config = {"from_attributes": True}


class HistorySessionOut(BaseModel):
    session_id: str
    quiz_id: str
    quiz_title: str
    score: float
    correct_answers: int
    total_questions: int
    duration_seconds: int
    matiere_name: str | None
    completed_at: datetime
    answers: dict
    questions: list[HistoryQuestionOut]
