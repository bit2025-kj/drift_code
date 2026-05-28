from fastapi import APIRouter, Depends, HTTPException, UploadFile, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from datetime import datetime
from app.database import get_db
from app.models import Quiz, Question, QuizSession, Matiere, User
from app.schemas.quiz import (
    QuizOut, GenerateQuizRequest, StartSessionResponse,
    SubmitSessionRequest, SessionResultResponse, UserQuizStats,
    GenerateFromProfileRequest, HistorySessionOut, HistoryQuestionOut,
)
from app.utils.auth import get_current_user
from app.services.quiz_service import (
    generate_quiz_with_ai, generate_quiz_from_content,
    generate_quiz_from_image, extract_text_from_pdf,
    render_pdf_page_as_image, _get_fallback_questions,
)
import uuid

router = APIRouter(prefix="/quiz", tags=["Quiz IA"])


@router.get("", response_model=list[QuizOut])
async def list_quizzes(db: AsyncSession = Depends(get_db), matiere_id: int | None = None):
    stmt = select(Quiz).options(selectinload(Quiz.matiere), selectinload(Quiz.classe)).where(Quiz.is_public == True)
    if matiere_id:
        stmt = stmt.where(Quiz.matiere_id == matiere_id)
    stmt = stmt.order_by(Quiz.plays_count.desc()).limit(20)
    result = await db.execute(stmt)
    quizzes = result.scalars().all()
    return [_enrich_quiz(q) for q in quizzes]


def _enrich_quiz(q: Quiz) -> QuizOut:
    out = QuizOut.model_validate(q)
    out.matiere_name = q.matiere.name if q.matiere else None
    out.classe_name = q.classe.name if q.classe else None
    return out


@router.post("/generate", response_model=StartSessionResponse)
async def generate_quiz(
    data: GenerateQuizRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    matiere_result = await db.execute(select(Matiere).where(Matiere.id == data.matiere_id))
    matiere = matiere_result.scalar_one_or_none()
    if not matiere:
        raise HTTPException(status_code=404, detail="Matière introuvable")

    questions_data = await generate_quiz_with_ai(
        matiere_name=matiere.name,
        difficulty=data.difficulty,
        question_count=data.question_count,
        topic=data.topic,
    )

    quiz = Quiz(
        id=str(uuid.uuid4()),
        title=f"Quiz {matiere.name} — {data.difficulty.capitalize()}",
        matiere_id=data.matiere_id,
        classe_id=data.classe_id,
        difficulty=data.difficulty,
        question_count=len(questions_data),
        is_ai_generated=True,
        created_by=current_user.id,
    )
    db.add(quiz)
    await db.flush()

    question_objects = []
    for i, qdata in enumerate(questions_data):
        q = Question(
            id=str(uuid.uuid4()),
            quiz_id=quiz.id,
            content=qdata["content"],
            options=qdata["options"],
            correct_answer=qdata["correct_answer"],
            explanation=qdata.get("explanation"),
            order=i,
        )
        db.add(q)
        question_objects.append(q)

    session = QuizSession(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        quiz_id=quiz.id,
        total_questions=len(question_objects),
    )
    db.add(session)
    await db.commit()

    from app.schemas.quiz import QuestionWithAnswer
    return StartSessionResponse(
        session_id=session.id,
        quiz=_enrich_quiz(quiz),
        questions=[QuestionWithAnswer.model_validate(q) for q in question_objects],
    )


@router.post("/sessions/{session_id}/submit", response_model=SessionResultResponse)
async def submit_quiz(
    session_id: str,
    data: SubmitSessionRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(QuizSession)
        .options(selectinload(QuizSession.quiz).selectinload(Quiz.questions))
        .where(QuizSession.id == session_id, QuizSession.user_id == current_user.id)
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session introuvable")
    if session.is_completed:
        raise HTTPException(status_code=400, detail="Session déjà terminée")

    questions = session.quiz.questions
    correct = sum(1 for q in questions if data.answers.get(q.id) == q.correct_answer)
    score = round((correct / len(questions)) * 100, 1) if questions else 0

    session.is_completed = True
    session.answers = data.answers
    session.correct_answers = correct
    session.score = score
    session.completed_at = datetime.utcnow()
    session.duration_seconds = data.duration_seconds
    session.quiz.plays_count += 1

    points_earned = correct * 10
    current_user.points += points_earned

    await db.commit()

    from app.schemas.quiz import QuestionWithAnswer
    return SessionResultResponse(
        session_id=session_id,
        score=score,
        correct_answers=correct,
        total_questions=len(questions),
        duration_seconds=session.duration_seconds,
        points_earned=points_earned,
        questions_with_answers=[QuestionWithAnswer.model_validate(q) for q in questions],
    )


@router.get("/my-sessions", response_model=list[dict])
async def my_sessions(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    result = await db.execute(
        select(QuizSession)
        .options(selectinload(QuizSession.quiz).selectinload(Quiz.matiere))
        .where(QuizSession.user_id == current_user.id)
        .order_by(QuizSession.started_at.desc())
        .limit(10)
    )
    sessions = result.scalars().all()
    return [
        {
            "session_id": s.id, "quiz_id": s.quiz_id, "quiz_title": s.quiz.title,
            "score": s.score, "is_completed": s.is_completed,
            "started_at": s.started_at, "matiere": s.quiz.matiere.name if s.quiz.matiere else None,
        }
        for s in sessions
    ]


@router.get("/stats", response_model=UserQuizStats)
async def my_quiz_stats(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    result = await db.execute(
        select(func.count(), func.avg(QuizSession.score), func.max(QuizSession.score))
        .where(QuizSession.user_id == current_user.id, QuizSession.is_completed == True)
    )
    count, avg_score, best_score = result.one()
    return UserQuizStats(
        total_sessions=count or 0,
        avg_score=round(avg_score or 0, 1),
        best_score=round(best_score or 0, 1),
        current_streak=current_user.current_streak,
        rank=current_user.rank,
        total_points=current_user.points,
    )


@router.post("/generate-from-file", response_model=StartSessionResponse)
async def generate_quiz_from_file(
    file: UploadFile,
    matiere_id: int = Form(...),
    difficulty: str = Form("moyen"),
    question_count: int = Form(10),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    matiere_result = await db.execute(select(Matiere).where(Matiere.id == matiere_id))
    matiere = matiere_result.scalar_one_or_none()
    if not matiere:
        raise HTTPException(status_code=404, detail="Matière introuvable")

    file_bytes = await file.read()
    content_type = (file.content_type or "").lower()
    q_count = max(5, min(question_count, 30))

    # Fetch user's level/class to contextualise questions
    user_result = await db.execute(
        select(User).options(selectinload(User.level), selectinload(User.classe))
        .where(User.id == current_user.id)
    )
    full_user = user_result.scalar_one()
    topic = (
        f"programme de {full_user.classe.name} ({full_user.level.name})"
        if full_user.classe and full_user.level
        else (f"niveau {full_user.level.name}" if full_user.level else None)
    )

    if "pdf" in content_type:
        text = extract_text_from_pdf(file_bytes)
        if len(text.strip()) > 100:
            questions_data = await generate_quiz_from_content(
                content=text, matiere_name=matiere.name,
                difficulty=difficulty, question_count=q_count, topic=topic,
            )
        else:
            img_bytes = render_pdf_page_as_image(file_bytes)
            if img_bytes:
                questions_data = await generate_quiz_from_image(
                    image_bytes=img_bytes, media_type="image/jpeg",
                    matiere_name=matiere.name, difficulty=difficulty,
                    question_count=q_count, topic=topic,
                )
            else:
                questions_data = _get_fallback_questions(matiere.name, q_count)
    elif content_type.startswith("image/"):
        questions_data = await generate_quiz_from_image(
            image_bytes=file_bytes, media_type=content_type,
            matiere_name=matiere.name, difficulty=difficulty,
            question_count=q_count, topic=topic,
        )
    else:
        raise HTTPException(status_code=400, detail="Format non supporté. Utilisez un PDF ou une image.")

    quiz = Quiz(
        id=str(uuid.uuid4()),
        title=f"Quiz {matiere.name} — {file.filename or 'cours'} ({difficulty.capitalize()})",
        matiere_id=matiere_id, difficulty=difficulty,
        question_count=len(questions_data), is_ai_generated=True, created_by=current_user.id,
    )
    db.add(quiz)
    await db.flush()

    question_objects = [
        Question(
            id=str(uuid.uuid4()), quiz_id=quiz.id, content=qd["content"],
            options=qd["options"], correct_answer=qd["correct_answer"],
            explanation=qd.get("explanation"), order=i,
        )
        for i, qd in enumerate(questions_data)
    ]
    for q in question_objects:
        db.add(q)

    session = QuizSession(
        id=str(uuid.uuid4()), user_id=current_user.id,
        quiz_id=quiz.id, total_questions=len(question_objects),
    )
    db.add(session)
    await db.commit()

    from app.schemas.quiz import QuestionWithAnswer
    return StartSessionResponse(
        session_id=session.id, quiz=_enrich_quiz(quiz),
        questions=[QuestionWithAnswer.model_validate(q) for q in question_objects],
    )


@router.post("/generate-from-profile", response_model=StartSessionResponse)
async def generate_quiz_from_profile(
    data: GenerateFromProfileRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user_result = await db.execute(
        select(User).options(selectinload(User.level), selectinload(User.classe))
        .where(User.id == current_user.id)
    )
    user = user_result.scalar_one()

    matiere = None
    if data.matiere_id:
        result = await db.execute(select(Matiere).where(Matiere.id == data.matiere_id))
        matiere = result.scalar_one_or_none()
    elif user.classe_id:
        from app.models.education import matiere_classe
        stmt = (
            select(Matiere)
            .join(matiere_classe, Matiere.id == matiere_classe.c.matiere_id)
            .where(matiere_classe.c.classe_id == user.classe_id)
            .limit(1)
        )
        result = await db.execute(stmt)
        matiere = result.scalar_one_or_none()

    if not matiere:
        raise HTTPException(status_code=400, detail="Profil incomplet. Définissez votre classe dans les paramètres.")

    classe_ctx = user.classe.name if user.classe else ""
    level_ctx = user.level.name if user.level else ""
    topic = f"programme de {classe_ctx} ({level_ctx})" if classe_ctx else None

    questions_data = await generate_quiz_with_ai(
        matiere_name=matiere.name, difficulty=data.difficulty,
        question_count=data.question_count, topic=topic,
    )

    quiz = Quiz(
        id=str(uuid.uuid4()),
        title=f"Quiz Parcours — {matiere.name}{' ' + classe_ctx if classe_ctx else ''}",
        matiere_id=matiere.id, classe_id=user.classe_id,
        difficulty=data.difficulty, question_count=len(questions_data),
        is_ai_generated=True, created_by=current_user.id,
    )
    db.add(quiz)
    await db.flush()

    question_objects = [
        Question(
            id=str(uuid.uuid4()), quiz_id=quiz.id, content=qd["content"],
            options=qd["options"], correct_answer=qd["correct_answer"],
            explanation=qd.get("explanation"), order=i,
        )
        for i, qd in enumerate(questions_data)
    ]
    for q in question_objects:
        db.add(q)

    session = QuizSession(
        id=str(uuid.uuid4()), user_id=current_user.id,
        quiz_id=quiz.id, total_questions=len(question_objects),
    )
    db.add(session)
    await db.commit()

    from app.schemas.quiz import QuestionWithAnswer
    return StartSessionResponse(
        session_id=session.id, quiz=_enrich_quiz(quiz),
        questions=[QuestionWithAnswer.model_validate(q) for q in question_objects],
    )


@router.get("/history", response_model=list[HistorySessionOut])
async def quiz_history(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: int = 50,
):
    result = await db.execute(
        select(QuizSession)
        .options(
            selectinload(QuizSession.quiz).selectinload(Quiz.matiere),
            selectinload(QuizSession.quiz).selectinload(Quiz.questions),
        )
        .where(QuizSession.user_id == current_user.id, QuizSession.is_completed == True)
        .order_by(QuizSession.completed_at.desc())
        .limit(limit)
    )
    sessions = result.scalars().all()
    out = []
    for s in sessions:
        qs = sorted(s.quiz.questions, key=lambda x: x.order) if s.quiz else []
        out.append(HistorySessionOut(
            session_id=s.id, quiz_id=s.quiz_id,
            quiz_title=s.quiz.title if s.quiz else "",
            score=s.score or 0, correct_answers=s.correct_answers or 0,
            total_questions=s.total_questions, duration_seconds=s.duration_seconds or 0,
            matiere_name=s.quiz.matiere.name if s.quiz and s.quiz.matiere else None,
            completed_at=s.completed_at or datetime.utcnow(),
            answers=s.answers or {},
            questions=[
                HistoryQuestionOut(
                    id=q.id, content=q.content, options=q.options,
                    correct_answer=q.correct_answer, explanation=q.explanation, order=q.order,
                )
                for q in qs
            ],
        ))
    return out


@router.get("/{quiz_id}", response_model=StartSessionResponse)
async def get_quiz(
    quiz_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Quiz)
        .options(
            selectinload(Quiz.matiere),
            selectinload(Quiz.classe),
            selectinload(Quiz.questions),
        )
        .where(Quiz.id == quiz_id, Quiz.is_public == True)
    )
    quiz = result.scalar_one_or_none()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz introuvable")

    session = QuizSession(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        quiz_id=quiz.id,
        total_questions=len(quiz.questions),
    )
    db.add(session)
    await db.commit()

    from app.schemas.quiz import QuestionWithAnswer
    return StartSessionResponse(
        session_id=session.id,
        quiz=_enrich_quiz(quiz),
        questions=[QuestionWithAnswer.model_validate(q) for q in sorted(quiz.questions, key=lambda x: x.order)],
    )


@router.get("/sessions/{session_id}/result", response_model=SessionResultResponse)
async def get_session_result(
    session_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(QuizSession)
        .options(selectinload(QuizSession.quiz).selectinload(Quiz.questions))
        .where(QuizSession.id == session_id, QuizSession.user_id == current_user.id)
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session introuvable")
    if not session.is_completed:
        raise HTTPException(status_code=400, detail="Session non terminée")

    from app.schemas.quiz import QuestionWithAnswer
    return SessionResultResponse(
        session_id=session.id,
        score=session.score,
        correct_answers=session.correct_answers,
        total_questions=session.total_questions,
        duration_seconds=session.duration_seconds,
        points_earned=session.correct_answers * 10,
        questions_with_answers=[QuestionWithAnswer.model_validate(q) for q in session.quiz.questions],
    )
